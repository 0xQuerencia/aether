import QtQuick

Canvas {
    id: chart
    property var values: []
    property color lineColor: "white"
    property bool filled: true
    property real strokeWidth: 2

    onPaint: {
        const ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        if (width <= 1 || height <= 1 || !values || values.length < 2) return;
        const points = [];
        for (const item of values) {
            const number = Number(item);
            if (item !== null && item !== undefined && Number.isFinite(number)) points.push(number);
        }
        if (points.length < 2) return;
        let low = Math.min(0, ...points);
        let high = Math.max(...points);
        if (high <= low) high = low + 1;
        const pad = strokeWidth;
        const xAt = i => pad + i * (width - pad * 2) / (points.length - 1);
        const yAt = value => height - pad - (value - low) * (height - pad * 2) / (high - low);

        ctx.beginPath();
        ctx.moveTo(xAt(0), yAt(points[0]));
        for (let i = 1; i < points.length; ++i) ctx.lineTo(xAt(i), yAt(points[i]));
        if (filled) {
            ctx.lineTo(xAt(points.length - 1), height);
            ctx.lineTo(xAt(0), height);
            ctx.closePath();
            ctx.fillStyle = Qt.rgba(lineColor.r, lineColor.g, lineColor.b, 0.14).toString();
            ctx.fill();
            ctx.beginPath();
            ctx.moveTo(xAt(0), yAt(points[0]));
            for (let i = 1; i < points.length; ++i) ctx.lineTo(xAt(i), yAt(points[i]));
        }
        ctx.strokeStyle = lineColor.toString();
        ctx.lineWidth = strokeWidth;
        ctx.lineJoin = "round";
        ctx.lineCap = "round";
        ctx.stroke();
    }
    onValuesChanged: requestPaint()
    onLineColorChanged: requestPaint()
    onFilledChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
}
