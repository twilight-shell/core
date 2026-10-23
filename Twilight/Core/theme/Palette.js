.pragma library

// Palette math: the Twilight palette, the other ponies' presets and the
// functions that build a palette from hues. No state, so the theme stays a
// plain list of properties.

const twilight = {
    bg: "#14101f",
    surface: "#1e1830",
    surfaceHigh: "#2a2142",
    border: "#3a2f58",
    text: "#ede4ff",
    muted: "#9a8cb8",
    primary: "#c9a0f0",
    accent: "#ec4f9a",
    secondary: "#5a5fc7",
    star: "#ff8fc7",
    ink: "#0a0713",
    shadow: "#06040b"
};

// Hues (0..1) for build(): background, primary, accent, secondary.
const presets = {
    luna: { name: "Luna", hues: [0.64, 0.6, 0.72, 0.55] },
    rarity: { name: "Rarity", hues: [0.74, 0.7, 0.78, 0.55] },
    pinkie: { name: "Pinkie", hues: [0.93, 0.91, 0.96, 0.52] },
    celestia: { name: "Celestia", hues: [0.86, 0.13, 0.94, 0.47] },
    fluttershy: { name: "Fluttershy", hues: [0.36, 0.15, 0.93, 0.42] },
    rainbow: { name: "Rainbow", hues: [0.6, 0.55, 0.0, 0.33] }
};

function fromPreset(preset) {
    const h = preset.hues;
    return build({ h: h[0], s: 0.45 }, { h: h[1], s: 0.7 }, { h: h[2], s: 0.8 }, { h: h[3], s: 0.55 });
}

function clamp(v, lo, hi) {
    return Math.max(lo, Math.min(hi, v));
}

function hueDistance(a, b) {
    const d = Math.abs(a - b);
    return Math.min(d, 1 - d);
}

// Picks hues from the wallpaper and rebuilds the palette around them:
// the most vivid color becomes the accent, a second distinct vivid hue
// the primary, and the hue of the darkest tinted color the background.
function derive(colors) {
    const all = colors.map(c => ({ h: c.hslHue, s: c.hslSaturation, l: c.hslLightness }))
        .filter(c => c.h >= 0);
    if (all.length === 0)
        return twilight;

    const vivid = all.slice().sort((a, b) => b.s * (1 - Math.abs(b.l - 0.55)) - a.s * (1 - Math.abs(a.l - 0.55)));
    const accent = vivid[0];
    const primary = vivid.find(c => hueDistance(c.h, accent.h) > 0.06 && c.s > 0.2)
        ?? { h: (accent.h + 0.08) % 1, s: accent.s, l: accent.l };
    const tinted = all.filter(c => c.s > 0.12).sort((a, b) => a.l - b.l);
    const base = tinted[0] ?? accent;
    const secondary = vivid.find(c => hueDistance(c.h, accent.h) > 0.1 && hueDistance(c.h, primary.h) > 0.06)
        ?? { h: (base.h + 0.04) % 1, s: 0.5, l: 0.5 };

    return build(base, primary, accent, secondary);
}

// A dark palette from four hues ({h, s}, 0..1): background tint,
// primary (light), accent (vivid) and secondary (mid).
function build(base, primary, accent, secondary) {
    const bh = base.h;
    const bs = clamp(base.s, 0.25, 0.5);
    return {
        bg: Qt.hsla(bh, bs, 0.07, 1),
        surface: Qt.hsla(bh, bs * 0.8, 0.12, 1),
        surfaceHigh: Qt.hsla(bh, bs * 0.8, 0.18, 1),
        border: Qt.hsla(bh, bs * 0.7, 0.26, 1),
        text: Qt.hsla(primary.h, 0.6, 0.93, 1),
        muted: Qt.hsla(primary.h, 0.22, 0.64, 1),
        primary: Qt.hsla(primary.h, clamp(primary.s, 0.45, 0.8), 0.76, 1),
        accent: Qt.hsla(accent.h, clamp(accent.s, 0.6, 0.85), 0.6, 1),
        secondary: Qt.hsla(secondary.h, clamp(secondary.s, 0.4, 0.6), 0.52, 1),
        star: Qt.hsla(accent.h, 0.9, 0.78, 1),
        ink: Qt.hsla(bh, 0.4, 0.04, 1),
        shadow: Qt.hsla(bh, 0.4, 0.025, 1)
    };
}
