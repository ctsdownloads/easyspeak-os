"""The two building blocks every installer screen uses: a numbered list, and a typed password with its strength."""
import pwquality
from gi.repository import Adw, GLib, Gtk


class NumberedList(Gtk.ScrolledWindow):
    """A list whose lines are numbered as they are said: "number three" picks line 3. A long one can be paged and
    jumped through by letter; on_scroll() is told when the lines on screen change."""

    def __init__(self, on_pick, on_scroll=None):
        super().__init__(vexpand=True, hscrollbar_policy=Gtk.PolicyType.NEVER)
        self.on_pick = on_pick
        self.titles = []
        self.rows = []
        self.picked = None
        self.box = Gtk.ListBox(selection_mode=Gtk.SelectionMode.NONE, css_classes=["boxed-list"],
                               valign=Gtk.Align.START, margin_bottom=6)
        self.box.connect("row-activated", lambda _b, row: self.select(row.get_index()))
        self.set_child(self.box)
        if on_scroll:
            self.get_vadjustment().connect("value-changed", lambda *_: on_scroll())

    def select(self, i):
        """Pick line i, clicked or said; a line said while off screen is scrolled into view afterwards."""
        self.picked = i
        self.on_pick(i)

    def first_shown(self):
        """The index of the first line on screen."""
        top = self.get_vadjustment().get_value()
        for i in range(len(self.titles)):
            ok, bounds = self.box.get_row_at_index(i).compute_bounds(self.box)
            if ok and bounds.get_y() + bounds.get_height() > top + 1:
                return i
        return 0

    def page(self, direction):
        """One screenful down (1) or up (-1), keeping the last line in view."""
        adj = self.get_vadjustment()
        adj.set_value(adj.get_value() + direction * adj.get_page_size() * 0.9)

    def jump(self, letter, start=0):
        """Scroll so the first line from start on that starts with the letter is at the top (start: where the
        alphabetical part begins, after lines pinned to the top). False when there is none."""
        i = next((n for n, t in enumerate(self.titles) if n >= start and t.lower().startswith(letter)), None)
        if i is None:
            return False
        ok, bounds = self.box.get_row_at_index(i).compute_bounds(self.box)
        if ok:
            self.get_vadjustment().set_value(bounds.get_y())
        return True

    def show_lines(self, lines, to_chosen=True):
        """lines: [(title, subtitle or "", chosen)]. Scrolls to the first chosen line, or stays where it was.
        The same lines as before are updated in place: rebuilding hundreds of rows on every pick is slow."""
        kept = self.get_vadjustment().get_value()
        titles = [title for title, _s, _c in lines]
        if titles != self.titles:
            self.box.remove_all()
            self.rows = []
            for n, title in enumerate(titles, 1):
                row = Adw.ActionRow(title=GLib.markup_escape_text(title), activatable=True)
                row.add_prefix(Gtk.Label(label=str(n), css_classes=["line-number"], valign=Gtk.Align.CENTER))
                mark = Gtk.Image(icon_name="object-select-symbolic", css_classes=["chosen-mark"])
                row.add_suffix(mark)
                self.box.append(row)
                self.rows.append((row, mark))
            self.titles = titles
        first = None
        for (row, mark), (_t, subtitle, chosen) in zip(self.rows, lines):
            row.set_subtitle(GLib.markup_escape_text(subtitle))
            mark.set_visible(chosen)
            (row.add_css_class if chosen else row.remove_css_class)("chosen")
            first = first or (row if chosen else None)
        if to_chosen and first:
            GLib.idle_add(self._scroll_to, first)
        elif not to_chosen:
            GLib.idle_add(self._keep, kept, self.picked)
        self.picked = None

    def _keep(self, kept, picked):
        """Stay where the list was, unless the line just picked is off screen."""
        adj = self.get_vadjustment()
        adj.set_value(kept)
        row = self.box.get_row_at_index(picked) if picked is not None else None
        if row:
            ok, bounds = row.compute_bounds(self.box)
            if ok and not (kept <= bounds.get_y() and bounds.get_y() + bounds.get_height() <= kept + adj.get_page_size()):
                self._scroll_to(row)
        return False

    def _scroll_to(self, row):
        ok, bounds = row.compute_bounds(self.box)
        if ok:
            adj = self.get_vadjustment()
            adj.set_value(max(0, bounds.get_y() - adj.get_page_size() / 3))
        return False


class PasswordPair(Gtk.Box):
    """A password typed twice, with a strength meter. ready() when both match and it isn't empty."""

    WORDS = ["Too weak", "Weak", "Fair", "Good", "Strong"]

    def __init__(self, what, on_change):
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        self.on_change = on_change
        rows = Gtk.ListBox(selection_mode=Gtk.SelectionMode.NONE, css_classes=["boxed-list"])
        self.first = Adw.PasswordEntryRow(title=what)
        self.second = Adw.PasswordEntryRow(title=f"{what}, again")
        for entry in (self.first, self.second):
            entry.connect("changed", self._changed)
            rows.append(entry)
        self.append(rows)
        self.meter = Gtk.LevelBar(min_value=0, max_value=4, mode=Gtk.LevelBarMode.DISCRETE)
        self.note = Gtk.Label(xalign=0, css_classes=["dim-label"], wrap=True)
        self.append(self.meter)
        self.append(self.note)
        self._show()

    def text(self):
        return self.first.get_text()

    def ready(self):
        return bool(self.text()) and self.text() == self.second.get_text()

    def focus(self):
        self.first.grab_focus()

    def strength(self):
        """0 to 4, and what is wrong with it if anything."""
        pw = self.text()
        if not pw:
            return 0, ""
        try:
            return min(4, 1 + pwquality.PWQSettings().check(pw) // 25), ""
        except pwquality.PWQError as e:
            return 0, e.args[1] if len(e.args) > 1 else ""

    def _changed(self, *_):
        self._show()
        self.on_change()

    def _show(self):
        """The meter and the note under it, for what is typed now."""
        level, problem = self.strength()
        self.meter.set_value(level)
        if not self.text():
            self.note.set_text("Type it, then type it again below.")
        elif self.second.get_text() and self.second.get_text() != self.text():
            self.note.set_text("The two don't match yet.")
        else:
            self.note.set_text(f"Strength: {self.WORDS[level]}." + (f" {problem}." if problem else ""))
