pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.modules.services

Singleton {
    id: root
    property string nightscoutURL: ""
    property string apikey: ""

    property string widgetText: ""
    property bool connectionError: false

    property int utcOffset: 1 * 60 * 60 * 1000 // +1 hour UTC
    property string mmol: "mmol/L"
    property bool warnOldCgmValue: true
    property int oldValueTimer: 20
    property var newestCgm: ({
                               "available": false,
                               "loading": true,
                               "sgv_mg": 0,
                               "sgv_mmol": 0,
                               "date": 0,
                               "dateString": "",
                               "direction": "Flat"
                           })
    property var nightscoutData: null
    property string entriesCount: "100"

    property int refCount: 0

    property int updateInterval: 60000 // 1 minute
    property int retryAttempts: 0
    property int maxRetryAttempts: 3
    property int retryDelay: 3000
    property int lastFetchTime: 0
    property int minFetchInterval: 3000
    property int persistentRetryCount: 0

    function handleNightscoutSuccess() {
        connectionError = false
        cgmTextMaker()
        root.retryAttempts = 0
        root.persistentRetryCount = 0
        if (persistentRetryTimer.running) {
            persistentRetryTimer.stop()
        }
        if (updateTimer.interval !== root.updateInterval) {
            updateTimer.interval = root.updateInterval
        }
    }

    function handleNightscoutFailure() {
        root.retryAttempts++
        if (root.retryAttempts < root.maxRetryAttempts) {
            retryTimer.start()
          } else {
            if (!root.newestCgm.available) {
                root.newestCgm.loading = false
            }
            console.info("Nightscout Connection:", connectionError)
            connectionError = true
            cgmTextMaker()
            const backoffDelay = Math.min(60000 * Math.pow(2, persistentRetryCount), 300000)
            persistentRetryCount++
            persistentRetryTimer.interval = backoffDelay
            persistentRetryTimer.start()
        }
    }

    function getNightscoutApiUrl() {
      // TODO: add password
      if (!root.nightscoutURL) {
        return null
      }
      var keyString = ""
      if (root.apikey != "") {
        keyString = '&token='+root.apikey
      }
      return root.nightscoutURL + 'api/v1/entries.json?find%5Bdate%5D%5B\$gt%5D=1763753031984&count=5'+keyString
    }

    function forceRestart() {
        nightscoutFetcher.running = false
        lastFetchTime = 0
        fetchNightscout()
    }

    function fetchNightscout() {
        if (nightscoutFetcher.running) {
            return
        }

        const now = Date.now()
        if (now - root.lastFetchTime < root.minFetchInterval) {
            return
        }

        const apiUrl = getNightscoutApiUrl()
        if (!apiUrl) {
            return
        }

        root.lastFetchTime = now
        root.newestCgm.loading = true
        nightscoutFetcher.command = ['curl', apiUrl]
        nightscoutFetcher.running = true
    }

    function formatSgv(sgv) {
        return (Math.round((sgv / 18.0) * 10) / 10).toFixed(1)
    }

    function dirSymbol(dir) {
      if (dir == "Flat") {
        return "→ "
      } else if (dir == "SingleUp") {
        return "↑ "
      } else if (dir == "SingleDown") {
        return "↓ "
      } else if (dir == "FortyFiveUp") {
        return "↗ "
      } else if (dir == "FortyFiveDown") {
        return "↘ "
      } else if (dir == "DoubleUp") {
        return "↑↑"
      } else if (dir == "DoubleDown") {
        return "↓↓"
      } else if (dir == "NONE") {
        return "⇼ "
      } else if (dir == "NOT COMPUTABLE") {
        return "- "
      } else if (dir == "RATE OUT OF RANGE") {
        return "⇕ "
      } else {
        return "? "
      }
    }

    function cgmTextMaker() {
      //console.info("NightscoutService: ")
      if (!mmol) {
        widgetText = "Service Error"
      } else if (connectionError) {
        widgetText = "Connection Error"
      } else if (((Date.now()) - (newestCgm.date + oldValueTimer * 1000)) < 0 && warnOldCgmValue) { //older than 20 min
        widgetText = "Old value"
      } else if (mmol == "mmol/L") {
        widgetText = newestCgm.sgv_mmol + "mmol/L " + dirSymbol(NightscoutService.newestCgm.direction)
      } else if (mmol == "mg/dL") {
        widgetText = newestCgm.sgv_mg + "mg/dL " + dirSymbol(NightscoutService.newestCgm.direction)
      } else {
        widgetText = "new error"
      }
    }

    Process {
        id: nightscoutFetcher
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const raw = text.trim()
                if (!raw || raw[0] !== "[") {
                    console.info("Nightscout Error: Failed to fetch")
                    root.handleNightscoutFailure()
                    return
                }
                try {
                    const data = JSON.parse(raw)
                    if (!data[0]) {
                        throw new Error("Required nightscout data fields missing")
                    }
                    const cgm_list = []
                    if (data.length > 0) {
                      for (let i = 0; i < data.length; i++) {
                            // if ((data[i].date - (Date.now() - (root.showHours * 60 * 60 * 1000))) > 0) {
                            //   root.maxMg = Math.max(root.maxMg, data[i].sgv)
                            // }
                            cgm_list.push({
                                "sgv_mg": data[i].sgv,
                                "sgv_mmol": formatSgv(data[i].sgv),
                                "date": data[i].date,
                                "dateString": data[i].dateString,
                                "direction": data[i].direction
                            })
                        }
                    }

                    root.newestCgm = {
                        "available": true,
                        "loading": false,
                        "sgv_mg": data[0].sgv,
                        "sgv_mmol": formatSgv(data[0].sgv),
                        "date": data[0].date,
                        "dateString": data[0].dateString,
                        "direction": data[0].direction
                    }

                    root.nightscoutData = cgm_list
                    root.cgmTextMaker()
                    root.handleNightscoutSuccess()
                } catch (e) {
                    console.info("Nightscout Error:",e)
                    root.handleNightscoutFailure(e)
                }
            }
        }

        onExited: exitCode => {
            if (exitCode !== 0) {
                root.handleNightscoutFailure()
            }
        }
    }

    Timer {
        id: updateTimer
        interval: root.updateInterval
        running: root.refCount > 0
        repeat: true
        onTriggered: {
            root.fetchNightscout()
        }
    }

    Timer {
        id: retryTimer
        interval: root.retryDelay
        running: false
        repeat: false
        onTriggered: {
            root.fetchNightscout()
        }
    }

    Timer {
        id: persistentRetryTimer
        interval: 60000
        running: false
        repeat: false
        onTriggered: {
            if (!root.newestCgm.available) {
                root.newestCgm.loading = true
            }
            root.fetchNightscout()
        }
    }

    function applySetting(key, value) {
        if (key === "nightscoutURL") {
            nightscoutURL = value.trim()
        } else if (key === "apikey") {
            apikey = value.trim()
        }
        if (key === "warnOldCgmValue") {
            warnOldCgmValue = value
            cgmTextMaker()
        } else if (key === "mmol") {
            if (value) {
                mmol = "mmol/L"
            } else {
                mmol = "mg/dL"
            }
            cgmTextMaker()
        } else if (key === "oldValueTimer") {
            oldValueTimer = value
            cgmTextMaker()
        } else {
            forceRestart()
        }
    }

    function applySettings(values) {
        nightscoutURL = values["nightscoutURL"].trim()
        apikey = values["apikey"].trim()
        if (values["mmol"]) {
            mmol = "mmol/L"
        } else {
            mmol = "mg/dL"
        }
        warnOldCgmValue = values["warnOldCgmValue"]
        oldValueTimer = values["oldValueTimer"]
        fetchNightscout()
        updateTimer.start()
        console.info("Nightscout:", "Nightscout Service initiated")
    }

    Connections {
        target: ModsService
        function onSettingChanged(modId, key, value) {
            if (modId === "vinatic.nightscout")
                applySetting(key, value);
        }
    }

    Component.onCompleted: ModsService.getSettings("vinatic.nightscout", (settings, error) => {
          if (!error) {
              applySettings(settings.values);
          }
    })
}
