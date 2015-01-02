/***
Copyright (C) 2014-2015 Marvin Beckers
This program is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License version 3, as published
by the Free Software Foundation.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranties of
MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along
with this program. If not, see http://www.gnu.org/licenses/.
***/

namespace SwitchboardPlugUserAccounts.Widgets {
	public class UserList : Gtk.ListBox {
		private Gtk.Label my_account_label;
		private Gtk.Label other_accounts_label;

		public UserList () {
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

			update_ui ();
		}

		public void update_ui () {
			List<weak Gtk.Widget> userlist_items = get_children ();
			foreach (unowned Gtk.Widget useritem in userlist_items) {
				//unowned UserItem u = (useritem is UserItem) ? (UserItem) useritem : null;
				remove (useritem);
			}

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

			show_all ();
		}

		public void update_headers (Gtk.ListBoxRow row, Gtk.ListBoxRow? before) {
				if (row == get_row_at_index (1))
					row.set_header (my_account_label);
				else if (row == get_row_at_index (2))
					row.set_header (other_accounts_label);
		}
	}
}
