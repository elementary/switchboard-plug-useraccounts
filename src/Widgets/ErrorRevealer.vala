/*
* Copyright (c) 2018 elementary LLC. (https://elementary.io)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*/

private class SwitchboardPlugUserAccounts.ErrorRevealer : Gtk.Box {
    public Gtk.Label label_widget { get; construct; }

    public string label {
        set {
            label_widget.label = "<span font_size=\"small\">%s</span>".printf (value);
        }
    }

    public bool reveal_child { get; set; default = false; }

    public ErrorRevealer (string label) {
        this.label = label;
    }

    construct {
        label_widget = new Gtk.Label ("") {
            justify = RIGHT,
            max_width_chars = 55,
            use_markup = true,
            wrap = true,
            xalign = 1
        };

        var revealer = new Gtk.Revealer () {
            child = label_widget,
            transition_type = CROSSFADE,
            halign = END
        };
        bind_property ("reveal-child", revealer, "reveal-child", SYNC_CREATE);

        orientation = VERTICAL;
        append (revealer);
    }
}
