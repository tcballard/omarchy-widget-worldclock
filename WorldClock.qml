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
    ColumnLayout {
        visible: !root.editingCities
        anchors.fill: parent
        anchors.margins: Style.space(root.widgetContext.sizeName === "compact" ? 16 : 20)
        spacing: Style.space(10)

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: Style.space(30)
            spacing: Style.space(8)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Label {
                    text: "WORLD CLOCK"
                    font.family: root.labelFamily
                    font.pixelSize: Style.font.bodySmall
                    font.bold: true
                    font.letterSpacing: 1.6
                    color: Color.accent
                }
                Label {
                    text: "Around the world"
                    font.family: root.labelFamily
                    font.pixelSize: Style.font.heading
                    font.bold: true
                    color: Color.foreground
                    visible: root.widgetContext.sizeName !== "compact"
                }
            }
            Ui.Button {
                text: "Edit cities"
                focusable: true
                fontSize: Style.font.bodySmall
                onClicked: root.editCities()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Color.foreground
            opacity: 0.12
        }

        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: root.rows
            spacing: Style.space(4)
            delegate: Rectangle {
                required property var modelData
                width: ListView.view.width
                height: Style.space(root.widgetContext.sizeName === "compact" ? 47 : 55)
                radius: Style.space(8)
                color: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, index % 2 === 0 ? 0.045 : 0.018)
                required property int index

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Style.space(10)
                    anchors.rightMargin: Style.space(10)
                    spacing: Style.space(9)
                    Rectangle {
                        Layout.preferredWidth: Style.space(6)
                        Layout.preferredHeight: Style.space(6)
                        radius: width / 2
                        color: modelData.day ? Color.accent : Color.muted
                        opacity: modelData.day ? 1 : 0.55
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Label {
                            text: modelData.label
                            font.family: root.labelFamily
                            font.pixelSize: Style.font.body
                            font.bold: true
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Label {
                            text: modelData.date + (modelData.relative ? "  ·  " + modelData.relative : "")
                            color: modelData.valid ? Color.muted : Color.urgent
                            font.family: root.labelFamily
                            font.pixelSize: Style.font.bodySmall
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                    Label {
                        visible: root.widgetContext.sizeName === "wide"
                        text: modelData.offset
                        color: Color.muted
                        font.family: root.labelFamily
                        font.pixelSize: Style.font.bodySmall
                    }
                    Label {
                        text: modelData.time
                        font.family: root.labelFamily
                        font.pixelSize: Style.font.heading + Style.space(4)
                        font.bold: true
                        color: modelData.valid ? Color.foreground : Color.urgent
                    }
                }
            }
            Label {
                anchors.centerIn: parent
                text: root.cities.length ? "Updating…" : "No cities configured"
                visible: root.rows.length === 0 && !root.error
            }
        }
        Label {
            text: root.error
            visible: text !== ""
            color: Color.urgent
            Layout.fillWidth: true
            wrapMode: Text.Wrap
        }
        RowLayout {
            Layout.fillWidth: true
            Label {
                text: root.error ? "Displayed times may be stale" : "LOCAL TIME · 24 HOUR"
                font.family: root.labelFamily
                color: Color.muted
                font.pixelSize: Style.font.bodySmall
                font.letterSpacing: 0.8
                Layout.fillWidth: true
            }
            Rectangle {
                width: Style.space(5)
                height: width
                radius: width / 2
                color: Color.accent
            }
            Label {
                text: "DAYTIME"
                font.family: root.labelFamily
                color: Color.muted
                font.pixelSize: Style.font.bodySmall
                font.letterSpacing: 0.8
            }
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
