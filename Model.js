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
    return entries.map(function(city,i) {
        var p=lines[i].split("|");
        if(p.length!==5 || !/^\d\d:\d\d$/.test(p[0]) || !/^[+-]\d\d:\d\d$/.test(p[2]) || !/^\d{4}-\d\d-\d\d$/.test(p[4]))
            return {label:city.label,zone:city.zone,time:"—",date:"Unknown timezone",offset:"",day:false,relative:"",valid:false};
        var delta=Math.round((Date.parse(p[4]+"T00:00:00Z")-Date.parse(today+"T00:00:00Z"))/86400000);
        return {label:city.label,zone:city.zone,time:p[0],date:p[1],isoDate:p[4],offset:"UTC"+p[2],day:Number(p[3])>=7&&Number(p[3])<19,relative:delta?(delta>0?"+":"−")+Math.abs(delta)+" day"+(Math.abs(delta)>1?"s":""):"",valid:true};
    });
}
if (typeof module !== "undefined") module.exports={cities:cities,rows:rows};


function minuteOfDay(row) {
    if (!row || !row.valid) return 0;
    var p=row.time.split(":"); return Number(p[0])*60+Number(p[1]);
}
function offsetMinutes(row) {
    var p=/^UTC([+-])(\d{2}):(\d{2})$/.exec(row.offset);
    return p ? (p[1]==="-"?-1:1)*(Number(p[2])*60+Number(p[3])) : 0;
}
function homeOffset(row, home) {
    if (!row || !row.valid || !home || !home.valid) return "";
    var delta=offsetMinutes(row)-offsetMinutes(home), minutes=Math.abs(delta);
    return (delta<0?"−":delta>0?"+":"") + Math.floor(minutes/60) + (minutes%60 ? ":"+String(minutes%60).padStart(2,"0") : "") + "h";
}
function homeDay(row, home) {
    if (!row || !row.valid || !home || !home.valid) return "";
    var delta=Math.round((Date.parse(row.isoDate+"T00:00:00Z")-Date.parse(home.isoDate+"T00:00:00Z"))/86400000);
    return delta ? (delta>0?"+":"−")+Math.abs(delta)+" day"+(Math.abs(delta)>1?"s":"") : "";
}
if (typeof module !== "undefined") Object.assign(module.exports,{minuteOfDay:minuteOfDay,homeOffset:homeOffset,homeDay:homeDay});
