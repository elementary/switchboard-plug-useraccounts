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

namespace SwitchboardPlugUserAccounts.Widgets {
    public class UserItem : Gtk.ListBoxRow {
        private Granite.Widgets.Avatar avatar;
        private Gtk.Label full_name_label;
        private Gtk.Label username_label;
        private Gtk.Revealer description_revealer;

        public weak Act.User user { get; construct; }

        public int account_type {
            set {
                description_revealer.reveal_child = value == Act.UserAccountType.ADMINISTRATOR;
            }
        }

        public string user_name {
            set {
                username_label.label = GLib.Markup.printf_escaped ("<small>%s</small>", value);
            }
        }

        public string icon_file {
            set {
                try {
                    var size = 32 * get_style_context ().get_scale ();
                    avatar.pixbuf = new Gdk.Pixbuf.from_file_at_scale (value, size, size, true);
                } catch (Error e) {
                    avatar.show_default (32);
                }
            }
        }

        public UserItem (Act.User user) {
            Object (user: user);
        }

        construct {
            full_name_label = new Gtk.Label ("");
            full_name_label.halign = Gtk.Align.START;
            full_name_label.get_style_context ().add_class ("h3");

            username_label = new Gtk.Label ("");
            username_label.halign = Gtk.Align.START;
            username_label.use_markup = true;
            username_label.ellipsize = Pango.EllipsizeMode.END;

            var description_label = new Gtk.Label ("<small>(%s)</small>".printf (_("Administrator")));
            description_label.halign = Gtk.Align.START;
            description_label.use_markup = true;

            description_revealer = new Gtk.Revealer ();
            description_revealer.add (description_label);

            avatar = new Granite.Widgets.Avatar ();

            var lock_image = new Gtk.Image.from_icon_name ("locked", Gtk.IconSize.LARGE_TOOLBAR);
            lock_image.halign = lock_image.valign = Gtk.Align.END;

            var lock_revealer = new Gtk.Revealer ();
            lock_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
            lock_revealer.add (lock_image);

            var overlay = new Gtk.Overlay ();
            overlay.add (avatar);
            overlay.add_overlay (lock_revealer);

            var grid = new Gtk.Grid ();
            grid.margin = 6;
            grid.margin_start = grid.margin_end = 12;
            grid.column_spacing = 6;
            grid.attach (overlay, 0, 0, 1, 2);
            grid.attach (full_name_label, 1, 0, 2, 1);
            grid.attach (username_label, 1, 1, 1, 1);
            grid.attach (description_revealer, 2, 1);

            add (grid);

            user.bind_property ("account-type", this, "account-type", GLib.BindingFlags.SYNC_CREATE);
            user.bind_property ("icon-file", this, "icon-file", GLib.BindingFlags.SYNC_CREATE);
            user.bind_property ("real-name", full_name_label, "label", GLib.BindingFlags.SYNC_CREATE);
            user.bind_property ("locked", lock_revealer, "reveal-child", GLib.BindingFlags.SYNC_CREATE);
            user.bind_property ("user-name", this, "user-name", GLib.BindingFlags.SYNC_CREATE);
        }
    }
}
