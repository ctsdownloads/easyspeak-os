// Pure logic for the ready dot, with no GNOME imports so it can be tested alone.
//
// States: hidden (waiting for the wake word or asleep), ready (listening for a
// command, no wake word needed) and busy (chime, thinking, or speaking a reply).

export const HIDDEN = 'hidden';
export const READY = 'ready';
export const BUSY = 'busy';

const CHIME_MS = 700;        // wake chime plays before it listens
const HEARD_MS = 500;        // a command was heard and is being carried out
const SPEAK_BASE_MS = 600;   // spoken replies: fixed part ...
const SPEAK_WORD_MS = 380;   // ... plus time per word
const CPU_BUSY_PERCENT = 100; // speech recognition shows as a CPU burst
const CPU_HOLD_MS = 400;     // keep the busy colour long enough to be seen

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
        return {type: 'speak', words: text ? text.split(/\s+/).length : 0};
    }
    if (message.includes('\u{1F442} '))
        return {type: 'heard'};
    return null;
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
    }

    event(ev, now) {
        switch (ev.type) {
        case 'wake':
        case 'hotkey':
            this.inSession = true;
            this.busyUntil = now + CHIME_MS;
            break;
        case 'heard':
            this.busyUntil = Math.max(this.busyUntil, now + HEARD_MS);
            break;
        case 'speak':
            this.busyUntil = Math.max(this.busyUntil,
                now + SPEAK_BASE_MS + SPEAK_WORD_MS * ev.words);
            break;
        case 'idle':
            this.inSession = false;
            this.busyUntil = 0;
            break;
        }
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
