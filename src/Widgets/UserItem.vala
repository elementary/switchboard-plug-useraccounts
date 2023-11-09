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
        private Gtk.Revealer description_revealer;
        private Adw.Avatar avatar;
        private Gtk.Label full_name_label;
        private Gtk.Label username_label;
        private Gtk.Revealer lock_revealer;

        public weak Act.User user { get; construct; }

        public int account_type {
            set {
                description_revealer.reveal_child = value == Act.UserAccountType.ADMINISTRATOR;
            }
        }

        public UserItem (Act.User user) {
            Object (user: user);
        }

        construct {
            full_name_label = new Gtk.Label ("") {
                halign = Gtk.Align.START,
                valign = Gtk.Align.END
            };
            full_name_label.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);

            username_label = new Gtk.Label ("") {
                halign = Gtk.Align.START,
                valign = Gtk.Align.START,
                ellipsize = Pango.EllipsizeMode.END
            };
            username_label.get_style_context ().add_class (Granite.STYLE_CLASS_SMALL_LABEL);

            var description_label = new Gtk.Label ("<small>(%s)</small>".printf (_("Administrator"))) {
                halign = Gtk.Align.START,
                use_markup = true,
                valign = Gtk.Align.START
            };

            description_revealer = new Gtk.Revealer ();
            description_revealer.add (description_label);

            avatar = new Hdy.Avatar (32, user.real_name, true) {
                margin = 6
            };

            var lock_image = new Gtk.Image.from_icon_name ("locked", Gtk.IconSize.LARGE_TOOLBAR);
            lock_image.halign = lock_image.valign = Gtk.Align.END;

            lock_revealer = new Gtk.Revealer ();
            lock_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
            lock_revealer.add (lock_image);

            var overlay = new Gtk.Overlay ();
            overlay.add (avatar);
            overlay.add_overlay (lock_revealer);

            var grid = new Gtk.Grid () {
                column_spacing = 6,
                margin_end = 12,
                margin_start = 6
            };
            grid.attach (overlay, 0, 0, 1, 2);
            grid.attach (full_name_label, 1, 0, 2, 1);
            grid.attach (username_label, 1, 1, 1, 1);
            grid.attach (description_revealer, 2, 1);

            update ();

            add (grid);

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

            account_type = user.account_type;
            full_name_label.label = user.real_name;
            avatar.text = user.real_name;
            lock_revealer.reveal_child = user.locked;
            username_label.label = user.user_name;
        }
    }
}
