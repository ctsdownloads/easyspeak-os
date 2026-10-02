// Pure layout for the on-screen "help" list, with no GNOME imports so it can be tested.
// Given the sections (title + words to say) and the room on screen, it picks the largest
// text size that fits, and spreads the sections over columns of similar height.

const CHAR_EM = 0.6;      // average character width as a share of the font size (a bit generous)
const LINE_EM = 1.38;     // line height as a share of the font size
const HEAD_GAP_EM = 0.7;  // gap after each section
const PAD_EM = 1.1;       // padding inside the whole panel
const COL_GAP_EM = 1.8;   // gap between columns
const MIN_PX = 12;
const MAX_PX = 22;

function blockRows(section) {
    return section.say.length + 1;   // the heading counts as a row
}

function blockChars(section) {
    return Math.max(section.title.length + 2, ...section.say.map(s => s.length + 2));
}

// Split the sections, kept in their given order (everyday commands first), into `cols`
// side-by-side columns so the tallest column is as short as it can be.
function distribute(sections, cols) {
    const rows = sections.map(s => blockRows(s) + HEAD_GAP_EM / LINE_EM);
    const n = sections.length;
    cols = Math.min(cols, n);
    let best = null;
    // try every way of cutting the list into `cols` consecutive groups
    const cut = (start, left, groups) => {
        if (left === 1) {
            const all = [...groups, [start, n]];
            const tallest = Math.max(...all.map(([a, b]) => rows.slice(a, b).reduce((x, y) => x + y, 0)));
            if (!best || tallest < best.tallest - 1e-9)
                best = {tallest, groups: all};
            return;
        }
        for (let end = start + 1; end <= n - (left - 1); end++)
            cut(end, left - 1, [...groups, [start, end]]);
    };
    cut(0, cols, []);
    return best.groups.map(([a, b]) => {
        const blocks = [...Array(b - a).keys()].map(k => a + k);
        return {
            rows: rows.slice(a, b).reduce((x, y) => x + y, 0),
            chars: Math.max(...blocks.map(k => blockChars(sections[k]))),
            blocks,
        };
    });
}

export function planHelp(sections, availW, availH) {
    let best = null;
    for (let fs = MAX_PX; fs >= MIN_PX; fs--) {
        for (let cols = 1; cols <= 6; cols++) {
            const columns = distribute(sections, cols);
            const height = Math.max(...columns.map(c => c.rows)) * fs * LINE_EM + 2 * PAD_EM * fs;
            const width = columns.reduce((w, c) => w + c.chars * fs * CHAR_EM, 0) +
                (columns.length - 1) * COL_GAP_EM * fs + 2 * PAD_EM * fs;
            if (width <= availW && height <= availH) {
                // prefer the biggest text; at the same size, the fewest columns
                if (!best || fs > best.fontPx || (fs === best.fontPx && columns.length < best.columns.length))
                    best = {fontPx: fs, columns, width, height};
            }
        }
        if (best)
            break;
    }
    if (!best) {
        const columns = distribute(sections, 6);
        best = {fontPx: MIN_PX, columns, width: availW, height: availH, clipped: true};
    }
    return {
        fontPx: best.fontPx,
        clipped: !!best.clipped,
        width: Math.round(best.width),
        height: Math.round(best.height),
        columns: best.columns.map(c => ({blocks: c.blocks, chars: c.chars})),
        lineHeightPx: Math.round(best.fontPx * LINE_EM),
        gapPx: Math.round(best.fontPx * COL_GAP_EM),
        padPx: Math.round(best.fontPx * PAD_EM),
        headGapPx: Math.round(best.fontPx * HEAD_GAP_EM),
        charPx: best.fontPx * CHAR_EM,
    };
}
