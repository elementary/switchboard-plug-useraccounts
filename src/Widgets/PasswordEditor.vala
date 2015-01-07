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
		private Gtk.Revealer error_revealer;
		private Gtk.Label error_pw_label;
		private Gtk.Revealer error_new_revealer;
		private Gtk.Label error_new_label;

		private PasswordQuality.Settings pwquality;

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
			//halign = Gtk.Align.END;

			/*
			 * users who don't have superuser privileges will need to auth against passwd.
			 * therefore they will need these UI elements created and displayed to set is_auth.
			 */
			if (!get_permission ().allowed) {
				/*Gtk.Label current_pw_label = new Gtk.Label (_("Current password:"));
				current_pw_label.halign = Gtk.Align.END;
				attach (current_pw_label, 0, 0, 1, 1);*/

				current_pw_entry = new Gtk.Entry ();
				current_pw_entry.set_size_request (195, 0);
				current_pw_entry.set_placeholder_text (_("Current Password"));
				current_pw_entry.halign = Gtk.Align.START;
				current_pw_entry.set_visibility (false);
				current_pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, null);
				current_pw_entry.set_icon_tooltip_text (Gtk.EntryIconPosition.SECONDARY, _("Press enter to authenticate"));
				current_pw_entry.changed.connect (() => {
					if (current_pw_entry.get_text ().length > 0)
						current_pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "go-jump-symbolic");
					error_revealer.set_reveal_child (false);
				});
				current_pw_entry.activate.connect (password_auth);
				current_pw_entry.icon_release.connect (password_auth);
				attach (current_pw_entry, 0, 0, 1, 1);

				//use TAB to "activate" the GtkEntry for the current password
				this.key_press_event.connect ((e) => {
					if (e.keyval == Gdk.Key.Tab && current_pw_entry.get_sensitive () == true)
						password_auth ();
					return false;
				});

				error_pw_label = new Gtk.Label ("<span font_size=\"small\">%s</span>".
					printf (_("Your input does not match your current password")));
				error_pw_label.set_halign (Gtk.Align.END);
				error_pw_label.get_style_context ().add_class ("error");
				error_pw_label.use_markup = true;

				error_revealer = new Gtk.Revealer ();
				error_revealer.set_transition_type (Gtk.RevealerTransitionType.SLIDE_DOWN);
				error_revealer.set_transition_duration (200);
				error_revealer.set_reveal_child (false);
					error_revealer.add (error_pw_label);
				attach (error_revealer, 0, 1, 1, 1);

				error_new_label = new Gtk.Label ("");
				error_new_label.set_halign (Gtk.Align.END);
				error_new_label.get_style_context ().add_class ("error");
				error_new_label.use_markup = true;

				error_new_revealer = new Gtk.Revealer ();
				error_new_revealer.set_transition_type (Gtk.RevealerTransitionType.SLIDE_DOWN);
				error_new_revealer.set_transition_duration (200);
				error_new_revealer.set_reveal_child (false);
				error_new_revealer.add (error_new_label);
				attach (error_new_revealer, 0, 3, 1, 1);
			} else if (get_permission ().allowed)
				is_auth = true;

			/*var new_pw_label = new Gtk.Label (_("New password:"));
			new_pw_label.halign = Gtk.Align.END;
			attach (new_pw_label, 0, 2, 1, 1);*/

			new_pw_entry = new Gtk.Entry ();
			new_pw_entry.set_size_request (195, 0);
			new_pw_entry.halign = Gtk.Align.START;
			new_pw_entry.set_placeholder_text (_("New Password"));
			new_pw_entry.set_visibility (false);
			
			new_pw_entry.set_icon_tooltip_text (Gtk.EntryIconPosition.SECONDARY, _("Password cannot be empty"));
			new_pw_entry.changed.connect (compare_passwords);
			attach (new_pw_entry, 0, 2, 1, 1);

			pw_level = new Gtk.LevelBar.for_interval (0.0, 100.0);
			pw_level.set_mode (Gtk.LevelBarMode.CONTINUOUS);
			pw_level.add_offset_value ("low", 50.0);
			pw_level.add_offset_value ("high", 75.0);
			pw_level.add_offset_value ("middle", 75.0);
			attach (pw_level, 0, 4, 1, 1);

			/*var confirm_pw_label = new Gtk.Label (_("Confirm password:"));
			confirm_pw_label.halign = Gtk.Align.END;
			attach (confirm_pw_label, 0, 5, 1, 1);*/

			confirm_pw_entry = new Gtk.Entry ();
			confirm_pw_entry.set_size_request (195, 0);
			confirm_pw_entry.halign = Gtk.Align.START;
			confirm_pw_entry.set_placeholder_text (_("Confirm New Password"));
			confirm_pw_entry.set_visibility (false);
			confirm_pw_entry.set_icon_tooltip_text (Gtk.EntryIconPosition.SECONDARY, _("Passwords do not match"));
			confirm_pw_entry.changed.connect (compare_passwords);
			attach (confirm_pw_entry, 0, 5, 1, 1);

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
			attach (show_pw_check, 0, 6, 1, 1);

			if (!is_auth) {
				new_pw_entry.set_sensitive (false);
				confirm_pw_entry.set_sensitive (false);
				show_pw_check.set_sensitive (false);
			}

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
				show_pw_check.set_sensitive (true);
			}
		}

		private void compare_passwords () {
			bool is_obscure = false;

			if (new_pw_entry.get_text () != "") {
				var val = pwquality.check (new_pw_entry.get_text ());
				if (val <= 25)
					val = 25;
				pw_level.set_value (val);

				if (val >= 0 && val <= 50)
					pw_level.set_tooltip_text (_("Weak password strength"));
				else if (val > 50 && val <= 75)
					pw_level.set_tooltip_text (_("Medium password strength"));
				else if (val > 75)
					pw_level.set_tooltip_text (_("Strong password strength"));

				/*
				 * without superuser privileges your new password needs to pass an obscurity test
				 * which is based on passwd's one to guess passwd's response.
				 */
				if (!get_permission ().allowed) {
					var result = ObscurityTest.test (current_pw_entry.get_text (),
						new_pw_entry.get_text ());
					if (result == ObscurityTest.RESULT.OBSCURE) {
						is_obscure = true;
						error_new_revealer.set_reveal_child (false);
					} else {
						var error_msg = "test";
						if (result == ObscurityTest.RESULT.SIMILIAR)
							error_msg = _("Resembles your current password");
						else if (result == ObscurityTest.RESULT.SIMPLE)
							error_msg = _("New password is too simple");
						else if (result == ObscurityTest.RESULT.PALINDROME)
							error_msg = _("New password is a palindrome");

						error_new_label.set_label ("<span font_size=\"small\">%s</span>"
							.printf (error_msg));
						error_new_revealer.set_reveal_child (true);
						is_obscure = false;
					}
				} else
					//a superuser does not need to care about obscurity
					is_obscure = true;
			}

			if (new_pw_entry.get_text () == confirm_pw_entry.get_text ()
			&& new_pw_entry.get_text () != "" && is_obscure) {
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
					error_new_revealer.set_reveal_child (false);
					confirm_pw_entry.set_sensitive (false);
					confirm_pw_entry.set_text ("");
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
					debug ("Authentication error: %s".printf (e.message));
					error_revealer.set_reveal_child (true);
					error_revealer.show_all ();
					is_auth = false;
					auth_changed ();
				} else {
					debug ("User is authenticated for password change now");
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
