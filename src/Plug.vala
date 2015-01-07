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

Authored by: Corentin Noël <tintou@mailoo.org>
Authored by: Marvin Beckers <beckersmarvin@gmail.com>
***/

namespace SwitchboardPlugUserAccounts {
	public static Plug plug;

	public class Plug : Switchboard.Plug {
		private Gtk.Grid? main_grid;
		private Gtk.InfoBar infobar;
		private Gtk.InfoBar infobar_error;
		private Gtk.LockButton lock_button;
		private Widgets.UserView userview;

		//translatable string for org.pantheon.user-accounts.administration policy
		public const string policy_message = _("Authentication is required to change user data");

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

			infobar_error = new Gtk.InfoBar ();
			infobar_error.message_type = Gtk.MessageType.ERROR;
			infobar_error.no_show_all = true;
			var error_button = infobar_error.add_button (_("Ok"), 1);
			error_button.clicked.connect (get_pe_notifier ().unset_error);
			var error_label = new Gtk.Label ("");
			var error_content = infobar_error.get_content_area () as Gtk.Container;
			error_content.add (error_label);

			main_grid.attach (infobar_error, 0, 0, 1, 1);

			get_pe_notifier ().notified.connect (() => {
				if (get_pe_notifier ().is_error ()) {
					infobar_error.no_show_all = false;
					error_label.set_label (("%s: %s".printf
						(_("Password change failed"), get_pe_notifier ().get_error_message ())));
					infobar_error.show_all ();
				} else {
					infobar_error.no_show_all = true;
					infobar_error.hide ();
				}
			});

			infobar = new Gtk.InfoBar ();
			infobar.message_type = Gtk.MessageType.INFO;
			lock_button = new Gtk.LockButton (get_permission ());
			var area = infobar.get_action_area () as Gtk.Container;
			area.add (lock_button);
			var content = infobar.get_content_area () as Gtk.Container;
			var label = new Gtk.Label (_("Some settings require administrator rights to be changed"));
			content.add (label);
			main_grid.attach (infobar, 0, 1, 1, 1);

			userview = new Widgets.UserView ();
			main_grid.attach (userview, 0, 2, 1, 1);
			main_grid.show_all ();

			get_permission ().notify["allowed"].connect (() => {
				if (get_permission ().allowed) {
					infobar.no_show_all = true;
					infobar.hide ();
				}
			});

			return main_grid;
		}

		public override void shown () {
			if (!get_permission ().allowed) {
				infobar.no_show_all = false;
				infobar.show_all ();
			}
		}

		public override void hidden () {
			try {
				foreach (Act.User user in get_removal_list ()) {
					debug ("Removing user %s from system".printf (user.get_user_name ()));
					get_usermanager ().delete_user (user, true);
				}
				debug ("Clearing removal list");
				clear_removal_list ();
			} catch (Error e) { critical (e.message); }

			if (get_permission ().allowed) {
				try {
					debug ("Releasing administrative permissions");
					get_permission ().release ();
				} catch (Error e) {
					critical (e.message);
				}
			}
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
