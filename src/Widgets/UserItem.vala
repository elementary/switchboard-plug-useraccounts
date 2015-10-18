/***
  Copyright (C) 2014-2015 Switchboard User Accounts Plug Developer
  This program is free software: you can redistribute it and/or modify it
  under the terms of the GNU Lesser General Public License version 3, as published
  by the Free Software Foundation.

  This program is distributed in the hope that it will be useful, but
  WITHOUT ANY WARRANTY; without even the implied warranties of
  MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
  PURPOSE. See the GNU General Public License for more details.

  You should have received a copy of the GNU General Public License along
  with this program. If not, see http://www.gnu.org/licenses/.
***/

namespace SwitchboardPlugUserAccounts.Widgets {
    public class UserItem : Gtk.ListBoxRow {
        private Gtk.Grid                grid;
        private Granite.Widgets.Avatar  avatar;
        private Gdk.Pixbuf              avatar_pixbuf;
        private Gtk.Box                 label_box;
        private Gtk.Label               full_name_label;
        private Gtk.Label               description_label;

        public weak Act.User user { public get; private set; }

        public UserItem (Act.User user) {
            this.user = user;
            user.changed.connect (update_ui);

            build_ui ();
        }

        private void build_ui () {
            grid = new Gtk.Grid ();
            grid.margin = 6;
            grid.margin_left = 12;
            grid.column_spacing = 6;
            add (grid);

            label_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            label_box.vexpand = true;
            label_box.valign = Gtk.Align.CENTER;
            grid.attach (label_box, 1, 0, 1, 1);

            full_name_label = new Gtk.Label ("");
            full_name_label.halign = Gtk.Align.START;
            full_name_label.get_style_context ().add_class ("h3");

            description_label = new Gtk.Label ("");
            description_label.halign = Gtk.Align.START;
            description_label.use_markup = true;

            label_box.pack_start (full_name_label, false, false);
            label_box.pack_start (description_label, false, false);

            update_ui ();

            grid.attach (avatar, 0, 0, 1, 1);
        }

        public void update_ui () {
            if (avatar == null) {
                avatar = new Granite.Widgets.Avatar ();
                avatar.margin_end = 3;
            }

            try {
                avatar_pixbuf = new Gdk.Pixbuf.from_file_at_scale (user.get_icon_file (), 32, 32, true);
                avatar.pixbuf = avatar_pixbuf;
            } catch (Error e) {
                avatar.show_default (32);
            }

            full_name_label.set_label (user.get_real_name ());
            string description = "<span font_size=\"small\">%s</span>".printf (user.get_user_name ());
            if (user.get_account_type () == Act.UserAccountType.ADMINISTRATOR)
                description = "<span font_size=\"small\">%s (%s)</span>".printf (user.get_user_name (), _("Administrator"));
            description_label.set_label (description);
            
            grid.show_all ();
        }
    }
}
