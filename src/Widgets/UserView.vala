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
	public class UserView : Granite.Widgets.ThinPaned {
		public UserList userlist;
		public unowned Act.UserManager usermanager;
		private string[]? installed_lang;
		public SList<Act.User> user_slist;
		public Act.User own_user;

		public Gtk.Stack content;
		public Gtk.Box sidebar;
		public Gtk.ScrolledWindow scrolled_window;
		public ListFooter footer;

		public UserView () {
			sidebar = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
			content = new Gtk.Stack ();

			pack1 (sidebar, true, false);
			pack2 (content, true, false);

			installed_lang = Utils.get_installed_languages ();

			usermanager = Act.UserManager.get_default ();
			usermanager.notify["is-loaded"].connect (() => this.update ());
		}

		public void update () {
			if (usermanager.is_loaded) {
				user_slist = usermanager.list_users ();
				own_user = usermanager.get_user (GLib.Environment.get_user_name ());
				userlist = new UserList (user_slist, own_user);
				userlist.row_selected.connect (userlist_selected);

				foreach (Act.User user in user_slist)
					content.add_named (new UserSettings (user, installed_lang), user.get_user_name ());

				this.build_ui ();
			}
		}

		public void build_ui () {
			scrolled_window = new Gtk.ScrolledWindow (null, null);
			scrolled_window.add (userlist);

			footer = new ListFooter ();
			sidebar.pack_start (scrolled_window, true, true);
			sidebar.pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), false);
			sidebar.pack_end (footer, false, false);

			//auto select own user row in userlist widget
			userlist.select_row (userlist.get_row_at_index (1));
			this.set_position (240);
			this.show_all ();
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
