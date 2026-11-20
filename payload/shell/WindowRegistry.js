.pragma library

function getScale(mw, mh, userScale) {
    if (arguments.length === 2) {
        userScale = mh;
        mh = mw * (1080.0 / 1920.0);
    }

    const width = Number(mw), height = Number(mh);
    if (!Number.isFinite(width) || !Number.isFinite(height) || width <= 0 || height <= 0)
        return 1.0;

    const requested = Number(userScale);
    const safeScale = userScale == null || !Number.isFinite(requested)
        ? 1.0 : Math.max(0.8, Math.min(1.4, requested));
    let rw = width / 1920.0;
    let rh = height / 1080.0;
    let r = Math.min(rw, rh);
    
    let baseScale = 1.0;
    
    if (r <= 1.0) {
        baseScale = Math.max(0.35, Math.pow(r, 0.85));
    } else {
        baseScale = Math.pow(r, 0.5);
    }
    
    return baseScale * safeScale;
}

function s(val, scale) {
    return Math.round(val * scale);
}
