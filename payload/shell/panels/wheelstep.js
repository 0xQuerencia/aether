.pragma library

function createState() {
    return {
        accumulator: 0,
        direction: 0,
        lastInputAt: null,
        lastStepAt: null,
        mode: ""
    };
}

function clear(state) {
    return {
        accumulator: 0,
        direction: 0,
        lastInputAt: null,
        lastStepAt: state && state.lastStepAt !== undefined ? state.lastStepAt : null,
        mode: ""
    };
}

function selectDelta(pixelX, pixelY, angleX, angleY) {
    var hasPixels = pixelX !== 0 || pixelY !== 0;
    var x = hasPixels ? pixelX : angleX;
    var y = hasPixels ? pixelY : angleY;
    var mode = hasPixels ? "pixel" : ((angleX !== 0 || angleY !== 0) ? "angle" : "");

    if (mode === "")
        return { delta: 0, mode: "" };

    if (Math.abs(y) >= Math.abs(x))
        return { delta: -y, mode: mode };
    return { delta: x, mode: mode };
}

function copyState(state) {
    return {
        accumulator: state && isFinite(state.accumulator) ? state.accumulator : 0,
        direction: state && isFinite(state.direction) ? state.direction : 0,
        lastInputAt: state && state.lastInputAt !== undefined ? state.lastInputAt : null,
        lastStepAt: state && state.lastStepAt !== undefined ? state.lastStepAt : null,
        mode: state && state.mode ? state.mode : ""
    };
}

function clearIfIdle(state, now, idleMs) {
    if (state.lastInputAt !== null && now - state.lastInputAt >= idleMs) {
        state.accumulator = 0;
        state.direction = 0;
        state.lastInputAt = null;
        state.mode = "";
    }
}

function takeStep(state, now, threshold, cooldownMs) {
    if (Math.abs(state.accumulator) < threshold)
        return 0;
    if (state.lastStepAt !== null && now - state.lastStepAt < cooldownMs)
        return 0;

    var direction = state.accumulator > 0 ? 1 : -1;
    state.accumulator -= direction * threshold;
    state.lastStepAt = now;
    if (Math.abs(state.accumulator) < 0.000001) {
        state.accumulator = 0;
        state.direction = 0;
    }
    return direction;
}

function advance(state, delta, mode, now, threshold, idleMs, cooldownMs, noiseFloor) {
    var next = copyState(state);
    if (!isFinite(delta) || Math.abs(delta) < noiseFloor)
        return { state: next, step: 0 };

    clearIfIdle(next, now, idleMs);
    if (next.mode !== "" && next.mode !== mode) {
        next.accumulator = 0;
        next.direction = 0;
    }

    var direction = delta > 0 ? 1 : -1;
    if (next.direction !== 0 && next.direction !== direction)
        next.accumulator = 0;

    next.direction = direction;
    next.mode = mode;
    next.accumulator += delta;
    next.lastInputAt = now;

    return { state: next, step: takeStep(next, now, threshold, cooldownMs) };
}

function drain(state, now, threshold, idleMs, cooldownMs) {
    var next = copyState(state);
    clearIfIdle(next, now, idleMs);
    return { state: next, step: takeStep(next, now, threshold, cooldownMs) };
}


function normalizeDelta(pixelX, pixelY, angleX, angleY, stepThreshold) {
    var picked = selectDelta(pixelX, pixelY, angleX, angleY);
    if (picked.mode === "")
        return { delta: 0, mode: "" };
    if (picked.mode === "angle") {
        var notch = Math.abs(angleY) >= 120 || Math.abs(angleX) >= 120;
        return { delta: notch ? picked.delta / 120 * stepThreshold : picked.delta / 8, mode: "unit" };
    }
    return { delta: picked.delta, mode: "unit" };
}

