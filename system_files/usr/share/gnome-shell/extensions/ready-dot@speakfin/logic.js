// Pure logic for the ready dot, with no GNOME imports so it can be tested alone.
//
// States: hidden (waiting for the wake word or asleep), ready (listening for a
// command, no wake word needed) and busy (chime, thinking, or speaking a reply).
// It also notices when EasySpeak did not understand a command, so the extension
// can offer the closest real commands.

export const HIDDEN = 'hidden';
export const READY = 'ready';
export const BUSY = 'busy';

const CHIME_MS = 700;        // wake chime plays before it listens
const HEARD_MS = 500;        // a command was heard and is being carried out
const SPEAK_BASE_MS = 600;   // spoken replies: fixed part ...
const SPEAK_WORD_MS = 380;   // ... plus time per word
const CPU_BUSY_PERCENT = 100; // speech recognition shows as a CPU burst
const CPU_HOLD_MS = 400;     // keep the busy colour long enough to be seen
const MISS_WINDOW_MS = 4000; // "didn't understand" must follow the heard text this closely

const NOT_UNDERSTOOD = /didn.t understand/i;

// Turns one line of EasySpeak's log into an event, or null if it is irrelevant.
export function parseEvent(message) {
    if (message.includes('Wake! (confidence'))
        return {type: 'wake'};
    if (message.includes('Hotkey dictation'))
        return {type: 'hotkey'};
    if (message.includes('Listening for wake word') ||
        message.includes('Muted; microphone released'))
        return {type: 'idle'};
    const speak = message.indexOf('\u{1F4AC} ');
    if (speak !== -1) {
        const text = message.slice(speak + 3).trim();
        return {type: 'speak', text, words: text ? text.split(/\s+/).length : 0};
    }
    const heard = message.indexOf('\u{1F442} ');
    if (heard !== -1)
        return {type: 'heard', text: message.slice(heard + 3).trim()};
    return null;
}

// True when what EasySpeak heard was a request for its command list: "help", "help me",
// "please help". Longer sentences that merely contain the word do not count.
export function isHelpRequest(text) {
    const words = text.toLowerCase().replace(/[^a-z\s]/g, ' ').split(/\s+/).filter(Boolean);
    return words.length > 0 && words.length <= 3 && words.includes('help') &&
        words.every(w => ['help', 'me', 'please', 'hey', 'jarvis', 'now'].includes(w));
}

// utime + stime (clock ticks) from the text of /proc/<pid>/stat.
export function parseStatTicks(stat) {
    const rest = stat.slice(stat.lastIndexOf(')') + 2).split(' ');
    return Number(rest[11]) + Number(rest[12]);
}

// CPU use in percent of one core (100 clock ticks per second).
export function cpuPercent(prevTicks, ticks, dtMs) {
    return ((ticks - prevTicks) / 100) / (dtMs / 1000) * 100;
}

export class ReadyTracker {
    constructor() {
        this.inSession = false;
        this.busyUntil = 0;
        this.lastHeard = null;   // {text, at}
        this.miss = null;        // text that was heard but not understood
    }

    event(ev, now) {
        switch (ev.type) {
        case 'wake':
        case 'hotkey':
            this.inSession = true;
            this.busyUntil = now + CHIME_MS;
            this.lastHeard = null;
            break;
        case 'heard':
            this.busyUntil = Math.max(this.busyUntil, now + HEARD_MS);
            this.lastHeard = {text: ev.text, at: now};
            break;
        case 'speak':
            this.busyUntil = Math.max(this.busyUntil,
                now + SPEAK_BASE_MS + SPEAK_WORD_MS * ev.words);
            if (NOT_UNDERSTOOD.test(ev.text) && this.lastHeard &&
                now - this.lastHeard.at <= MISS_WINDOW_MS) {
                this.miss = this.lastHeard.text;
                this.lastHeard = null;
            }
            break;
        case 'idle':
            this.inSession = false;
            this.busyUntil = 0;
            this.lastHeard = null;
            break;
        }
    }

    // The text EasySpeak did not understand, once; null if there is none.
    takeMiss() {
        const m = this.miss;
        this.miss = null;
        return m;
    }

    cpu(percent, now) {
        if (this.inSession && percent >= CPU_BUSY_PERCENT)
            this.busyUntil = Math.max(this.busyUntil, now + CPU_HOLD_MS);
    }

    state(now) {
        if (!this.inSession)
            return HIDDEN;
        return now < this.busyUntil ? BUSY : READY;
    }
}
