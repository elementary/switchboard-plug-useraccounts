/*
* Copyright 2014-2019 elementary, Inc. (https://elementary.io)
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

public class SwitchboardPlugUserAccounts.Widgets.UserItem : Gtk.ListBoxRow {
    private Gtk.Revealer description_revealer;
    private Hdy.Avatar avatar;
    private Gtk.Label full_name_label;
    private Gtk.Label username_label;
    private Gtk.Revealer lock_revealer;

    public weak Act.User user { get; construct; }

    public UserItem (Act.User user) {
        Object (user: user);
    }

    construct {
        full_name_label = new Gtk.Label ("") {
            halign = START,
            valign = END
        };
        full_name_label.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);

        username_label = new Gtk.Label ("") {
            halign = START,
            valign = START,
            ellipsize = END
        };
        username_label.get_style_context ().add_class (Granite.STYLE_CLASS_SMALL_LABEL);

        avatar = new Hdy.Avatar (32, user.real_name, true) {
            margin_top = 6,
            margin_end = 12,
            margin_bottom = 6
        };

        var lock_image = new Gtk.Image.from_icon_name ("locked", Gtk.IconSize.LARGE_TOOLBAR) {
            halign = END,
            valign = END,
            pixel_size = 24
        };

        lock_revealer = new Gtk.Revealer () {
            child = lock_image,
            transition_type = CROSSFADE
        };

        var overlay = new Gtk.Overlay () {
            child = avatar
        };
        overlay.add_overlay (lock_revealer);

        var grid = new Gtk.Grid () {
            margin_end = 12,
            margin_start = 12
        };
        grid.attach (overlay, 0, 0, 1, 2);
        grid.attach (full_name_label, 1, 0);
        grid.attach (username_label, 1, 1);

        update ();

        child = grid;

        // Need to make a weak signal connection for automatic disconnection when finalised
        // Otherwise UserItem is never destroyed (memory leak)
        unowned UserItem weak_this = this;
        user.changed.connect (weak_this.update);
    }

    private void update () {
        var user_icon_file = File.new_for_path (user.get_icon_file ());
        if (user_icon_file.query_exists ()) {
            avatar.loadable_icon = new FileIcon (user_icon_file);
        } else {
            avatar.loadable_icon = null;
        }

        full_name_label.label = user.real_name;
        avatar.text = user.real_name;
        lock_revealer.reveal_child = user.locked;
        username_label.label = user.user_name;

        if (user.account_type == Act.UserAccountType.ADMINISTRATOR) {
            username_label.label += " (%s)".printf (_("Administrator"));
        }
    }
}
