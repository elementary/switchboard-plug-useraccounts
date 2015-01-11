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
    public class UserListBox : Gtk.ListBox {
        private Gtk.Label       my_account_label;
        private Gtk.Label       other_accounts_label;
        private Gtk.ListBoxRow  guest_session_row;
        private Gtk.Label       guest_description_label;

        public UserListBox () {
            selection_mode = Gtk.SelectionMode.SINGLE;
            get_usermanager ().user_added.connect (update_ui);
            get_usermanager ().user_removed.connect (update_ui);
            set_header_func (update_headers);

            build_ui ();
            show_all ();
        }

        private void build_ui () {
            my_account_label = new Gtk.Label (_("My Account"));
            my_account_label.margin_top = 5;
            my_account_label.margin_start = 5;
            my_account_label.halign = Gtk.Align.START;
            my_account_label.get_style_context ().add_class ("category-label");
            my_account_label.set_sensitive (false);

            other_accounts_label = new Gtk.Label (_("Other Accounts"));
            other_accounts_label.margin_top = 5;
            other_accounts_label.margin_start = 5;
            other_accounts_label.halign = Gtk.Align.START;
            other_accounts_label.get_style_context ().add_class ("category-label");
            other_accounts_label.set_sensitive (false);

            build_guest_session_row ();
            update_ui ();
        }

        public void update_ui () {
            List<weak Gtk.Widget> userlist_items = get_children ();
            foreach (unowned Gtk.Widget useritem in userlist_items)
                remove (useritem);

            //cheat an invisible box at pos 0 because update_headers does not reach pos 0
            insert (new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0), 0);

            insert (new UserItem (get_current_user ()), 1);
            int pos = 2;
            foreach (unowned Act.User temp_user in get_usermanager ().list_users ()) {
                if (get_current_user () != temp_user && !check_removal (temp_user)) {
                    insert (new UserItem (temp_user), pos);
                    pos++;
                }
            }

            insert (guest_session_row, pos);

            show_all ();
        }

        public void update_headers (Gtk.ListBoxRow row, Gtk.ListBoxRow? before) {
                if (row == get_row_at_index (1))
                    row.set_header (my_account_label);
                else if (row == get_row_at_index (2))
                    row.set_header (other_accounts_label);
        }

        public void update_guest () {
            string state_string = _("Enabled");
            bool state = get_guest_session_state ();
            if (!state)
                state_string = _("Disabled");

            guest_description_label.set_label ("<span font_size=\"small\">%s</span>".printf (state_string));
        }

        private void build_guest_session_row () {
            guest_session_row = new Gtk.ListBoxRow ();
            guest_session_row.name = "guest_session";
            Gtk.Grid row_grid = new Gtk.Grid ();
            row_grid.margin = 6;
            row_grid.margin_left = 12;
            row_grid.column_spacing = 6;
            guest_session_row.add (row_grid);

            Gtk.Image avatar = new Gtk.Image.from_icon_name ("avatar-default", Gtk.IconSize.DND);
            avatar.margin_end = 3;
            row_grid.attach (avatar, 0, 0, 1, 1);

            Gtk.Box label_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            label_box.vexpand = true;
            label_box.valign = Gtk.Align.CENTER;
            row_grid.attach (label_box, 1, 0, 1, 1);

            Gtk.Label full_name_label = new Gtk.Label (_("Guest Session"));
            full_name_label.halign = Gtk.Align.START;
            full_name_label.get_style_context ().add_class ("h3");

            guest_description_label = new Gtk.Label (null);
            guest_description_label.halign = Gtk.Align.START;
            guest_description_label.use_markup = true;

            update_guest ();

            label_box.pack_start (full_name_label, false, false);
            label_box.pack_start (guest_description_label, false, false);
        }
    }
}
