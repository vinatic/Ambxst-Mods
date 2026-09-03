pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.modules.services

Singleton {
    id: root
    property string bridgeIP: ""
    property string api: ""
    property int lightID: -1

    property bool toggleRunning: false

    property var lights: null

    property bool on: true
    property int bri: 0
    property int hue: 0
    property int sat: 0
    property string effect: ""
    property var xy: [0.0, 0.0]

    Process {
      id: getLights
      running: false
      command: ["sh", "-c", "curl "+bridgeIP+"/api/"+api+"/lights"]
      stdout: StdioCollector {
        onStreamFinished: {
          const data = JSON.parse(text.trim())
          let ids = Object.keys(data)
          var light_list = []
          for (let i = 0; i < ids.length; i++) {
              light_list.push({
                        "id": ids[i],
                        "name": data[ids[i]].name,
                        "on": data[ids[i]].state.on,
                        "bri": data[ids[i]].state.bri,
                        "hue": data[ids[i]].state.hue,
                        "sat": data[ids[i]].state.sat,
                        "effect": data[ids[i]].state.effect,
                        "xy": data[ids[i]].state.xy
                      })
                    }
              root.lights = light_list
              root.lightID = (light_list.length > 0) ? light_list[0].id : -1
              getLightDataHelper()
        }
      }
    }

    Process {
      id: getLightData
      running: false
      command: ["sh", "-c", "curl "+bridgeIP+"/api/"+api+"/lights/"+lightID]
      stdout: StdioCollector {
        onStreamFinished: {
          const data = JSON.parse(text.trim())
          // console.log("Hue Service: started collecting. Now the Power is: "+root.lightData.on+", Now the Brightness is: "+root.lightData.bri)
          root.on = data.state.on
          root.bri = data.state.bri
          root.hue = data.state.hue
          root.sat = data.state.sat
          root.effect = data.state.effect
          root.xy = data.state.xy

          console.log("Hue Service: finished collecting. Power is: "+data.state.on+", Brightness is: "+data.state.bri)
          if (toggleRunning) {
            console.log("Hue Service: on is being set to: "+!data.state.on)
            toggleRunning = false
            setPower(!data.state.on)
          }
        }
      }
    }

    function getLightDataHelper() {
      getLightData.running = true
    }

    function getLightsHelper() {
      getLights.running = true
    }

    function widgetHelper() {
      if (lightID === -1) {
          getLightsHelper()
      } else {
          getLightDataHelper()
      }
    }

    Process {
      id: setHueCommand
      running: false
      // stdout: StdioCollector {
      //   onStreamFinished: console.log(setHueCommand.command)
      // }
    }

    function hueRunCommandHelper(param) {
      let request = "curl "+"-X "+"PUT "+"-d "+param+" "+bridgeIP+"/api/"+api+"/lights/"+lightID+"/state";
      setHueCommand.command = ["bash", "-c", request]
      console.log(setHueCommand.command)
      setHueCommand.running = true
    }

    function setBrightness(value) {
      let param = "'{"+'"bri": '+value+"}'";
      hueRunCommandHelper(param);
      root.bri = value
    }

    function togglePower() {
      toggleRunning = true
      getLightDataHelper();
    }

    function setPower(value) {
      let param = "'{"+'"on": '+value+"}'";
      root.on = value
      hueRunCommandHelper(param);
    }

    function applySetting(key, value) {
        if (key === "bridgeIP") {
            bridgeIP = value.trim()
        } else if (key === "api") {
            api = value.trim()
        }
        getLightsHelper()
    }

    function applySettings(values) {
        bridgeIP = values["bridgeIP"].trim()
        api = values["api"].trim()
        getLightsHelper()
    }

    Connections {
        target: ModsService
        function onSettingChanged(modId, key, value) {
            if (modId === "vinatic.hue-bridge-controller")
                applySetting(key, value);
        }
    }

    Component.onCompleted: ModsService.getSettings("vinatic.hue-bridge-controller", (settings, error) => {
          if (!error) {
              applySettings(settings.values);
          }
    })
}

