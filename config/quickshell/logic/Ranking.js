// A match's quality always beats habit; habit breaks ties between good matches.
function match(app, query) {
    var words = query.toLowerCase().trim().split(/\s+/).filter(Boolean);
    var name = app.name.toLowerCase();
    var extra = ((app.genericName || "") + " " + (app.keywords || []).join(" ")).toLowerCase();
    if (!words.every(word => (name + " " + extra).includes(word))) return -1;
    if (!words.length) return 0;
    var phrase = words.join(" ");
    if (name === phrase) return 4;
    if (name.startsWith(phrase)) return 3;
    if (words.every(word => name.split(/\W+/).some(part => part.startsWith(word)))) return 2;
    return words.every(word => name.includes(word)) ? 1 : 0;
}

function habit(entry, now) {
    if (!entry) return 0;
    var days = Math.max(0, now - entry.last) / 86400000;
    return Math.log2(1 + Math.max(0, entry.count)) * Math.exp(-days / 60)
        + 4 * Math.exp(-days / 3);
}

function rank(apps, query, usage, now) {
    return apps.filter(app => !app.noDisplay).map(app => ({app: app,
        match: match(app, query), habit: habit(usage[app.id], now), last: (usage[app.id] || {}).last || 0
    })).filter(item => item.match >= 0).sort((a, b) => b.match - a.match
        || b.habit - a.habit || b.last - a.last || a.app.name.localeCompare(b.app.name))
        .map(item => item.app);
}

if (typeof module !== "undefined") module.exports = {match, habit, rank};
