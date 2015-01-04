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
	public class PasswordEditor : Gtk.Grid {
		private Gtk.Entry current_pw_entry;
		private Gtk.Entry new_pw_entry;
		private Gtk.Entry confirm_pw_entry;
		private Gtk.CheckButton show_pw_check;
		private Gtk.LevelBar pw_level;

		private PasswordQuality.Settings pwquality;
		public Passwd.Handler h;

		private bool is_auth = false;
		private signal void auth_changed ();

		public bool is_valid = false;
		public signal void validation_changed ();

		public PasswordEditor () {
			pwquality = new PasswordQuality.Settings ();
			build_ui ();
		}

		private void build_ui () {
			expand = true;
			set_row_spacing (10);
			set_column_spacing (10);
			halign = Gtk.Align.END;

			if (!get_permission ().allowed) {
				Gtk.Label current_pw_label = new Gtk.Label (_("Current password:"));
				current_pw_label.halign = Gtk.Align.END;
				attach (current_pw_label, 0, 0, 1, 1);

				current_pw_entry = new Gtk.Entry ();
				current_pw_entry.halign = Gtk.Align.START;
				current_pw_entry.set_visibility (false);
				current_pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "dialog-password-symbolic");
				current_pw_entry.set_icon_tooltip_text (Gtk.EntryIconPosition.SECONDARY, _("Press enter to authenticate"));
				current_pw_entry.activate.connect (password_auth);
				attach (current_pw_entry, 1, 0, 1, 1);
			} else if (get_permission ().allowed)
				is_auth = true;

			var new_pw_label = new Gtk.Label (_("New password:"));
			new_pw_label.halign = Gtk.Align.END;
			attach (new_pw_label, 0, 1, 1, 1);

			new_pw_entry = new Gtk.Entry ();
			new_pw_entry.halign = Gtk.Align.START;
			new_pw_entry.set_visibility (false);
			if (!is_auth)
				new_pw_entry.set_sensitive (false);
			
			new_pw_entry.set_icon_tooltip_text (Gtk.EntryIconPosition.SECONDARY, _("Password cannot be empty"));
			new_pw_entry.changed.connect (compare_passwords);
			attach (new_pw_entry, 1, 1, 1, 1);

			pw_level = new Gtk.LevelBar.for_interval (0.0, 100.0);
			pw_level.set_mode (Gtk.LevelBarMode.CONTINUOUS);
			pw_level.add_offset_value ("low", 25.0);
			pw_level.add_offset_value ("middle", 50.0);
			pw_level.add_offset_value ("high", 75.0);
			attach (pw_level, 1, 2, 1, 1);

			var confirm_pw_label = new Gtk.Label (_("Confirm:"));
			confirm_pw_label.halign = Gtk.Align.END;
			attach (confirm_pw_label, 0, 3, 1, 1);

			confirm_pw_entry = new Gtk.Entry ();
			confirm_pw_entry.halign = Gtk.Align.START;
			confirm_pw_entry.set_visibility (false);
			if (!is_auth)
				confirm_pw_entry.set_sensitive (false);
			confirm_pw_entry.set_icon_tooltip_text (Gtk.EntryIconPosition.SECONDARY, _("Passwords do not match"));
			confirm_pw_entry.changed.connect (compare_passwords);
			attach (confirm_pw_entry, 1, 3, 1, 1);

			show_pw_check = new Gtk.CheckButton.with_label (_("Show passwords"));
			show_pw_check.clicked.connect (() => {
				if (show_pw_check.get_active ()) {
					new_pw_entry.set_visibility (true);
					confirm_pw_entry.set_visibility (true);
				} else {
					new_pw_entry.set_visibility (false);
					confirm_pw_entry.set_visibility (false);
				}
			});
			attach (show_pw_check, 1, 4, 1, 1);

			auth_changed.connect (update_ui);

			show_all ();
		}

		private void update_ui () {
			if (is_auth) {
				current_pw_entry.set_sensitive (false);
				current_pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "process-completed-symbolic");
				current_pw_entry.set_icon_tooltip_text (Gtk.EntryIconPosition.SECONDARY, _("Password accepted"));
				new_pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "dialog-error-symbolic");
				new_pw_entry.set_sensitive (true);
				new_pw_entry.grab_focus ();
				confirm_pw_entry.set_sensitive (true);
			}
		}

		private void compare_passwords () {
			if (new_pw_entry.get_text () != "") {
				var val = pwquality.check (new_pw_entry.get_text ());
				if (val <= 0)
					val = 1;
				//debug ("password quality level: %d".printf (val));
				pw_level.set_value (val);
				if (val > 0 && val <= 25)
					pw_level.set_tooltip_text (_("Weak password strength"));
				else if (val > 25 && val <= 75)
					pw_level.set_tooltip_text (_("Medium password strength"));
				else if (val > 75)
					pw_level.set_tooltip_text (_("Strong password strength"));
			}
			if (new_pw_entry.get_text () == confirm_pw_entry.get_text () && new_pw_entry.get_text () != "") {
				is_valid = true;
				new_pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, null);
				confirm_pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, null);
			} else {
				is_valid = false;

				if (new_pw_entry.get_text () != confirm_pw_entry.get_text ())
					confirm_pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "dialog-error-symbolic");
				else
					confirm_pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, null);

				if (new_pw_entry.get_text () == "") {
					new_pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "dialog-error-symbolic");
					confirm_pw_entry.set_sensitive (false);
				} else {
					new_pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, null);
					confirm_pw_entry.set_sensitive (true);
				}
			}
			validation_changed ();
		}
		private void password_auth () {
			Passwd.passwd_authenticate (get_passwd_handler (true), current_pw_entry.get_text (), (h, e) => {
				if (e != null) {
					debug ("auth error: %s".printf (e.message));
					is_auth = false;
					auth_changed ();
				} else {
					debug ("user is authenticated for password change now");
					is_auth = true;
					auth_changed ();
				}
			});
		}

		public string? get_password () {
			if (is_valid)
				return new_pw_entry.get_text ();
			else
				return null;
		}

		public void reset () {
			new_pw_entry.set_text ("");
			confirm_pw_entry.set_text ("");
		}
	}
}
