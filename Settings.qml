import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui as Ui
import "Model.js" as Model

ColumnLayout {
    id:root
    required property var settingsContext
    property bool ready:false
    readonly property string family:settingsContext.appearance.fontFamily || Style.font.family
    spacing:Style.space(8)
    function change(key,value) {
        var next=Object.assign({},settingsContext.draftSettings);
        next[key]=value; settingsContext.draftSettings=next;
    }
    function setMode(value) { if(value === "analogue" || value === "digital") change("displayMode",value); }
    Component.onCompleted: {
        editor.reset(); ready=true;
        if(!editor.draft.some(function(c){return c.zone === settingsContext.draftSettings.homeZone;})) {
            var london=editor.draft.find(function(c){return c.zone === "Europe/London";});
            change("homeZone",london ? london.zone : (editor.draft.length ? editor.draft[0].zone : ""));
        }
    }
    Label { text:"Clock display"; font.family:root.family; font.pixelSize:Style.font.heading }
    RowLayout {
        Ui.Button { objectName:"digital-mode"; text:"Digital"; focusable:true; selected:root.settingsContext.draftSettings.displayMode !== "analogue"; onClicked:root.setMode("digital") }
        Ui.Button { objectName:"analogue-mode"; text:"Analogue"; focusable:true; selected:root.settingsContext.draftSettings.displayMode === "analogue"; onClicked:root.setMode("analogue") }
    }
    Label { text:"Clock design · Solar and Classic for medium/large; Monolith and Twin for small"; color:Color.muted; font.pixelSize:Style.font.bodySmall; Layout.fillWidth:true; wrapMode:Text.Wrap }
    Flow {
        Layout.fillWidth:true; spacing:Style.space(4)
        Repeater {
            model:["solar","classic","monolith","twin"]
            Ui.Button {
                required property string modelData
                text:modelData.charAt(0).toUpperCase()+modelData.slice(1)
                focusable:true; selected:root.settingsContext.draftSettings.style === modelData
                onClicked:root.change("style",modelData)
            }
        }
    }
    Label { text:"Home city · offsets and dates are relative to this clock"; color:Color.muted; font.pixelSize:Style.font.bodySmall; Layout.fillWidth:true; wrapMode:Text.Wrap }
    Flickable {
        Layout.fillWidth:true; Layout.preferredHeight:Style.space(38)
        contentWidth:homes.width; clip:true; boundsBehavior:Flickable.StopAtBounds
        Row {
            id:homes
            Repeater {
                model:editor.draft
                Ui.Button {
                    required property var modelData
                    text:modelData.label; focusable:true
                    selected:root.settingsContext.draftSettings.homeZone === modelData.zone
                    onClicked:root.change("homeZone",modelData.zone)
                }
            }
        }
    }
    CityEditor {
        id:editor;objectName:"city-editor"
        Layout.fillWidth:true; Layout.fillHeight:true
        family:root.family; showActions:false
        initial:Model.cities(root.settingsContext.draftSettings)
        onDraftChanged:if(root.ready) {
            root.change("cities",draft);
            if(!draft.some(function(c){return c.zone === root.settingsContext.draftSettings.homeZone;}))
                root.change("homeZone",draft.length ? draft[0].zone : "");
        }
    }
}
