import os,sys,tempfile,json,subprocess
from pathlib import Path
os.environ.setdefault("QT_QPA_PLATFORM","offscreen")
from PySide6.QtCore import QUrl,QTimer,QObject,QMetaObject,Q_ARG,Qt
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtQuick import QQuickWindow
import PySide6
root=Path(__file__).resolve().parents[1]
for p in root.glob("*.qml"):
 subprocess.run([str(Path(PySide6.__file__).parent/"qmlformat"),str(p)],check=True,stdout=subprocess.DEVNULL)
stubs={'qs/Ui/Button.qml': 'import QtQuick\nimport qs.Commons\nRectangle {\n id:root\n property string text:""\n property string tooltipText:""\n property bool selected:false\n property bool focusable:false\n property real fontSize:Style.font.body\n property real horizontalPadding:Style.space(9)\n signal clicked()\n implicitWidth:label.implicitWidth+horizontalPadding*2\n implicitHeight:label.implicitHeight+Style.space(14)\n color:selected?Qt.rgba(Color.accent.r,Color.accent.g,Color.accent.b,.12):"transparent"\n border.width:activeFocus?1:0;border.color:Color.accent\n activeFocusOnTab:focusable\n Keys.onReturnPressed:clicked()\n Keys.onSpacePressed:clicked()\n Text {id:label;anchors.centerIn:parent;textFormat:Text.PlainText;text:root.text;color:root.selected?Color.accent:Color.foreground;font.family:Style.font.family;font.pixelSize:root.fontSize}\n MouseArea {anchors.fill:parent;onClicked:{if(root.focusable)root.forceActiveFocus();root.clicked()}}\n}\n', 'qs/Ui/qmldir': 'module qs.Ui\nButton 1.0 Button.qml\n', 'qs/Commons/Style.qml': 'pragma Singleton\nimport QtQuick\nQtObject {\n property real scale:1\n property int cornerRadius:0\n function spaceReal(n){return n*scale}\n function space(n){return n*scale}\n property QtObject font:QtObject {\n  property string family:"DejaVu Sans Mono"\n  property real body:12*Style.scale\n  property real bodySmall:10*Style.scale\n  property real heading:16*Style.scale\n }\n}\n', 'qs/Commons/Color.qml': 'pragma Singleton\nimport QtQuick\nQtObject {\n property bool light:false\n property color foreground:light?"#263022":"#e4e8df"\n property color background:light?"#f1f0e8":"#171c1a"\n property color accent:light?"#526c36":"#b3cb92"\n property color muted:light?"#68715e":"#8a9588"\n property color urgent:light?"#9c3e30":"#e5a085"\n}\n', 'qs/Commons/qmldir': 'module qs.Commons\nsingleton Color 1.0 Color.qml\nsingleton Style 1.0 Style.qml\n', 'Quickshell/Io/Process.qml': 'import QtQuick\nQtObject {\n property var command:[]\n property bool running:false\n property QtObject stdout:null\n signal exited(int code,int status)\n}\n', 'Quickshell/Io/StdioCollector.qml': 'import QtQuick\nQtObject {property bool waitForEnd:true;property string text:""}\n', 'Quickshell/Io/IpcHandler.qml': 'import QtQuick\nQtObject {property string target:""}\n', 'Quickshell/Io/qmldir': 'module Quickshell.Io\nProcess 1.0 Process.qml\nStdioCollector 1.0 StdioCollector.qml\nIpcHandler 1.0 IpcHandler.qml\n'}
with tempfile.TemporaryDirectory() as tmp:
 for name,text in stubs.items():
  p=Path(tmp)/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(text)
 preview=Path(tmp)/"Preview.qml"
 fixture=json.loads((root/"widget.json").read_text())["defaults"]
 preview.write_text('''import QtQuick
import qs.Commons
import "'''+root.as_uri()+'''" as Widget
import "'''+(root/"Model.js").as_uri()+'''" as Model
Window {
 width:800;height:280;visible:true;color:Color.background
 function setLight(value) { Color.light=value; }
 QtObject {
  id:context;objectName:"context";property var settings:'''+json.dumps(fixture)+''';property bool active:false
  property var appearance:({fontFamily:"DejaVu Sans Mono"})
  property int configureRequests:0
  function requestConfigure() { configureRequests++; }
  function applySettings(text) { context.settings=JSON.parse(text); }
 }
 QtObject {
  id:settingsContext;objectName:"settings-context"
  property var draftSettings:JSON.parse(JSON.stringify(context.settings))
  property var appearance:context.appearance
  function resetDraft(text) { draftSettings=JSON.parse(text); }
 }
 Widget.WorldClock {
  id:clock;objectName:"clock";anchors.fill:parent;widgetContext:context
  function populate() { rows=Model.rows("12:30|Tue 15 Sep|+01:00|12|2026-09-15\\n07:30|Tue 15 Sep|-04:00|07|2026-09-15\\n06:30|Tue 15 Sep|-05:00|06|2026-09-15\\n13:30|Tue 15 Sep|+02:00|13|2026-09-15\\n20:30|Tue 15 Sep|+09:00|20|2026-09-15\\n21:30|Tue 15 Sep|+10:00|21|2026-09-15",cities,"2026-09-15"); }
  Component.onCompleted:populate()
 }
 Widget.Settings {
  id:settings;objectName:"settings";anchors.fill:parent;visible:false;settingsContext:settingsContext
  property bool cancelledByOwner:false
  Keys.onEscapePressed:cancelledByOwner=true
 }
}
''')
 app=QGuiApplication([]);engine=QQmlApplicationEngine();engine.addImportPath(tmp)
 warnings=[];engine.warnings.connect(lambda es:warnings.extend(e.toString() for e in es))
 engine.load(QUrl.fromLocalFile(str(preview)))
 assert engine.rootObjects(),"Could not load widget"
 def check():
  from PySide6.QtTest import QTest
  window=engine.rootObjects()[0]
  clock=window.findChild(QObject,"clock")
  settings=window.findChild(QObject,"settings")
  editor=window.findChild(QObject,"city-editor")
  context=window.findChild(QObject,"context")
  sc=window.findChild(QObject,"settings-context")
  def call(obj,name,*args):
   assert QMetaObject.invokeMethod(obj,name,*[Q_ARG("QVariant",a) for a in args])
  def value(obj,key):return obj.property(key).toVariant()
  def snapshot(name):
   QTest.qWait(100)
   assert window.grabWindow().save(str(out/(name+".png")))
  out=root/"test-results";out.mkdir(exist_ok=True)
  call(clock,"openSettings")
  assert context.property("configureRequests")==1
  assert not clock.findChild(QObject,"analogue-mode"), "Settings controls must not be on the clock"
  original=value(context,"settings")
  call(settings,"setMode","analogue")
  assert value(sc,"draftSettings")["displayMode"]=="analogue"
  assert value(context,"settings")==original, "Draft must not mutate saved settings"
  call(editor,"add","Europe/Paris")
  call(editor,"move",6,-1)
  assert value(sc,"draftSettings")["cities"][5]["zone"]=="Europe/Paris"
  call(editor,"removeAt",0)
  assert value(sc,"draftSettings")["homeZone"]=="America/New_York"
  before=value(editor,"draft")
  call(editor,"add","../bad")
  assert value(editor,"draft")==before and editor.property("message")
  # Simulate Core discarding an editor draft; display still uses acknowledged settings.
  call(sc,"resetDraft",json.dumps(original))
  assert not clock.property("analogue")
  clock.setVisible(False);settings.setVisible(True)
  call(editor,"forceActiveFocus")
  QTest.keyClick(window,Qt.Key.Key_Escape)
  assert settings.property("cancelledByOwner"), "Embedded city editor swallowed Core's Escape action"
  window.setWidth(520);window.setHeight(500)
  snapshot("settings")
  settings.setVisible(False);clock.setVisible(True)
  for mode in ["digital","analogue"]:
   saved=dict(original,displayMode=mode)
   (out/"saved-settings.json").write_text(json.dumps(saved))
   call(context,"applySettings",(out/"saved-settings.json").read_text())
   call(clock,"populate")
   assert clock.property("analogue")== (mode=="analogue")
   for name,width,height in [("reference",1000,280),("small",168,168),("medium",376,168),("large",376,376)]:
    window.setWidth(width);window.setHeight(height)
    snapshot(mode+"-"+name)
   call(window,"setLight",True)
   snapshot(mode+"-light")
   call(window,"setLight",False)
  if warnings:
   print("\n".join(warnings));app.exit(1);return
  print("PASS: settings callback (Core owns gear), mode drafts and reload, city edits, home fallback, invalid IDs, both modes at Core content sizes, dark/light rendering")
  app.exit(0)
 QTimer.singleShot(300,check);sys.exit(app.exec())
