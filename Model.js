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
        return {label:city.label,zone:city.zone,time:p[0],date:p[1],offset:"UTC"+p[2],day:Number(p[3])>=7&&Number(p[3])<19,relative:delta?(delta>0?"+":"−")+Math.abs(delta)+" day"+(Math.abs(delta)>1?"s":""):"",valid:true};
    });
}
if (typeof module !== "undefined") module.exports={cities:cities,rows:rows};
