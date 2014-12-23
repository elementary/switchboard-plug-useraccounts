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
		public UserList userlist;
		public unowned Act.UserManager usermanager;
		public SList<Act.User> user_slist;
		public unowned Act.User current_user;
		public Gtk.Stack content;
		public Gtk.Box sidebar;
		public Gtk.ScrolledWindow scrolled_window;
		public ListFooter footer;


		public UserView (Polkit.Permission _permission) {
			sidebar = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
			content = new Gtk.Stack ();
			
			expand = true;

			pack1 (sidebar, true, false);
			pack2 (content, true, false);

			usermanager = Act.UserManager.get_default ();
			usermanager.notify["is-loaded"].connect (update);
		}

		private void update () {
			if (usermanager.is_loaded) {
				user_slist = usermanager.list_users ();
				current_user = usermanager.get_user (GLib.Environment.get_user_name ());
				userlist = new UserList (usermanager, current_user);
				userlist.row_selected.connect (userlist_selected);

				foreach (Act.User user in user_slist)
					content.add_named (new UserSettings (user, (user == current_user)), user.get_user_name ());

				build_ui ();
			}
		}

		public void build_ui () {
			scrolled_window = new Gtk.ScrolledWindow (null, null);
			scrolled_window.add (userlist);

			footer = new ListFooter ();
			sidebar.pack_start (scrolled_window, true, true);
			sidebar.pack_end (footer, false, false);

			//auto select current user row in userlist widget
			userlist.select_row (userlist.get_row_at_index (1));
			set_position (240);
			show_all ();
		}

		public void userlist_selected (Gtk.ListBoxRow? user_item) {
			string? user_name = null;
			if (user_item != null)
				user_name = ((UserItem)user_item).user_name;

			if (user_name != null) {
				foreach (Act.User user in user_slist) {
					if (user.get_user_name () == user_name) {
						content.set_visible_child_name (user_name);
						break;
					}
				}
			}
		}
	}
}
