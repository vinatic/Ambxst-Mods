pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.modules.services
import qs.modules.theme
import qs.modules.globals

Singleton {
    id: root
    property string bridgeIP: ""
    property string api: ""

    property bool toggleRunning: false
    property int toggleLightID: 0

    property bool autoColor: false
    property var lights: null
    property var groups: null

    property color hueColor: Colors.sourceColor // change to Colors.primary if sourceColor is too intense

    onHueColorChanged: {
        if (autoColor) {
            applyColorHelper();
        }
    }

    Process {
      id: getLights
      running: false
      command: ["sh", "-c", "curl "+bridgeIP+"/api/"+api+"/lights"]
      stdout: StdioCollector {
        onStreamFinished: {
          const data = JSON.parse(text)
          var ids = Object.keys(data)
          var light_list = {}
          for (let i = 0; i < ids.length; i++) {
              light_list[ids[i]] = {
                        "id": ids[i],
                        "name": data[ids[i]].name,
                        "on": data[ids[i]].state.on,
                        "bri": data[ids[i]].state.bri,
                        "hue": data[ids[i]].state.hue,
                        "sat": data[ids[i]].state.sat,
                        "effect": data[ids[i]].state.effect,
                        "xy": data[ids[i]].state.xy,
                        "colorgamut": data[ids[i]].capabilities.control.colorgamut
                      }
          }
          root.lights = light_list
        }
      }
    }

    Process {
      id: getLightData
      running: false
      stdout: StdioCollector {
        onStreamFinished: {
          const data = JSON.parse(text.trim())
          // console.log("Hue Service: started collecting. Now the Power is: "+root.lightData.on+", Now the Brightness is: "+root.lightData.bri)
          console.log("Hue Service: finished collecting. Power is: "+data.state.on+", Brightness is: "+data.state.bri)
          if (toggleRunning) {
            console.log("Hue Service: on is being set to: "+!data.state.on)
            setPower(toggleLightID, !data.state.on)
            toggleRunning = false
            toggleLightID = 0
          }
        }
      }
    }

    Process {
      id: getGroups
      running: false
      command: ["sh", "-c", "curl "+bridgeIP+"/api/"+api+"/groups"]
      stdout: StdioCollector {
        onStreamFinished: {
          const data = JSON.parse(text)
          let ids = Object.keys(data)
          let groups_list = []
          for (let i = 0; i < ids.length; i++) {
            groups_list.push({
                        "id": ids[i],
                        "name": data[ids[i]].name,
                        "on": data[ids[i]].action.on,
                        "all_on": data[ids[i]].state.all_on,
                        "any_on": data[ids[i]].state.any_on,
                        "bri": data[ids[i]].action.bri,
                        "hue": data[ids[i]].action.hue,
                        "sat": data[ids[i]].action.sat,
                        "effect": data[ids[i]].action.effect,
                        "xy": data[ids[i]].action.xy
                      })
                    }
          root.groups = groups_list
        }
      }
    }

    function getLightDataHelper(id) {
      getLightData.command = ["sh", "-c", "curl "+bridgeIP+"/api/"+api+"/lights/"+id]
      getLightData.running = true
    }

    function getLightsHelper() {
      getLights.running = true
    }

    function getGroupsHelper() {
      getGroups.running = true
    }

    Process {
      id: setHueCommand
      running: false
      // stdout: StdioCollector {
      //   onStreamFinished: console.log(setHueCommand.command)
      // }
    }

    function hueRunCommandHelper(id, param) {
      let request = "curl "+"-X "+"PUT "+"-d "+param+" "+bridgeIP+"/api/"+api+"/lights/"+id+"/state";
      setHueCommand.command = ["bash", "-c", request]
      //console.log(setHueCommand.command)
      setHueCommand.running = true
    }

    function setBrightness(id, value) {
      let param = "'{"+'"bri": '+value+"}'";
      hueRunCommandHelper(id, param);
    }

    function togglePower(id) {
      toggleLightID = id
      toggleRunning = true
      getLightDataHelper(id);
    }

    function setPower(id, value) {
      let param = "'{"+'"on": '+value+"}'";
      hueRunCommandHelper(id, param);
      root.lights[id] = Object.assign({}, root.lights[id], { "on": value })
      root.lights = Object.assign({}, root.lights) // Forces the update to widget
    }

    function applyColorHelper() {
        var rgb = [hueColor.r, hueColor.g, hueColor.b]
        let r = (rgb[0] > 0.04045) ? ((rgb[0] + 0.055) / (1.0 + 0.055))**2.4 : (rgb[0] / 12.92)
        let g = (rgb[1] > 0.04045) ? ((rgb[1] + 0.055) / (1.0 + 0.055))**2.4 : (rgb[1] / 12.92)
        let b = (rgb[2] > 0.04045) ? ((rgb[2] + 0.055) / (1.0 + 0.055))**2.4 : (rgb[2] / 12.92)

        const X = r * 0.664511 + g * 0.154324 + b * 0.162028
        const Y = r * 0.283881 + g * 0.668433 + b * 0.047685
        const Z = r * 0.000088 + g * 0.072310 + b * 0.986039

        let cx = (X / (X + Y + Z)).toFixed(4)
        let cy = (Y / (X + Y + Z)).toFixed(4)
        var param = "'"+'{"xy":['+cx+','+cy+"]}'"

        for (let i = 0; i < groups.length; i++) {
            let request = "curl "+"-X "+"PUT "+"-d "+param+" "+bridgeIP+"/api/"+api+"/groups/"+groups[i].id+"/action";
            setHueCommand.command = ["bash", "-c", request]
            setHueCommand.running = true
        }
    }

    function applySetting(key, value) {
        if (key === "bridgeIP") {
            bridgeIP = value.trim()
        } else if (key === "api") {
            api = value.trim()
        }
        if (key === "autoColor") {
            autoColor = value
            applyColorHelper()
        } else {
            getLightsHelper()
            getGroupsHelper()
        }
    }

    function applySettings(values) {
        bridgeIP = values["bridgeIP"].trim()
        api = values["api"].trim()
        autoColor = values["autoColor"]
        getLightsHelper()
        getGroupsHelper()
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

