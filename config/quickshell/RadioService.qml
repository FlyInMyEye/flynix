import QtQuick
import Quickshell
import Quickshell.Networking
import Quickshell.Bluetooth

QtObject {
    id: root
    required property var machine
    property var networkBackend: Networking
    property var bluetoothBackend: Bluetooth
    readonly property var wifiDevices: networkBackend.devices.values.filter(d => d.type === DeviceType.Wifi)
    readonly property var wifiDevice: wifiDevices.find(d => d.connected) || wifiDevices[0] || null
    readonly property bool wifiAvailable: wifiDevice !== null && networkBackend.wifiHardwareEnabled
    readonly property bool wifiEnabled: networkBackend.wifiEnabled
    readonly property var networks: wifiDevice ? wifiDevice.networks.values.slice().sort((a, b) => Number(b.connected) - Number(a.connected) || b.signalStrength - a.signalStrength || a.name.localeCompare(b.name)) : []
    readonly property var currentNetwork: networks.find(n => n.connected) || null
    readonly property string wifiStatus: !wifiDevice ? "No Wi-Fi adapter" : !networkBackend.wifiHardwareEnabled ? "Hardware blocked" : !wifiEnabled ? "Wi-Fi off" : currentNetwork ? currentNetwork.name : "Not connected"
    readonly property var adapter: bluetoothBackend.defaultAdapter
    readonly property bool bluetoothAvailable: adapter !== null
    readonly property bool bluetoothEnabled: adapter !== null && adapter.enabled
    readonly property var devices: adapter ? adapter.devices.values.filter(d => d.paired || d.connected).sort((a, b) => Number(b.connected) - Number(a.connected) || a.name.localeCompare(b.name)) : []
    readonly property var connectedDevices: devices.filter(d => d.connected)
    readonly property string bluetoothStatus: !adapter ? "No Bluetooth adapter" : !bluetoothEnabled ? "Bluetooth off" : connectedDevices.length ? connectedDevices.map(d => d.name).join(", ") : "Not connected"
    property string error: ""
    property var pendingNetwork: null
    property bool credentialsRejected: false
    property Connections machineEvents: Connections {
        target: root.machine
        function onStateChanged() { root.error = ""; root.pendingNetwork = null; root.credentialsRejected = false; }
    }
    property Binding scan: Binding {
        target: root.wifiDevice
        property: "scannerEnabled"
        value: true
        when: root.wifiDevice !== null && root.wifiEnabled && root.machine.state === "WIFI"
        restoreMode: Binding.RestoreBindingOrValue
    }
    property Connections connectionEvents: Connections {
        target: root.pendingNetwork
        function onConnectionFailed(reason) {
            root.credentialsRejected = reason === ConnectionFailReason.NoSecrets;
            root.error = root.credentialsRejected ? "Password not accepted · select network to retry" : ConnectionFailReason.toString(reason);
        }
    }
    function toggleWifi() {
        if (!machine.locked && wifiAvailable) networkBackend.wifiEnabled = !wifiEnabled;
    }
    function toggleBluetooth() {
        if (!machine.locked && adapter) adapter.enabled = !adapter.enabled;
    }
    function needsPassword(network) {
        return (!network.known || pendingNetwork === network && credentialsRejected) && [WifiSecurityType.WpaPsk, WifiSecurityType.Wpa2Psk, WifiSecurityType.Sae].includes(network.security);
    }
    function connectWifi(network, password) {
        if (machine.locked || !wifiEnabled || !network || network.stateChanging) return;
        error = "";
        pendingNetwork = network;
        if (network.connected) network.disconnect();
        else if (needsPassword(network)) network.connectWithPsk(password);
        else if (network.known || [WifiSecurityType.Open, WifiSecurityType.Owe].includes(network.security)) network.connect();
        else error = "Use network settings for this security type";
    }
    function toggleDevice(device) {
        if (!machine.locked && bluetoothEnabled && device) device.connected = !device.connected;
    }
    function manage(bluetooth) {
        if (machine.locked) return;
        Quickshell.execDetached(bluetooth ? ["blueman-manager"] : ["kitty", "--class", "island-wifi", "nmtui-connect"]);
        machine.dismiss();
    }
}
