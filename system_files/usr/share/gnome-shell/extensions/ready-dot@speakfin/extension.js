// Dot in the top bar for EasySpeak: yellow = ready for a command (no wake word
// needed), orange = busy hearing, thinking or replying, hidden = waiting for the
// wake word. It follows the session journal for EasySpeak's log lines and, while
// a session is open, watches EasySpeak's CPU use to catch it thinking.
// When EasySpeak says it did not understand, a small card under the top bar offers
// the closest real commands.

import Clutter from 'gi://Clutter';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import GObject from 'gi://GObject';
import St from 'gi://St';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as PanelMenu from 'resource:///org/gnome/shell/ui/panelMenu.js';
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';
import {BUSY, HIDDEN, ReadyTracker, cpuPercent, parseEvent, parseStatTicks} from './logic.js';
import {suggest} from './suggest.js';

const STYLE = {
    ready: 'color: #ffd60a; font-size: 20px;',
    busy: 'color: #ff7a00; font-size: 20px;',
};
const TICK_MS = 100;
const CARD_SECONDS = 7;

// What can be said right after "Hey Jarvis", plus the words that enter a mode.
const MAIN_SECTIONS = ['General', 'Apps', 'Files', 'Media', 'System'];
const ENTRY_WORDS = ['grid', 'browser', 'notes', 'start tracking'];
const COMMAND_FILES = [
    `${GLib.get_user_data_dir()}/speakfin/commands.json`,
    '/usr/share/speakfin/commands.json',
];

const Dot = GObject.registerClass(
class ReadyDot extends PanelMenu.Button {
    _init() {
        super._init(0.0, 'Ready Dot', true);
        this.visible = false;
        this.reactive = false;
        this._label = new St.Label({
            text: '\u25CF',
            y_align: Clutter.ActorAlign.CENTER,
            style: STYLE.ready,
        });
        this.add_child(this._label);
    }

    show_state(state) {
        if (state === HIDDEN) {
            this.visible = false;
            return;
        }
        this._label.set_style(state === BUSY ? STYLE.busy : STYLE.ready);
        this.visible = true;
    }
});

const nowMs = () => GLib.get_monotonic_time() / 1000;

export default class ReadyDotExtension extends Extension {
    enable() {
        this._dot = new Dot();
        Main.panel.addToStatusArea(this.uuid, this._dot, 0, 'right');
        this._tracker = new ReadyTracker();
        this._cancellable = new Gio.Cancellable();
        this._retry = 0;
        this._tick = 0;
        this._pid = 0;
        this._prevTicks = null;
        this._prevAt = 0;
        this._phrases = null;
        this._card = null;
        this._cardTimer = 0;
        this._follow();
    }

    disable() {
        if (this._cancellable)
            this._cancellable.cancel();
        this._cancellable = null;
        if (this._retry)
            GLib.source_remove(this._retry);
        this._retry = 0;
        this._stopTicking();
        this._hideCard();
        if (this._proc)
            this._proc.force_exit();
        this._proc = null;
        this._stream = null;
        this._tracker = null;
        this._phrases = null;
        if (this._dot)
            this._dot.destroy();
        this._dot = null;
    }

    _follow() {
        try {
            this._proc = Gio.Subprocess.new(
                ['journalctl', '--user', '--follow', '--lines=0',
                    '--output=json', '--output-fields=MESSAGE,_PID'],
                Gio.SubprocessFlags.STDOUT_PIPE | Gio.SubprocessFlags.STDERR_SILENCE);
        } catch (e) {
            logError(e, 'ready-dot: could not start journalctl');
            return;
        }
        this._stream = new Gio.DataInputStream({
            base_stream: this._proc.get_stdout_pipe(),
            close_base_stream: true,
        });
        this._readLine();
    }

    _readLine() {
        const stream = this._stream;
        stream.read_line_async(GLib.PRIORITY_DEFAULT, this._cancellable, (s, res) => {
            let line;
            try {
                [line] = s.read_line_finish_utf8(res);
            } catch (e) {
                return;
            }
            if (line === null) {
                this._scheduleRestart();
                return;
            }
            this._handleLine(line);
            this._readLine();
        });
    }

    _handleLine(line) {
        let entry;
        try {
            entry = JSON.parse(line);
        } catch (e) {
            return;
        }
        if (typeof entry.MESSAGE !== 'string')
            return;
        const ev = parseEvent(entry.MESSAGE);
        if (ev === null || !this._tracker)
            return;
        const pid = Number(entry._PID);
        if (pid && pid !== this._pid) {
            this._pid = pid;
            this._prevTicks = null;
        }
        if (ev.type === 'heard' || ev.type === 'wake' || ev.type === 'hotkey' || ev.type === 'idle')
            this._hideCard();
        this._tracker.event(ev, nowMs());
        const miss = this._tracker.takeMiss();
        if (miss !== null)
            this._offerSuggestions(miss);
        this._update();
    }

    // ---- "did you mean" card ----

    _loadPhrases() {
        if (this._phrases)
            return this._phrases;
        this._phrases = [];
        for (const path of COMMAND_FILES) {
            try {
                const [ok, bytes] = GLib.file_get_contents(path);
                if (!ok)
                    continue;
                const all = JSON.parse(new TextDecoder().decode(bytes));
                this._phrases = all.filter(p =>
                    MAIN_SECTIONS.includes(p.section) || ENTRY_WORDS.includes(p.phrase));
                break;
            } catch (e) {
                // try the next location
            }
        }
        return this._phrases;
    }

    _offerSuggestions(heard) {
        const found = suggest(heard, this._loadPhrases());
        if (!found.length)
            return;
        this._hideCard();
        const box = new St.BoxLayout({
            orientation: Clutter.Orientation.VERTICAL,
            reactive: false,
            style: 'background-color: rgba(32, 32, 38, 0.96); color: #f2f2f2; ' +
                'border: 2px solid #ffd60a; border-radius: 14px; padding: 12px 20px; spacing: 4px;',
        });
        box.add_child(new St.Label({
            text: `Heard \u201C${heard.replace(/[.!?]+$/, '')}\u201D`,
            style: 'font-size: 15px; color: #bbbbbb;',
        }));
        box.add_child(new St.Label({text: 'Did you mean:', style: 'font-size: 15px;'}));
        for (const s of found) {
            box.add_child(new St.Label({
                text: `\u2022 ${s.phrase}`,
                style: 'font-size: 22px; font-weight: bold; color: #ffd60a;',
            }));
        }
        Main.uiGroup.add_child(box);
        const monitor = Main.layoutManager.primaryMonitor;
        const [, width] = box.get_preferred_width(-1);
        box.set_position(
            monitor.x + Math.floor((monitor.width - width) / 2),
            monitor.y + Main.layoutManager.panelBox.height + 12);
        this._card = box;
        this._cardTimer = GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, CARD_SECONDS, () => {
            this._cardTimer = 0;
            this._hideCard();
            return GLib.SOURCE_REMOVE;
        });
    }

    _hideCard() {
        if (this._cardTimer)
            GLib.source_remove(this._cardTimer);
        this._cardTimer = 0;
        if (this._card)
            this._card.destroy();
        this._card = null;
    }

    // ---- dot state ----

    _update() {
        if (!this._dot || !this._tracker)
            return;
        const state = this._tracker.state(nowMs());
        this._dot.show_state(state);
        if (this._tracker.inSession)
            this._startTicking();
        else
            this._stopTicking();
    }

    _startTicking() {
        if (this._tick)
            return;
        this._prevTicks = null;
        this._tick = GLib.timeout_add(GLib.PRIORITY_DEFAULT, TICK_MS, () => {
            this._onTick();
            return GLib.SOURCE_CONTINUE;
        });
    }

    _stopTicking() {
        if (this._tick)
            GLib.source_remove(this._tick);
        this._tick = 0;
        this._prevTicks = null;
    }

    _onTick() {
        if (!this._tracker)
            return;
        const now = nowMs();
        const ticks = this._readTicks();
        if (ticks !== null && this._prevTicks !== null && now > this._prevAt)
            this._tracker.cpu(cpuPercent(this._prevTicks, ticks, now - this._prevAt), now);
        this._prevTicks = ticks;
        this._prevAt = now;
        this._update();
    }

    _readTicks() {
        if (!this._pid)
            return null;
        try {
            const [ok, bytes] = GLib.file_get_contents(`/proc/${this._pid}/stat`);
            return ok ? parseStatTicks(new TextDecoder().decode(bytes)) : null;
        } catch (e) {
            return null;
        }
    }

    _scheduleRestart() {
        this._proc = null;
        this._stream = null;
        this._stopTicking();
        this._hideCard();
        if (this._tracker)
            this._tracker.event({type: 'idle'}, nowMs());
        if (this._dot)
            this._dot.show_state(HIDDEN);
        this._retry = GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, 5, () => {
            this._retry = 0;
            if (this._dot)
                this._follow();
            return GLib.SOURCE_REMOVE;
        });
    }
}
