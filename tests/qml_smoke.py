import os,sys,tempfile,json,subprocess
from pathlib import Path
os.environ.setdefault("QT_QPA_PLATFORM","offscreen")
from PySide6.QtCore import QUrl,QTimer,QObject,QMetaObject,Q_ARG
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
 width:580;height:408;visible:true;color:Color.background
 QtObject {
  id:context;objectName:"context";property var settings:'''+json.dumps(fixture)+''';property bool active:false;property string sizeName:"wide"
  property var appearance:({fontFamily:"DejaVu Sans"});property bool saving:false;property string saveError:"";property bool inputRequested:false
  property var submitted:null
  function requestInput(value) { inputRequested=value; }
  function saveSettings(value) { if(saving)return false;submitted=value;return true; }
 }
 Widget.WorldClock {
  id:clock;objectName:"clock";anchors.fill:parent;widgetContext:context
  Component.onCompleted: rows=Model.rows("12:30|Tue 15 Sep|+01:00|12|2026-09-15\\n07:30|Tue 15 Sep|-04:00|07|2026-09-15\\n06:30|Tue 15 Sep|-05:00|06|2026-09-15\\n13:30|Tue 15 Sep|+02:00|13|2026-09-15\\n20:30|Tue 15 Sep|+09:00|20|2026-09-15\\n21:30|Tue 15 Sep|+10:00|21|2026-09-15",cities,"2026-09-15")
 }
}
''')
 app=QGuiApplication([]);engine=QQmlApplicationEngine();engine.addImportPath(tmp)
 warnings=[];engine.warnings.connect(lambda es:warnings.extend(e.toString() for e in es))
 engine.load(QUrl.fromLocalFile(str(preview)))
 assert engine.rootObjects(),"Could not load widget"
 def check():
  window=engine.rootObjects()[0]
  clock=window.findChild(QObject,"clock")
  editor=window.findChild(QObject,"city-editor")
  context=window.findChild(QObject,"context")
  def call(obj,name,*args):
   assert QMetaObject.invokeMethod(obj,name,*[Q_ARG("QVariant",a) for a in args])
  def draft():return editor.property("draft").toVariant()
  call(clock,"editCities")
  assert context.property("inputRequested")
  assert len(draft())==6
  call(editor,"add","Europe/Paris")
  assert len(draft())==7
  call(editor,"move",6,-1)
  assert draft()[5]["zone"]=="Europe/Paris"
  call(editor,"removeAt",0)
  assert len(draft())==6
  call(editor,"add","../bad")
  assert len(draft())==6 and editor.property("message")
  context.setProperty("saving",True)
  call(clock,"saveCities",draft())
  assert "busy" in editor.property("message")
  context.setProperty("saving",False)
  call(clock,"saveCities",draft())
  assert context.property("submitted").toVariant()["cities"][4]["zone"]=="Europe/Paris"
  call(clock,"closeEditor")
  assert not context.property("inputRequested")
  call(clock,"editCities")
  assert draft()[0]["zone"]=="Europe/London", "Cancel must discard the draft"
  out=root/"test-results";out.mkdir(exist_ok=True)
  app.processEvents()
  assert window.grabWindow().save(str(out/"editor.png"))
  call(clock,"closeEditor")
  app.processEvents()
  if warnings:
   print("\n".join(warnings));app.exit(1);return
  out=root/"test-results";out.mkdir(exist_ok=True)
  assert engine.rootObjects()[0].grabWindow().save(str(out/"worldclock.png"))
  print("PASS: native rows, editor add/remove/reorder, invalid ID, busy save, submitted settings, cancel and keyboard ownership")
  app.exit(0)
 QTimer.singleShot(300,check);sys.exit(app.exec())
