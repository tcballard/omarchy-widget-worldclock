import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.Commons
import qs.Ui as Ui
import "Model.js" as Model

Item {
    id: root
    required property var widgetContext
    property bool editingCities: false
    readonly property var appearance: widgetContext.appearance || ({})
    readonly property string labelFamily: typeof appearance.fontFamily === "string" ? appearance.fontFamily : Style.font.family
    function editCities() {
        if(!widgetContext.requestInput) { error="Update Widget Core to enable the city editor"; return; }
        editor.reset(); editingCities=true; widgetContext.requestInput(true); editor.forceActiveFocus();
    }
    function closeEditor() { editingCities=false; widgetContext.requestInput(false); }
    function saveCities(value) {
        var settings=Object.assign({},widgetContext.settings,{cities:value});
        if(!widgetContext.saveSettings(settings)) editor.message="Core is busy. Try Save again.";
    }
    readonly property var cities: Model.cities(widgetContext.settings)
    property var rows: []
    property string error: ""
    property int sampledMinute: -1
    property int generation: 0
    property int requestGeneration: 0
    property var requestedCities: []
    property string requestedDate: ""
    property bool expired: false
    function refresh() {
        if (!widgetContext.active || sample.running || !cities.length) return;
        var now=new Date();
        sampledMinute=Math.floor(now.getTime()/60000);
        requestGeneration=generation;
        requestedCities=cities;
        requestedDate=Qt.formatDateTime(now,"yyyy-MM-dd");
        expired=false;
        var path=decodeURIComponent(Qt.resolvedUrl("scripts/times").toString().replace(/^file:\/\//,""));
        sample.command=["/usr/bin/timeout","--kill-after=1","3","/usr/bin/bash",path,String(Math.floor(now.getTime()/1000))].concat(cities.map(function(c){return c.zone}));
        sample.running=true;
        deadline.restart();
    }
    onCitiesChanged: { generation++; sampledMinute=-1; rows=[]; Qt.callLater(refresh); }
    Component.onCompleted: refresh()
    Timer { interval:1000; repeat:true; running:root.widgetContext.active; onTriggered: { if(Math.floor(Date.now()/60000)!==root.sampledMinute) root.refresh(); } }
    Timer { id:deadline; interval:5000; onTriggered: { root.expired=true; sample.running=false; root.error="Time update timed out"; } }
    Process {
        id:sample
        stdout:StdioCollector { id:output; waitForEnd:true }
        onExited:function(code,status) {
            deadline.stop();
            if(root.expired) return;
            if(root.requestGeneration!==root.generation) { Qt.callLater(root.refresh); return; }
            try {
                if(code!==0 || output.text.length>4096) throw new Error("Time update failed");
                root.rows=Model.rows(output.text,root.requestedCities,root.requestedDate);
                root.error="";
            } catch(e) { root.error="Time update failed · check coreutils and tzdata"; }
        }
    }
    readonly property bool small: widgetContext.sizeName === "compact"
    readonly property string styleName: widgetContext.settings && widgetContext.settings.style
        ? widgetContext.settings.style : (small ? "monolith" : "solar")
    readonly property string viewName: widgetContext.settings && widgetContext.settings.view
        ? widgetContext.settings.view : "analogue"
    readonly property var shown: rows.slice(0, small ? 4 : 5)
    readonly property var clockColors: [Color.accent, "#40c8e0", "#8b82e8", "#70cb86", "#ef819a"]
    function changeOption(key,value) {
        var next=Object.assign({},widgetContext.settings);next[key]=value;
        if(!widgetContext.saveSettings(next)) error="Could not save clock style";
    }
    ColumnLayout {
        visible: !root.editingCities
        anchors.fill: parent
        anchors.margins: Style.space(root.small ? 16 : 20)
        spacing: Style.space(8)
        RowLayout {
            Layout.fillWidth: true
            Label { text: "WORLD CLOCK"; font.bold: true; font.letterSpacing: 1.4; font.pixelSize: Style.font.bodySmall; color: Color.accent; Layout.fillWidth: true }
            Ui.Button { text: root.viewName === "analogue" ? "Digital" : "Analogue"; fontSize: Style.font.bodySmall; onClicked: root.changeOption("view",root.viewName === "analogue" ? "digital" : "analogue") }
            Ui.Button { text: root.small ? (root.styleName === "twin" ? "Monolith" : "Twin") : (root.styleName === "classic" ? "Solar" : "Classic"); fontSize: Style.font.bodySmall; onClicked: root.changeOption("style",root.small ? (root.styleName === "twin" ? "monolith" : "twin") : (root.styleName === "classic" ? "solar" : "classic")) }
            Ui.Button { text: "Edit"; fontSize: Style.font.bodySmall; onClicked: root.editCities() }
        }
        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Color.foreground; opacity: .12 }
        Item {
            Layout.fillWidth: true; Layout.fillHeight: true
            Loader {
                anchors.centerIn: parent
                width: Math.min(parent.width,root.small ? Style.space(300) : Style.space(470))
                height: Math.min(parent.height,root.small ? Style.space(275) : Style.space(270))
                sourceComponent: root.small
                    ? (root.styleName === "twin" ? twinComponent : monolithComponent)
                    : (root.styleName === "classic" ? classicComponent : solarComponent)
            }
            Label { anchors.centerIn: parent; text: root.cities.length ? "Updating…" : "No cities configured"; visible: root.rows.length === 0 && !root.error }
        }
        Label { text: root.error; visible: text !== ""; color: Color.urgent; Layout.fillWidth: true }
    }
    Component {
        id: solarComponent
        RowLayout {
            visible: root.rows.length > 0
            spacing: Style.space(16)
            ClockFace { visible: root.viewName === "analogue"; solar: true; rows: root.shown; colors: root.clockColors; Layout.preferredWidth: Math.min(parent.height,parent.width*.46); Layout.preferredHeight: Layout.preferredWidth }
            ColumnLayout {
                visible: root.viewName === "analogue"; Layout.fillWidth: true; spacing: Style.space(8)
                Repeater { model: root.shown; delegate: RowLayout {
                    required property var modelData; required property int index
                    Layout.fillWidth: true; spacing: Style.space(7)
                    Rectangle { width: 8; height: 8; radius: 4; color: root.clockColors[index] }
                    Label { text: modelData.label; elide: Text.ElideRight; Layout.fillWidth: true }
                    Label { text: modelData.time; color: Color.muted; font.family: root.labelFamily }
                } }
            }
            ColumnLayout {
                visible: root.viewName === "digital"; Layout.fillWidth: true; spacing: Style.space(8)
                Repeater { model: root.shown; delegate: ColumnLayout {
                    id: digitalCity
                    required property var modelData; required property int index
                    Layout.fillWidth: true; spacing: 3
                    RowLayout { Layout.fillWidth: true; Label { text: modelData.label; Layout.fillWidth: true } Label { text: modelData.time; font.bold: true } }
                    Row { Layout.fillWidth: true; spacing: 1; Repeater { model: 24; delegate: Rectangle {
                        required property int index
                        width: Math.max(2,(parent.width-23)/24); height: Style.space(12); radius: 2
                        color: index>=8 && index<18 ? root.clockColors[digitalCity.index] : Color.foreground
                        opacity: index>=8 && index<18 ? .55 : (index>=6 && index<18 ? .1 : .22)
                    } } }
                } }
            }
        }
    }
    Component {
        id: classicComponent
        Item {
            visible: root.rows.length > 0
            Row {
                visible: root.viewName === "analogue"; anchors.centerIn: parent; spacing: Style.space(9)
                Repeater { model: root.shown.slice(0,4); delegate: Column {
                    required property var modelData; required property int index
                    width: Math.min((classicArea.width-Style.space(27))/Math.max(1,Math.min(4,root.shown.length)),Style.space(105)); spacing: Style.space(5)
                    ClockFace { anchors.horizontalCenter: parent.horizontalCenter; width: Math.min(parent.width-8,classicArea.height*.54); height: width; row: modelData }
                    Label { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.label.length>8 ? modelData.label.slice(0,7)+"…" : modelData.label; font.bold: true; font.pixelSize: Style.font.bodySmall }
                    Label { anchors.horizontalCenter: parent.horizontalCenter; text: index === 0 ? "Home" : modelData.homeOffset || modelData.offset; color: Color.muted; font.pixelSize: Style.font.bodySmall }
                } }
            }
            Grid {
                visible: root.viewName === "digital"; anchors.centerIn: parent; columns: 2; rowSpacing: Style.space(14); columnSpacing: Style.space(20)
                Repeater { model: root.shown.slice(0,4); delegate: Column {
                    required property var modelData; required property int index
                    width: (classicArea.width-Style.space(20))/2; spacing: 2
                    Label { text: (modelData.day ? "☀ " : "☾ ")+modelData.label; color: Color.muted; elide: Text.ElideRight; width: parent.width }
                    Label { text: modelData.time; font.pixelSize: Style.font.heading+Style.space(10); font.bold: true }
                    Label { text: (modelData.homeRelative || "Today")+" · "+(index===0?"Home":modelData.homeOffset || modelData.offset); color: Color.muted; font.pixelSize: Style.font.bodySmall }
                } }
            }
            property alias classicArea: classicArea
            Item { id: classicArea; anchors.fill: parent; z: -1 }
        }
    }
    Component {
        id: monolithComponent
        ColumnLayout {
            visible: root.rows.length > 0; spacing: Style.space(8)
            ClockFace { visible: root.viewName === "analogue"; row: root.shown[0] || ({}); Layout.alignment: Qt.AlignHCenter; Layout.preferredWidth: Math.min(parent.width*.6,parent.height*.62); Layout.preferredHeight: Layout.preferredWidth }
            Label { visible: root.viewName === "analogue"; text: root.shown.length ? root.shown[0].label + " · " + (root.shown[0].homeRelative || "Today") : ""; Layout.alignment: Qt.AlignHCenter; font.bold: true }
            Label { visible: root.viewName === "digital"; text: root.shown.length ? root.shown[0].label : ""; color: Color.accent; font.bold: true }
            Label { visible: root.viewName === "digital"; text: root.shown.length ? root.shown[0].time : ""; font.pixelSize: Style.font.heading+Style.space(24); font.bold: true; Layout.fillHeight: true; verticalAlignment: Text.AlignVCenter }
            Repeater { model: root.viewName === "digital" ? root.shown.slice(1,4) : []; delegate: RowLayout {
                required property var modelData; Layout.fillWidth: true
                Label { text: modelData.label; color: Color.muted; Layout.fillWidth: true }
                Label { text: modelData.time; color: Color.muted }
            } }
        }
    }
    Component {
        id: twinComponent
        ColumnLayout {
            visible: root.rows.length > 0; spacing: Style.space(4)
            Repeater { model: root.shown.slice(0,2); delegate: RowLayout {
                required property var modelData; required property int index
                Layout.fillWidth: true; Layout.fillHeight: true
                ClockFace { visible: root.viewName === "analogue"; row: modelData; Layout.preferredWidth: Style.space(76); Layout.preferredHeight: Layout.preferredWidth }
                ColumnLayout { Layout.fillWidth: true
                    Label { text: modelData.label; font.bold: true; elide: Text.ElideRight; Layout.fillWidth: true }
                    Label { text: root.viewName === "digital" ? modelData.time : (index===0?"Home":modelData.homeOffset || modelData.offset); font.pixelSize: root.viewName === "digital" ? Style.font.heading+Style.space(10) : Style.font.bodySmall; color: root.viewName === "digital" ? Color.foreground : Color.muted }
                }
            } }
        }
    }
    CityEditor {
        id:editor;objectName:"city-editor";anchors.fill:parent;anchors.margins:Style.space(14);visible:root.editingCities
        initial:root.cities;family:root.labelFamily;busy:root.widgetContext.saving || false
        onCancelled:root.closeEditor()
        onSubmitted:function(value){root.saveCities(value)}
        Connections {
            target:root.widgetContext;ignoreUnknownSignals:true
            function onSaveErrorChanged() { if(root.widgetContext.saveError) editor.message=root.widgetContext.saveError; }
        }
    }
}
