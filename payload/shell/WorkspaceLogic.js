.pragma library

function build(count, spaces, activeId) {
    const byId = {}, ids = [];
    count = Math.max(1, Math.min(64, Number(count) || 8));
    for (let id = 1; id <= count; id++) ids.push(id);
    for (let space of spaces) {
        if (space.id <= 0) continue;
        byId[space.id] = space;
        if (ids.indexOf(space.id) === -1) ids.push(space.id);
    }
    if (activeId > 0 && ids.indexOf(activeId) === -1) ids.push(activeId);
    ids.sort((a, b) => a - b);
    return ids.map(id => ({wsId: String(id), wsState: id === activeId ? "active" : byId[id] && byId[id].occupied ? "occupied" : "empty"}));
}
