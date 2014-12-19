/*-
 * Copyright (c) 2014 Marvin Beckers <beckersmarvin@gmail.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

namespace SwitchboardPlugUsers.Widgets {

	public class UserList : Gtk.ListBox {
		private unowned SList<Act.User> userlist;
		private Act.User own_user;

		private Gtk.Label my_account_label;
		private Gtk.Label other_accounts_label;

		public UserList (SList<Act.User> userlist, Act.User own_user) {
			this.selection_mode = Gtk.SelectionMode.SINGLE;
			this.userlist = userlist;
			this.own_user = own_user;
			set_header_func (update_headers);
			build_ui ();

			show_all ();
		}

		private void build_ui () {
			//cheat an invisible box at pos 0 because update_headers does not reach pos 0
			insert (new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0), 0);

			my_account_label = new Gtk.Label ("");
			my_account_label.margin_top = 10;
			my_account_label.margin_start = 5;
			my_account_label.halign = Gtk.Align.START;
			my_account_label.use_markup = true;
			my_account_label.set_label ("<b>"+_("My Account")+"</b>");
			my_account_label.set_sensitive (false);

			other_accounts_label = new Gtk.Label ("");
			other_accounts_label.margin_top = 10;
			other_accounts_label.margin_start = 5;
			other_accounts_label.halign = Gtk.Align.START;
			other_accounts_label.use_markup = true;
			other_accounts_label.set_label ("<b>"+_("Other Accounts")+"</b>");
			other_accounts_label.set_sensitive (false);

			update_ui ();
		}

		public void update_ui () {
			insert (new UserItem (own_user), 1);

			int i = 2;
			foreach (unowned Act.User temp_user in userlist) {
				if (own_user != temp_user) {
					insert (new UserItem (temp_user), i);
					i++;
				}
			}
			show_all ();
		}

		public void update_headers (Gtk.ListBoxRow row, Gtk.ListBoxRow before) {
			if (row == get_row_at_index (1))
				row.set_header (my_account_label);
			else if (row == get_row_at_index (2))
				row.set_header (other_accounts_label);
		}
	}
}
