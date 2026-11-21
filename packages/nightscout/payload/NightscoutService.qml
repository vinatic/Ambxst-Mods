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

    property string cgmUnit: "mmol/L"
    property bool hideUnit: false
    property bool warnOldCgmValue: true
    property int oldValueTimer: 20

    property var nightscoutData: null
    property string entriesCount: "5"

    property int updateInterval: 60000 // 1 minute

    function handleNightscoutSuccess() {
        connectionError = false
        cgmTextMaker()
    }

    function handleNightscoutFailure() {
        console.log("Nightscout Connection:", connectionError)
        connectionError = true
        cgmTextMaker()
    }

    function getNightscoutApiUrl() {
      if (!root.nightscoutURL) {
        return null
      }
      var keyString = ""
      if (root.apikey != "") {
        keyString = '&token='+root.apikey
      }
      return root.nightscoutURL + 'api/v1/entries.json?find%5Bdate%5D%5B\$gt%5D=1763753031984&count='+entriesCount+''+keyString
    }

    function forceRestart() {
        nightscoutFetcher.running = false
        fetchNightscout()
    }

    function fetchNightscout() {
        if (nightscoutFetcher.running) {
            return
        }

        const apiUrl = getNightscoutApiUrl()
        if (!apiUrl) {
            return
        }

        nightscoutFetcher.command = ['curl', apiUrl]
        nightscoutFetcher.running = true
    }

    function formatCgm(cgm, unit) {
        if (unit === "mmol/L") {
          return (Math.round((cgm / 18.018) * 10) / 10).toFixed(1)
        } else if (unit === "mmol/mol") {
          return Math.round(0.3808 * cgm - 5.716)
        } else if (unit === "HbA1c") {
          return ((cgm + 46.7) / 28.7).toFixed(1)
        }
    }

    function dirSymbol(dir) {
      if (dir == "Flat") {
        return " → "
      } else if (dir == "SingleUp") {
        return " ↑ "
      } else if (dir == "SingleDown") {
        return " ↓ "
      } else if (dir == "FortyFiveUp") {
        return " ↗ "
      } else if (dir == "FortyFiveDown") {
        return " ↘ "
      } else if (dir == "DoubleUp") {
        return " ↑↑"
      } else if (dir == "DoubleDown") {
        return " ↓↓"
      } else if (dir == "NONE") {
        return " ⇼ "
      } else if (dir == "NOT COMPUTABLE") {
        return " - "
      } else if (dir == "RATE OUT OF RANGE") {
        return " ⇕ "
      } else {
        return " ? "
      }
    }

    function cgmTextMaker() {
      if (connectionError) {
        widgetText = I18n.t("Connection Error")
      } else if (nightscoutData === null || nightscoutData.length === 0) {
        widgetText = I18n.t("No data Error")
      } else if (nightscoutData[0].date + oldValueTimer * 60 * 1000 - Date.now() < 0 && warnOldCgmValue) { //older than 20 min
        widgetText = I18n.t("Old value")
      } else {
        widgetText = nightscoutData[0][cgmUnit] + (hideUnit && cgmUnit !== "%" ? "" : cgmUnit) + dirSymbol(nightscoutData[0].direction)
      }
    }

    Process {
        id: nightscoutFetcher
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const raw = text.trim()
                if (!raw || raw[0] !== "[") {
                    console.log("Nightscout Error: Failed to fetch")
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
                                "mg/dL": data[i].sgv,
                                "mmol/L": formatCgm(data[i].sgv, "mmol/L"),
                                "mmol/mol": formatCgm(data[i].sgv, "mmol/mol"),
                                "%": formatCgm(data[i].sgv, "HbA1c"),
                                "date": data[i].date,
                                "dateString": data[i].dateString,
                                "direction": data[i].direction
                            })
                        }
                    }

                    root.nightscoutData = cgm_list
                    root.handleNightscoutSuccess()
                } catch (e) {
                    console.log("Nightscout Error:",e)
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
        running: false
        repeat: true
        onTriggered: {
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
        } else if (key === "unit") {
            cgmUnit = value
            cgmTextMaker()
        } else if (key === "hideUnit") {
            hideUnit = value
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
        cgmUnit = values["unit"]
        hideUnit = values["hideUnit"]
        warnOldCgmValue = values["warnOldCgmValue"]
        oldValueTimer = values["oldValueTimer"]
        fetchNightscout()
        updateTimer.start()
        console.log("Nightscout:", "Nightscout Service initiated")
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
