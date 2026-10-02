// Closest-command suggestions for something EasySpeak heard but did not understand.
// Pure logic: no GNOME imports. Never invents a command: it only returns phrases
// from the real command list, and nothing at all when nothing is close.

export function normalize(text) {
    return text.toLowerCase().replace(/[^a-z0-9\s]/g, ' ').replace(/\s+/g, ' ').trim();
}

const FILLERS = new Set(['the', 'a', 'an', 'please', 'now', 'it', 'that', 'this', 'me', 'my', 'then', 'and', 'so',
    'folder', 'much', 'easy', 'speak', 'easyspeak']);

function withoutFillers(text) {
    const kept = text.split(' ').filter(w => !FILLERS.has(w));
    return kept.length ? kept.join(' ') : text;
}

function levenshtein(a, b) {
    const m = a.length, n = b.length;
    if (!m) return n;
    if (!n) return m;
    let prev = Array.from({length: n + 1}, (_, j) => j);
    for (let i = 1; i <= m; i++) {
        const cur = [i];
        for (let j = 1; j <= n; j++)
            cur[j] = Math.min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + (a[i - 1] === b[j - 1] ? 0 : 1));
        prev = cur;
    }
    return prev[n];
}

const sim = (a, b) => 1 - levenshtein(a, b) / Math.max(a.length, b.length, 1);

// Rough sound-alike key: collapses spellings that sound the same, so "nodes"~"notes".
function sound(w) {
    return w.replace(/ph/g, 'f').replace(/ck|c/g, 'k').replace(/[dt]/g, 't')
        .replace(/[bp]/g, 'p').replace(/[sz]/g, 's').replace(/[aeiouyw]+/g, 'a').replace(/(.)\1+/g, '$1');
}

function wordSim(a, b) {
    if (a === b) return 1;
    return Math.max(sim(a, b), 0.9 * sim(sound(a), sound(b)));
}

// Average best-match similarity of the longer phrase's words (so extra or missing words cost).
function phraseScore(heard, cand) {
    const h = heard.split(' '), c = cand.split(' ');
    const [long, short] = h.length >= c.length ? [h, c] : [c, h];
    let total = 0;
    const used = new Set();
    for (const w of short) {
        let best = 0, bi = -1;
        long.forEach((x, i) => {
            if (used.has(i)) return;
            const s = wordSim(w, x);
            if (s > best) { best = s; bi = i; }
        });
        if (bi >= 0) used.add(bi);
        total += best;
    }
    const lengthPenalty = 1 - 0.15 * (long.length - short.length);
    return (total / long.length) * Math.max(lengthPenalty, 0.5);
}

// Catches words split or joined differently: "down loads" ~ "downloads", "good buy" ~ "goodbye".
function joinedScore(heard, cand) {
    const a = heard.replace(/ /g, ''), b = cand.replace(/ /g, '');
    if (Math.min(a.length, b.length) / Math.max(a.length, b.length) < 0.7)
        return 0;                                    // very different lengths are not the same words
    return Math.max(sim(a, b), 0.95 * sim(sound(a), sound(b)));
}

export function suggest(heardText, phrases, {max = 3, min = 0.70} = {}) {
    const full = normalize(heardText);
    if (!full) return [];
    if (phrases.some(p => normalize(p.phrase) === full)) return [];   // it was a real command
    const heard = withoutFillers(full);
    if (heard.split(' ').length > 4) return [];            // long speech is conversation, not a command
    const seen = new Set();
    return phrases
        .map(p => {
            const cand = withoutFillers(normalize(p.phrase));
            const exact = cand === heard;
            return {...p, score: exact ? 1 : Math.max(phraseScore(heard, cand), joinedScore(heard, cand))};
        })
        .filter(p => p.score >= min)
        .sort((a, b) => b.score - a.score)
        .filter(p => (seen.has(p.phrase) ? false : seen.add(p.phrase)))
        .filter((p, _, all) => p.score >= all[0].score - 0.12)   // only near-ties with the best match
        .slice(0, max);
}
