pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications


Singleton {
    id: root

    readonly property string unusedLegacyNotifFile: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/quickshell/island/notif.json"
    property int liveRevision: 0
    property var _live: ({})
    property var _expiry: ({})
    property var _held: ({})
    function hold(id, active) {
        const key=String(id);
        if (active && !_held[key]) _held[key]=Date.now();
        else if (!active && _held[key]) {
            if (_expiry[key]) _expiry[key] += Date.now()-_held[key];
            delete _held[key];
        }
    }
    property var _order: []
    signal received(var payload)
    readonly property alias history: historyModel
    ListModel { id: historyModel }
    function addHistory(data) {
        for (let i = historyModel.count - 1; i >= 0; i--) if (historyModel.get(i).nhId === data.id) historyModel.remove(i);
        let at = historyModel.count;
        for (let i = 0; i < historyModel.count; i++) {
            if (String(historyModel.get(i).nhApp).toLocaleLowerCase() >= String(data.app).toLocaleLowerCase()) { at = i; break; }
        }
        historyModel.insert(at, {nhId:data.id,nhApp:data.app,nhSummary:data.summary,nhBody:data.body,nhIcon:data.icon,nhActions:data.actions,nhHasReply:data.hasReply,nhReplyPlaceholder:data.replyPlaceholder,nhUrgency:data.urgency,nhTs:data.ts});
        while (historyModel.count > 50) {
            let oldest = 0;
            for (let i = 1; i < historyModel.count; i++) if (historyModel.get(i).nhTs < historyModel.get(oldest).nhTs) oldest = i;
            root.dismiss(historyModel.get(oldest).nhId); historyModel.remove(oldest);
        }
    }
    Timer {
        interval: 250; repeat: true
        running: root.liveRevision >= 0 && Object.keys(root._expiry).length > 0
        onTriggered: {
            let now = Date.now();
            for (let key of Object.keys(root._expiry)) if (!root._held[key] && root._expiry[key] <= now && root._live[key]) root._live[key].expire();
        }
    }

    NotificationServer {
        id: server
        keepOnReload: false
        bodySupported: true
        bodyMarkupSupported: false
        imageSupported: true
        actionsSupported: true
        inlineReplySupported: true

        onNotification: (n) => {
            n.tracked = true;
            const key = String(n.id);
            if (root._live[key] !== n) {
                root._live[key] = n;
                
                
                const flush = function() {
                    if (root._live[key] === n) root.refreshNotification(n);
                };
                const changed = function() { Qt.callLater(flush); };
                for (let name of ["summary", "body", "actions", "appName", "appIcon", "image", "expireTimeout", "urgency", "hasInlineReply", "inlineReplyPlaceholder", "transient"]) {
                    n[name + "Changed"].connect(changed);
                }
                n.closed.connect(function(reason) {
                    if (root._live[key] === n) {
                        delete root._live[key]; delete root._expiry[key]; delete root._held[key]; root.liveRevision++;
                    }
                });
            }
            root.refreshNotification(n);
        }
    }


    function refreshNotification(n) {
        const key = String(n.id);
        if (root._live[key] !== n) return;
        let timeout = n.expireTimeout < 0 ? Prefs.p.notifSeconds : n.expireTimeout;
        if (timeout > 0) root._expiry[key] = Date.now() + timeout * 1000;
        else delete root._expiry[key];
        root._order = root._order.filter(id => id !== key).concat([key]);
        while (root._order.length > 100) { let first = root._order[0]; root._order = root._order.slice(1); if (root._live[first]) root._live[first].expire(); }
        root.liveRevision++;

        const actions = [];
        for (let i = 0; i < n.actions.length; ++i) {
            const action = n.actions[i];
            actions.push({ id: action.identifier, text: action.text });
        }
        const payload = {
            ts: Date.now(),
            id: n.id,
            app: n.appName || "",
            summary: n.summary || "",
            body: n.body || "",
            icon: n.image || n.appIcon || "",
            actions: actions,
            hasReply: n.hasInlineReply,
            replyPlaceholder: n.inlineReplyPlaceholder || "",
            urgency: n.urgency
        };
        if (!n.transient) root.addHistory(payload);
        root.received(payload);
    }

    function liveNotification(notificationId) {
        const revision = liveRevision;
        return _live[String(notificationId)] || null;
    }

    function actionsFor(notificationId) {
        const notification = liveNotification(notificationId);
        if (!notification) return [];

        const actions = [];
        for (let i = 0; i < notification.actions.length; ++i) {
            const action = notification.actions[i];
            actions.push({ id: action.identifier, text: action.text });
        }
        return actions;
    }

    function hasAction(notificationId, actionIdentifier) {
        const notification = liveNotification(notificationId);
        if (!notification) return false;
        for (let i = 0; i < notification.actions.length; ++i) {
            if (notification.actions[i].identifier === actionIdentifier) return true;
        }
        return false;
    }

    function invokeAction(notificationId, actionIdentifier) {
        const notification = liveNotification(notificationId);
        if (!notification) return false;
        for (let i = 0; i < notification.actions.length; ++i) {
            const action = notification.actions[i];
            if (action.identifier === actionIdentifier) {
                action.invoke();
                return true;
            }
        }
        return false;
    }

    function invokeDefaultAction(notificationId) {
        return invokeAction(notificationId, "default");
    }

    function reply(notificationId, text) {
        const notification = liveNotification(notificationId);
        if (!notification || !notification.hasInlineReply) return false;
        notification.sendInlineReply(text);
        return true;
    }

    function dismiss(notificationId) {
        const key = String(notificationId);
        const notification = liveNotification(key);
        if (!notification) return false;
        notification.dismiss();
        delete _live[key];
        delete _expiry[key];
        liveRevision++;
        return true;
    }

    function dismissAll() {
        const ids = Object.keys(_live);
        for (let i = 0; i < ids.length; ++i) dismiss(ids[i]);
    }
}
