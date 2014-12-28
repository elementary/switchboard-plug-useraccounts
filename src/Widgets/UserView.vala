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

namespace SwitchboardPlugUserAccounts.Widgets {
	public class UserView : Granite.Widgets.ThinPaned {
		public UserList userlist = null;
		public SList<Act.User> user_slist;
		public Gtk.Stack content;
		public Gtk.Box sidebar;
		public Gtk.ScrolledWindow scrolled_window;
		public ListFooter footer;

		public UserView () {
			sidebar = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
			content = new Gtk.Stack ();
			
			expand = true;
			pack1 (sidebar, true, false);
			pack2 (content, true, false);

			get_usermanager ().notify["is-loaded"].connect (update);
		}

		private void update () {
			if (get_usermanager ().is_loaded) {
				user_slist = get_usermanager ().list_users ();
				get_usermanager ().user_added.connect (add_user_settings);
				get_usermanager ().user_removed.connect (remove_user_settings);

				userlist = new UserList ();
				userlist.row_selected.connect (userlist_selected);

				foreach (Act.User user in user_slist)
					add_user_settings (user);

				build_ui ();
			}
		}

		public void build_ui () {
			scrolled_window = new Gtk.ScrolledWindow (null, null);
			scrolled_window.add (userlist);

			footer = new ListFooter ();
			footer.removal_changed.connect (userlist.update_ui);
			sidebar.pack_start (scrolled_window, true, true);
			sidebar.pack_end (footer, false, false);

			//auto select current user row in userlist widget
			userlist.select_row (userlist.get_row_at_index (1));
			set_position (240);
			show_all ();
		}

		private void add_user_settings (Act.User user) {
			debug ("adding UserSettings Widget for User '%s'".printf (user.get_user_name ()));
			content.add_named (new UserSettings (user), user.get_user_name ());
		}

		private void remove_user_settings (Act.User user) {
			debug ("removing UserSettings Widget for User '%s'".printf (user.get_user_name ()));
			content.remove (content.get_child_by_name (user.get_user_name ()));
		}

		private void userlist_selected (Gtk.ListBoxRow? user_item) {
			string? user_name = null;
			if (user_item != null) {
				user_name = ((UserItem)user_item).user_name;
				content.set_visible_child_name (user_name);
				footer.set_selected_user (user_name);
			}
		}
	}
}
