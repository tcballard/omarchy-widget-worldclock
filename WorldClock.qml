import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.Commons
import qs.Ui as Ui
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
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Style.space(4)
        anchors.topMargin: Style.space(25)
        spacing: Style.space(root.compact ? 3 : 10)
        ListView {
            id:list
            objectName:"city-strip"
            Layout.fillWidth:true; Layout.fillHeight:true
            orientation:ListView.Horizontal
            clip:true
            boundsBehavior:Flickable.StopAtBounds
            model:root.rows
            activeFocusOnTab:true
            Keys.onRightPressed:incrementCurrentIndex()
            Keys.onLeftPressed:decrementCurrentIndex()
            highlightRangeMode:ListView.ApplyRange
            delegate:Item {
                id:city
                required property var modelData
                readonly property bool isHome:root.home !== null && root.home.zone === modelData.zone
                readonly property color ink:isHome ? Color.accent : Color.foreground
                width:list.width / Math.max(1,Math.floor(list.width/Style.space(155)))
                height:list.height
                Rectangle { anchors.right:parent.right; height:parent.height; width:1; color:Color.muted; opacity:0.3 }
                ColumnLayout {
                    anchors.fill:parent; anchors.leftMargin:Style.space(10); anchors.rightMargin:Style.space(10)
                    spacing:Style.space(root.compact ? 2 : 8)
                    Label { text:city.modelData.label.toUpperCase(); font.family:root.labelFamily; font.letterSpacing:1; font.pixelSize:Style.font.bodySmall; Layout.fillWidth:true }
                    Item {
                        Layout.fillWidth:true; Layout.fillHeight:true
                        Layout.minimumHeight:Style.space(root.analogue ? 48 : 30)
                        Label {
                            anchors.centerIn:parent; width:parent.width; horizontalAlignment:Text.AlignHCenter
                            visible:!root.analogue || !city.modelData.valid
                            text:city.modelData.time; color:city.ink; font.family:root.labelFamily
                            font.pixelSize:Math.min(parent.width*0.28,Style.space(root.compact ? 34 : 56))
                        }
                        Canvas {
                            id:dial
                            visible:root.analogue && city.modelData.valid
                            anchors.centerIn:parent
                            width:Math.min(parent.width,parent.height,Style.space(140)); height:width
                            property string clockTime:city.modelData.time
                            property color ink:city.ink
                            property color muted:Color.muted
                            onClockTimeChanged:requestPaint()
                            onInkChanged:requestPaint()
                            onMutedChanged:requestPaint()
                            onWidthChanged:requestPaint()
                            onVisibleChanged:if(visible)requestPaint()
                            onPaint: {
                                var ctx=getContext("2d"), r=width/2-2;
                                if(r<=0)return;
                                ctx.reset();ctx.translate(width/2,height/2);
                                ctx.strokeStyle=muted;ctx.lineWidth=1;
                                ctx.beginPath();ctx.arc(0,0,r,0,Math.PI*2);ctx.stroke();
                                for(var i=0;i<12;i++) {
                                    var a=i*Math.PI/6;
                                    ctx.beginPath();ctx.moveTo(Math.sin(a)*r*.85,-Math.cos(a)*r*.85);
                                    ctx.lineTo(Math.sin(a)*r*.96,-Math.cos(a)*r*.96);ctx.stroke();
                                }
                                var parts=clockTime.split(":"), h=Number(parts[0]), m=Number(parts[1]);
                                function hand(angle,length,thickness) {
                                    ctx.strokeStyle=ink;ctx.lineWidth=thickness;ctx.lineCap="round";
                                    ctx.beginPath();ctx.moveTo(0,0);ctx.lineTo(Math.sin(angle)*r*length,-Math.cos(angle)*r*length);ctx.stroke();
                                }
                                hand((h%12+m/60)*Math.PI/6,.52,3);
                                hand(m*Math.PI/30,.78,2);
                                ctx.fillStyle=ink;ctx.beginPath();ctx.arc(0,0,2.5,0,Math.PI*2);ctx.fill();
                            }
                        }
                    }
                    Label { text:!city.modelData.valid ? "Unknown timezone" : (city.isHome ? "Home" : Model.homeOffset(city.modelData,root.home)) + " · " + (city.modelData.day ? "Day" : "Night"); color:city.isHome?Color.accent:Color.muted; font.pixelSize:Style.font.bodySmall; Layout.fillWidth:true }
                    Label { visible:!root.compact; text:Model.homeDay(city.modelData,root.home) || city.modelData.date; color:Color.muted; font.pixelSize:Style.font.bodySmall; Layout.fillWidth:true }
                    Rectangle {
                        visible:!root.compact && city.modelData.valid
                        Layout.fillWidth:true; height:Style.space(5); color:Qt.rgba(Color.muted.r,Color.muted.g,Color.muted.b,.25)
                        Rectangle { x:parent.width*7/24; width:parent.width*12/24; height:parent.height; color:Color.accent; opacity:.35 }
                        Rectangle { x:Math.max(0,Math.min(parent.width-width,parent.width*Model.minuteOfDay(city.modelData)/1440)); width:2; height:parent.height+4; anchors.verticalCenter:parent.verticalCenter; color:city.ink }
                    }
                }
            }
            Label { anchors.centerIn:parent; text:root.cities.length?"Updating…":"No cities configured"; visible:root.rows.length===0 && !root.error }
        }
        Label { text:root.error; visible:text!==""; color:Color.urgent; Layout.fillWidth:true; wrapMode:Text.Wrap; font.pixelSize:Style.font.bodySmall }
    }
    Ui.Button {
        objectName:"settings-gear"
        anchors.right:parent.right; anchors.top:parent.top
        text:"⚙"; tooltipText:"World Clock settings"; focusable:true
        fontSize:Style.font.heading
        Accessible.name:"World Clock settings"
        onClicked:root.openSettings()
    }
}
