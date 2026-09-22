var catalog=["Europe/London","Europe/Amsterdam","Europe/Paris","Europe/Berlin","Europe/Zurich","Europe/Dublin","Europe/Madrid","Europe/Rome","Europe/Stockholm","Europe/Warsaw","Europe/Helsinki","Europe/Athens","Europe/Istanbul","America/New_York","America/Chicago","America/Denver","America/Los_Angeles","America/Toronto","America/Vancouver","America/Sao_Paulo","America/Mexico_City","Asia/Tokyo","Asia/Hong_Kong","Asia/Singapore","Asia/Shanghai","Asia/Seoul","Asia/Kolkata","Asia/Kathmandu","Asia/Dubai","Asia/Bangkok","Asia/Taipei","Australia/Sydney","Australia/Melbourne","Australia/Perth","Australia/Adelaide","Pacific/Auckland","Pacific/Honolulu","Africa/Johannesburg","Africa/Cairo","UTC"];
function cities(settings) {
    if (!settings || !Array.isArray(settings.cities)) return [];
    return settings.cities.slice(0,12).map(function(c) {
        if (typeof c === "string") return {label:c.split("/").pop().replace(/_/g," "),zone:c};
        return {label:c && typeof c.label === "string" ? c.label.slice(0,48) : "Unknown city",
                zone:c && typeof c.zone === "string" && c.zone.length <= 100 ? c.zone : "INVALID"};
    });
}
function rows(text, entries, today) {
    var lines=text.trim().split("\n");
    if (lines.length !== entries.length) throw new Error("Incomplete time sample");
    var result=entries.map(function(city,i) {
        var p=lines[i].split("|");
        if(p.length!==5 || !/^\d\d:\d\d$/.test(p[0]) || !/^[+-]\d\d:\d\d$/.test(p[2]) || !/^\d{4}-\d\d-\d\d$/.test(p[4]))
            return {label:city.label,zone:city.zone,time:"—",date:"Unknown timezone",offset:"",day:false,relative:"",localDate:"",valid:false};
        var delta=Math.round((Date.parse(p[4]+"T00:00:00Z")-Date.parse(today+"T00:00:00Z"))/86400000);
        return {label:city.label,zone:city.zone,time:p[0],date:p[1],offset:"UTC"+p[2],day:Number(p[3])>=7&&Number(p[3])<19,relative:delta?(delta>0?"+":"−")+Math.abs(delta)+" day"+(Math.abs(delta)>1?"s":""):"",localDate:p[4],valid:true};
    });
    var home=result[0];
    function minutes(offset) { var m=/^UTC([+-])(\d\d):(\d\d)$/.exec(offset); return m ? (m[1]==="-"?-1:1)*(Number(m[2])*60+Number(m[3])) : 0; }
    return result.map(function(row,i) {
        if(!row.valid || !home.valid) return Object.assign({},row,{homeOffset:"",homeRelative:""});
        var d=Math.round((Date.parse(row.localDate+"T00:00:00Z")-Date.parse(home.localDate+"T00:00:00Z"))/86400000);
        var diff=minutes(row.offset)-minutes(home.offset), a=Math.abs(diff);
        return Object.assign({},row,{homeRelative:d===0?"Today":d===1?"Tomorrow":d===-1?"Yesterday":(d>0?"+":"−")+Math.abs(d)+" days",
            homeOffset:i===0?"Home":(diff<0?"−":"+")+Math.floor(a/60)+(a%60?":"+String(a%60).padStart(2,"0"):"")+"h"});
    });
}
if (typeof module !== "undefined") module.exports={cities:cities,rows:rows};
