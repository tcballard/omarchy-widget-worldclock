import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui as Ui
import "Model.js" as Model

FocusScope {
    id: root
    property bool showActions: true
    property var initial: []
    property var draft: []
    property string message: ""
    property bool busy: false
    property string family: Style.font.family
    signal cancelled()
    signal submitted(var cities)
    function reset() { draft=JSON.parse(JSON.stringify(initial)); message=""; search.text=""; }
    function removeAt(i) { var next=draft.slice(); next.splice(i,1); draft=next; }
    function move(i,d) { var next=draft.slice(); var j=i+d; if(j<0||j>=next.length)return; var c=next[i];next[i]=next[j];next[j]=c;draft=next; }
    function add(zone) {
        if(draft.length>=12) { message="Maximum twelve cities"; return; }
        if(!/^[A-Za-z0-9_+-]+(\/[A-Za-z0-9_+-]+)*$/.test(zone) || zone.length>100) { message="Choose a timezone or enter an IANA ID"; return; }
        if(draft.some(function(c){return c.zone===zone})) { message="That timezone is already listed"; return; }
        draft=draft.concat([{label:zone.split("/").pop().replace(/_/g," "),zone:zone}]); search.text="";message="";
    }
    // Embedded API 2 editors let Core own Escape/Cancel, including its busy guard.
    Keys.onEscapePressed: function(event) {
        if(showActions) cancelled();
        else event.accepted=false;
    }
    ColumnLayout {
        anchors.fill:parent; spacing:Style.space(8)
        RowLayout {
            Layout.fillWidth:true
            Label { text:"Your cities"; font.family:root.family; font.pixelSize:Style.font.heading; Layout.fillWidth:true }
            Label { text:root.draft.length+" / 12"; color:Color.muted }
        }
        Label { text:"Edit labels · use arrows to reorder"; font.family:root.family; color:Color.muted; font.pixelSize:Style.font.bodySmall; Layout.fillWidth:true }
        ListView {
            Layout.fillWidth:true; Layout.fillHeight:true; clip:true; spacing:Style.space(4)
            model:root.draft
            delegate:RowLayout {
                required property var modelData
                required property int index
                width:ListView.view.width; height:Style.space(40)
                Rectangle {
                    Layout.fillWidth:true; Layout.preferredHeight:Style.space(34);radius:Style.space(5)
                    color:Qt.rgba(Color.foreground.r,Color.foreground.g,Color.foreground.b,0.04)
                    border.width:name.activeFocus?1:0;border.color:Color.accent
                    TextInput {
                        id:name;anchors.fill:parent;anchors.margins:Style.space(6);text:modelData.label;maximumLength:48;clip:true
                        color:Color.foreground;font.family:root.family;font.pixelSize:Style.font.body;selectByMouse:true
                        onTextEdited: { var next=root.draft.slice(); next[index]=Object.assign({},next[index],{label:text}); root.draft=next; }
                        Accessible.name: "City label for "+modelData.zone
                    }
                }
                Ui.Button { text:"↑";focusable:true;enabled:index>0&&!root.busy;onClicked:root.move(index,-1) }
                Ui.Button { text:"↓";focusable:true;enabled:index<root.draft.length-1&&!root.busy;onClicked:root.move(index,1) }
                Ui.Button { text:"×";focusable:true;enabled:!root.busy;onClicked:root.removeAt(index) }
            }
        }
        Rectangle {
            Layout.fillWidth:true;Layout.preferredHeight:Style.space(36);radius:Style.space(6)
            color:Qt.rgba(Color.foreground.r,Color.foreground.g,Color.foreground.b,0.04)
            border.width:1;border.color:search.activeFocus?Color.accent:Color.muted
            TextInput {
                id:search;objectName:"city-search";anchors.fill:parent;anchors.margins:Style.space(8);maximumLength:100;clip:true
                color:Color.foreground;font.family:root.family;font.pixelSize:Style.font.body;selectByMouse:true
                onAccepted:root.add(text.trim())
                Accessible.name:"Search cities or enter an IANA timezone"
            }
            Label { anchors.fill:search;visible:search.text==="";text:"Search cities / IANA timezone";color:Color.muted;font.family:root.family }
        }
        ListView {
            Layout.fillWidth:true;Layout.preferredHeight:search.text?Style.space(74):0;visible:search.text!=="";clip:true
            model:Model.catalog.filter(function(z){return z.toLowerCase().replace(/_/g," ").indexOf(search.text.toLowerCase())>=0}).slice(0,12)
            delegate:Ui.Button { required property string modelData; text:modelData.replace(/_/g," ");width:ListView.view.width;focusable:true;onClicked:root.add(modelData) }
        }
        Label { text:root.message;visible:text!=="";color:Color.urgent;Layout.fillWidth:true;wrapMode:Text.Wrap }
        RowLayout {
            Layout.fillWidth:true
            Ui.Button { text:"Cancel";visible:root.showActions;focusable:true;enabled:!root.busy;onClicked:root.cancelled() }
            Item { Layout.fillWidth:true }
            Ui.Button { text:"Add ID";visible:search.text!=="";focusable:true;enabled:!root.busy;onClicked:root.add(search.text.trim()) }
            Ui.Button { text:root.busy?"Saving…":"Save";visible:root.showActions;objectName:"save-cities";focusable:true;enabled:!root.busy;onClicked:root.submitted(root.draft) }
        }
    }
}

