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
        visible:!root.editingCities
        anchors.fill:parent; anchors.margins:Style.space(14); spacing:Style.space(8)
        RowLayout {
            Layout.fillWidth:true
            Label { text:"World Clock"; font.family:root.labelFamily; font.pixelSize:Style.font.title || Style.font.heading; Layout.fillWidth:true }
            Ui.Button { text:"Edit cities";focusable:true;fontSize:Style.font.bodySmall;onClicked:root.editCities() }
        }
        ListView {
            id:list
            Layout.fillWidth:true; Layout.fillHeight:true; clip:true
            model:root.rows; spacing:0
            delegate:Item {
                required property var modelData
                width:ListView.view.width; height:Style.space(root.widgetContext.sizeName==="compact"?43:54)
                Rectangle { anchors.bottom:parent.bottom; width:parent.width; height:1; color:Color.foreground; opacity:typeof root.appearance.separatorAlpha==="number"?Math.max(0,Math.min(1,root.appearance.separatorAlpha)):0.07 }
                RowLayout {
                    anchors.fill:parent; spacing:Style.space(10)
                    Rectangle { width:Style.space(5); height:Style.space(5);radius:width/2; color:modelData.day?Color.accent:Color.muted; opacity:modelData.day?1:0.45 }
                    ColumnLayout {
                        Layout.fillWidth:true; spacing:Style.space(2)
                        Label { text:modelData.label; font.family:root.labelFamily; Layout.fillWidth:true }
                        Label { text:modelData.date+(modelData.relative?" · "+modelData.relative:""); color:modelData.valid?Color.muted:Color.urgent; font.pixelSize:Style.font.bodySmall; Layout.fillWidth:true }
                    }
                    Label { visible:root.widgetContext.sizeName==="wide"; text:modelData.offset; color:Color.muted; font.pixelSize:Style.font.bodySmall }
                    Label { text:modelData.time; font.pixelSize:Style.font.heading; color:modelData.valid?Color.foreground:Color.urgent }
                }
            }
            Label { anchors.centerIn:parent; text:root.cities.length?"Updating…":"No cities configured"; visible:root.rows.length===0 && !root.error }
        }
        Label { text:root.error; visible:text!==""; color:Color.urgent; Layout.fillWidth:true; wrapMode:Text.Wrap }
        Label { text:root.error?"Displayed times may be stale":"24-hour time · Bright dot: daytime"; font.family:root.labelFamily;color:Color.muted; font.pixelSize:Style.font.bodySmall; Layout.fillWidth:true; wrapMode:Text.Wrap }
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
