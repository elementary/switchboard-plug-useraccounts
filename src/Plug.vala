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
 *
 * Authored by: Corentin Noël <tintou@mailoo.org>
 * Authored by: Marvin Beckers <beckersmarvin@gmail.com>
 */

namespace SwitchboardPlugUserAccounts {
	public static Plug plug;

	public class Plug : Switchboard.Plug {
		private Widgets.UserView userview;

		private Gtk.Grid? main_grid = null;
		private Gtk.InfoBar infobar;
		private Gtk.LockButton lock_button;

		public Plug () {
			Object (category: Category.SYSTEM,
				code_name: Build.PLUGCODENAME,
				display_name: _("User Accounts"),
				description: _("Manage user accounts on your local system"),
				icon: "system-users");

			plug = this;
		}

		public override Gtk.Widget get_widget () {
			if (main_grid != null)
				return main_grid;

			main_grid = new Gtk.Grid ();
			main_grid.expand = true;

			infobar = new Gtk.InfoBar ();
			infobar.message_type = Gtk.MessageType.INFO;
			lock_button = new Gtk.LockButton (get_permission ());
			var area = infobar.get_action_area () as Gtk.Container;
			area.add (lock_button);
			var content = infobar.get_content_area () as Gtk.Container;
			var label = new Gtk.Label (_("Some settings require administrator rights to be changed"));
			content.add (label);
			main_grid.attach (infobar, 0, 0, 1, 1);

			userview = new Widgets.UserView ();
			main_grid.attach (userview, 0, 1, 1, 1);
			main_grid.show_all ();

			get_permission ().notify["allowed"].connect (() => {
				if (get_permission ().allowed) {
					infobar.no_show_all = true;
					infobar.hide ();
				}
			});

			return main_grid;
		}

        public override void shown () { }
        public override void hidden () {
			try {
				foreach (Act.User user in get_removal_list ())
					get_usermanager ().delete_user (user, true);
					clear_removal_list ();
			} catch (Error e) { critical (e.message); }
		}
        public override void search_callback (string location) { }

		    // 'search' returns results like ("Keyboard → Behavior → Duration", "keyboard<sep>behavior")
		    public override async Gee.TreeMap<string, string> search (string search) {
		        return new Gee.TreeMap<string, string> (null, null);
		    }
    }
}

public Switchboard.Plug get_plug (Module module) {
	debug ("Activating User Accounts plug");
	var plug = new SwitchboardPlugUserAccounts.Plug ();
	return plug;
}
