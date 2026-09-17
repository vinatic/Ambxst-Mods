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
    property bool toggleGroupRunning: false
    property int toggleGroupID: 0

    property bool autoColor: false
    property var lights: null
    property var groups: null

    property bool updateOnRelease: false

    property color autoHueColor: Colors.sourceColor // change to Colors.primary if sourceColor is too intense
    property color hueColor: getColor() //Does not get color from hue bridge yet

    onAutoHueColorChanged: {
      if (autoColor) {
        root.hueColor = autoHueColor
      }
    }

    onHueColorChanged: {
        applyColorHelper();
    }

    property bool _initialized: false

    function initialize() {
        if (_initialized) return;
        _initialized = true;
        getLightsHelper()
        getGroupsHelper()
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
            console.log("Hue Service: Light "+toggleLightID+" is being set to: "+!data.state.on)
            setPower(toggleLightID, !data.state.on)
            toggleRunning = false
            toggleLightID = 0
          }
        }
      }
    }

    Process {
      id: getGroupData
      running: false
      stdout: StdioCollector {
        onStreamFinished: {
          const data = JSON.parse(text.trim())
          if (toggleGroupRunning) {
            console.log("Hue Service: Group "+toggleGroupID+" is being set to: "+!data.state.any_on)
            setGroupPower(toggleGroupID, !data.state.any_on)
            toggleGroupRunning = false
            toggleGroupID = 0
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
          let groups_list = {}
          for (let i = 0; i < ids.length; i++) {
            groups_list[ids[i]] = {
                        "id": ids[i],
                        "lights": data[ids[i]].lights,
                        "name": data[ids[i]].name,
                        "on": data[ids[i]].action.on,
                        "all_on": data[ids[i]].state.all_on,
                        "any_on": data[ids[i]].state.any_on,
                        "bri": data[ids[i]].action.bri,
                        "hue": data[ids[i]].action.hue,
                        "sat": data[ids[i]].action.sat,
                        "effect": data[ids[i]].action.effect,
                        "xy": data[ids[i]].action.xy
                      }
                    }
          root.groups = groups_list
        }
      }
    }

    function getLightDataHelper(id) {
      getLightData.command = ["sh", "-c", "curl "+bridgeIP+"/api/"+api+"/lights/"+id]
      getLightData.running = true
    }

    function getGroupDataHelper(id) {
      getGroupData.command = ["sh", "-c", "curl "+bridgeIP+"/api/"+api+"/groups/"+id]
      getGroupData.running = true
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

    function hueGroupRunCommandHelper(id, param) {
      let request = "curl "+"-X "+"PUT "+"-d "+param+" "+bridgeIP+"/api/"+api+"/groups/"+id+"/action";
      setHueCommand.command = ["bash", "-c", request]
      //console.log(setHueCommand.command)
      setHueCommand.running = true
    }

    function setBrightness(id, value) {
      let param = "'{"+'"bri": '+value+"}'";
      hueRunCommandHelper(id, param);
    }

    function setGroupBrightness(id, value) {
      let param = "'{"+'"bri": '+value+"}'";
      hueGroupRunCommandHelper(id, param);
      root.groups[id] = Object.assign({}, root.groups[id], {"bri": value})
      root.groups = Object.assign({}, root.groups) // Forces the update to widget
      for (let i=0; i<groups[id].lights.length; i++) {
        updateLightBri(root.groups[id].lights[i], value);
      }
    }

    function toggleGroupPower(id) {
      toggleGroupID = id
      toggleGroupRunning = true
      getGroupDataHelper(id);
    }

    function togglePower(id) {
      toggleLightID = id
      toggleRunning = true
      getLightDataHelper(id);
    }

    function setPower(id, value) {
      let param = "'{"+'"on": '+value+"}'";
      hueRunCommandHelper(id, param);
      updateLightOn(id, value)
    }

    function setGroupPower(id, value) {
      let param = "'{"+'"on": '+value+"}'";
      hueGroupRunCommandHelper(id, param);
      root.groups[id] = Object.assign({}, root.groups[id], {"any_on": value})
      root.groups = Object.assign({}, root.groups) // Forces the update to widget
      for (let i=0; i<groups[id].lights.length; i++) {
        updateLightOn(root.groups[id].lights[i], value)
      }
    }

    function updateLightOn(id, value) {
      root.lights[id] = Object.assign({}, root.lights[id], { "on" : value })
      root.lights = Object.assign({}, root.lights) // Forces the update to widget
    }

    function updateLightBri(id, value) {
      root.lights[id] = Object.assign({}, root.lights[id], { "bri" : value })
      root.lights = Object.assign({}, root.lights) // Forces the update to widget
    }

    function getColor() {
        // TODO: Get color from hue bridge
        return autoHueColor
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
        let ids = lights != null ? Object.keys(lights) : {}

        for (let i = 0; i < ids.length; i++) {
            hueRunCommandHelper(ids[i], param)
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
        } else if (key === "updateOnRelease") {
            updateOnRelease = value
        } else {
            getLightsHelper()
            getGroupsHelper()
        }

    }

    function applySettings(values) {
        bridgeIP = values["bridgeIP"].trim()
        api = values["api"].trim()
        autoColor = values["autoColor"]
        updateOnRelease = values["updateOnRelease"]
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
