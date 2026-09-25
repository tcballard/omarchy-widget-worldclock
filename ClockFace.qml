import QtQuick
import qs.Commons

Canvas {
    id: face
    property bool solar: false
    property var row: ({time: "12:00", day: true})
    property var rows: []
    property var colors: [Color.accent, "#40c8e0", "#8b82e8", "#70cb86", "#ef819a"]
    property bool dark: false
    onRowChanged: requestPaint()
    onRowsChanged: requestPaint()
    onDarkChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    function parts(value) { var p = (value || "12:00").split(":"); return [Number(p[0]) || 0, Number(p[1]) || 0]; }
    function line(ctx,x,y,a,b,color,w) { ctx.beginPath();ctx.moveTo(x,y);ctx.lineTo(a,b);ctx.strokeStyle=color;ctx.lineWidth=w;ctx.lineCap="round";ctx.stroke(); }
    onPaint: {
        var ctx=getContext("2d"), d=Math.min(width,height), r=d/2;
        ctx.reset();ctx.save();ctx.translate((width-d)/2,(height-d)/2);
        ctx.beginPath();ctx.arc(r,r,r-1,0,Math.PI*2);
        ctx.fillStyle=solar ? Color.background : (row.day ? Qt.lighter(Color.background,1.28) : Qt.darker(Color.background,1.4));ctx.fill();
        ctx.strokeStyle=Color.muted;ctx.lineWidth=0.7;ctx.stroke();
        if(solar) {
            ctx.beginPath();ctx.arc(r,r,r-2,0,Math.PI);ctx.lineTo(r,r);ctx.closePath();ctx.fillStyle="rgba(100,110,120,0.14)";ctx.fill();
            for(var i=0;i<24;i++) { var a=(i/24+0.5)*Math.PI*2, major=i%6===0, edge=r-d*.035;
                line(ctx,r+Math.sin(a)*edge,r-Math.cos(a)*edge,r+Math.sin(a)*(edge-d*(major?.065:.03)),r-Math.cos(a)*(edge-d*(major?.065:.03)),Color.muted,major?1.5:.75);
            }
            ctx.fillStyle=Color.muted;ctx.font="10px sans-serif";ctx.textAlign="center";ctx.textBaseline="middle";
            [["12",0],["18",.5],["00",1],["06",1.5]].forEach(function(v){var a=v[1]*Math.PI;ctx.fillText(v[0],r+Math.sin(a)*d*.36,r-Math.cos(a)*d*.36);});
            var taken=[];
            for(var j=Math.min(rows.length,5)-1;j>=0;j--) {
                var p=parts(rows[j].time), theta=((p[0]+p[1]/60)/24+.5)*Math.PI*2;
                var count=0;
                for(var q=0;q<Math.min(rows.length,5);q++) {
                    var other=parts(rows[q].time), oa=((other[0]+other[1]/60)/24+.5)*Math.PI*2;
                    if(q!==j && Math.abs(Math.atan2(Math.sin(oa-theta),Math.cos(oa-theta)))<Math.PI/24) count++;
                }
                if(taken.some(function(t){return Math.abs(Math.atan2(Math.sin(t-theta),Math.cos(t-theta)))<Math.PI/24;}))continue;
                taken.push(theta);var x=r+Math.sin(theta)*d*.39,y=r-Math.cos(theta)*d*.39;
                line(ctx,r,r,x,y,colors[j],2.2);ctx.beginPath();ctx.arc(x,y,Math.max(3,d*.025),0,Math.PI*2);ctx.fillStyle=colors[j];ctx.fill();
                if(count && !rows.slice(0,j).some(function(other){var p=parts(other.time),a=((p[0]+p[1]/60)/24+.5)*Math.PI*2;return Math.abs(Math.atan2(Math.sin(a-theta),Math.cos(a-theta)))<Math.PI/24;})) {
                    ctx.font="bold 10px sans-serif";ctx.textAlign="left";ctx.fillStyle=Color.foreground;ctx.fillText("+"+count,x+6,y-6);
                }
            }
            ctx.beginPath();ctx.arc(r,r,3,0,Math.PI*2);ctx.fillStyle=Color.foreground;ctx.fill();
        } else {
            var ink=row.day?Color.foreground:"#f5f5f7";
            for(var k=0;k<12;k++){var angle=k*Math.PI/6,edge12=r-5,len=(k%3===0?.16:.08)*r;
                line(ctx,r+Math.sin(angle)*edge12,r-Math.cos(angle)*edge12,r+Math.sin(angle)*(edge12-len),r-Math.cos(angle)*(edge12-len),ink,k%3===0?1.8:1);
            }
            var t=parts(row.time),ha=(t[0]%12+t[1]/60)*Math.PI/6,ma=t[1]*Math.PI/30;
            line(ctx,r,r,r+Math.sin(ha)*r*.5,r-Math.cos(ha)*r*.5,ink,d>=100?4:2.6);
            line(ctx,r,r,r+Math.sin(ma)*r*.75,r-Math.cos(ma)*r*.75,ink,d>=100?2.6:1.8);
            ctx.beginPath();ctx.arc(r,r,d>=100?3.5:2.5,0,Math.PI*2);ctx.fillStyle=Color.accent;ctx.fill();
        }
        ctx.restore();
    }
}
