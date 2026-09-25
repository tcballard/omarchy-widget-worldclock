import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.Commons
import "Model.js" as Model

Item {
    id: root
    required property var widgetContext
    readonly property var appearance: widgetContext.appearance || ({})
    readonly property string labelFamily: typeof appearance.fontFamily === "string" ? appearance.fontFamily : Style.font.family
    function openSettings() { widgetContext.requestConfigure(); }
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
    readonly property bool analogue: widgetContext.settings.displayMode === "analogue"
    readonly property bool compact: height < Style.space(240)
    readonly property var home: rows.find(function(r) { return r.zone === (root.widgetContext.settings.homeZone || "Europe/London") && r.valid; }) || rows.find(function(r) { return r.valid; }) || null
    readonly property bool small: widgetContext.family === "small"
    readonly property string styleName: (widgetContext.settings.style || (small ? "monolith" : "solar"))
    readonly property string viewName: analogue ? "analogue" : "digital"
    readonly property var shown: rows.filter(function(r) { return r.valid; }).slice(0,small ? 4 : 5)
    readonly property var clockColors: [Color.accent, "#40c8e0", "#8b82e8", "#70cb86", "#ef819a"]
    ColumnLayout {
        anchors.fill:parent; anchors.margins:Style.space(small ? 8 : 14); spacing:Style.space(8)
        Label { text:small ? "CLOCK" : "WORLD CLOCK"; font.family:root.labelFamily; font.bold:true; font.letterSpacing:1.4; color:Color.accent; font.pixelSize:Style.font.bodySmall; Layout.fillWidth:true }
        Rectangle { Layout.fillWidth:true; Layout.preferredHeight:1; color:Color.foreground; opacity:.12 }
        Item {
            Layout.fillWidth:true; Layout.fillHeight:true
            Loader { anchors.fill:parent; sourceComponent:root.small ? (root.styleName==="twin" ? twinComponent : monolithComponent) : (root.styleName==="classic" ? classicComponent : solarComponent) }
            Label { anchors.centerIn:parent; text:root.cities.length ? "Updating…" : "No cities configured"; visible:root.rows.length===0 && !root.error }
        }
        Label { text:root.error; visible:text!==""; color:Color.urgent; Layout.fillWidth:true; wrapMode:Text.Wrap; font.pixelSize:Style.font.bodySmall }
    }
    Component {
        id: solarComponent
        RowLayout {
            visible: root.rows.length > 0
            spacing: Style.space(12)
            ClockFace { visible: root.viewName === "analogue"; solar: true; rows: root.shown; colors: root.clockColors; Layout.preferredWidth: Math.min(parent.height-Style.space(4),parent.width*.42); Layout.preferredHeight: Layout.preferredWidth }
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
                visible: root.viewName === "analogue"; anchors.centerIn: parent; spacing: Style.space(root.width > Style.space(500) ? 15 : 6)
                Repeater { model: root.shown.slice(0,4); delegate: Column {
                    required property var modelData; required property int index
                    width: Math.min((classicArea.width-Style.space(root.width > Style.space(500) ? 45 : 18))/Math.max(1,Math.min(4,root.shown.length)),Style.space(120)); spacing: Style.space(7)
                    ClockFace { anchors.horizontalCenter: parent.horizontalCenter; width: Math.min(parent.width-Style.space(4),classicArea.height*.72); height: width; row: modelData }
                    Label { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.label.length>8 ? modelData.label.slice(0,7)+"…" : modelData.label; font.bold: true; font.pixelSize: Style.font.bodySmall }
                    Label { anchors.horizontalCenter: parent.horizontalCenter; text: index === 0 ? "Home" : Model.homeOffset(modelData,root.home) || modelData.offset; color: Color.muted; font.pixelSize: Style.font.bodySmall }
                } }
            }
            Grid {
                visible: root.viewName === "digital"; anchors.centerIn: parent; columns: 2; rowSpacing: Style.space(14); columnSpacing: Style.space(20)
                Repeater { model: root.shown.slice(0,4); delegate: Column {
                    required property var modelData; required property int index
                    width: (classicArea.width-Style.space(20))/2; spacing: 2
                    Label { text: (modelData.day ? "☀ " : "☾ ")+modelData.label; color: Color.muted; elide: Text.ElideRight; width: parent.width }
                    Label { text: modelData.time; font.pixelSize: Style.font.heading+Style.space(10); font.bold: true }
                    Label { text: (Model.homeDay(modelData,root.home) || "Today")+" · "+(index===0?"Home":Model.homeOffset(modelData,root.home) || modelData.offset); color: Color.muted; font.pixelSize: Style.font.bodySmall }
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
            ClockFace { visible: root.viewName === "analogue"; row: root.shown[0] || ({}); Layout.alignment: Qt.AlignHCenter; Layout.preferredWidth: Math.min(parent.width*.76,parent.height*.72); Layout.preferredHeight: Layout.preferredWidth }
            Label { visible: root.viewName === "analogue"; text: root.shown.length ? root.shown[0].label + " · " + (Model.homeDay(root.shown[0],root.home) || "Today") : ""; Layout.alignment: Qt.AlignHCenter; font.bold: true }
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
                ClockFace { visible: root.viewName === "analogue"; row: modelData; Layout.preferredWidth: Math.min(Style.space(86),root.height*.31); Layout.preferredHeight: Layout.preferredWidth }
                ColumnLayout { Layout.fillWidth: true
                    Label { text: modelData.label; font.bold: true; elide: Text.ElideRight; Layout.fillWidth: true }
                    Label { text: root.viewName === "digital" ? modelData.time : (index===0?"Home":Model.homeOffset(modelData,root.home) || modelData.offset); font.pixelSize: root.viewName === "digital" ? Style.font.heading+Style.space(10) : Style.font.bodySmall; color: root.viewName === "digital" ? Color.foreground : Color.muted }
                }
            } }
        }
    }
}
