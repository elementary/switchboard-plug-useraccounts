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
	public class UserSettings : Gtk.Grid {
		private Act.User user;

		private Gtk.Image avatar;
		private Gdk.Pixbuf? avatar_pixbuf;
		private Gtk.Entry full_name_entry;
		private Gtk.Button change_password_button;
		private Gtk.Button enable_user_button;
		private Gtk.ComboBoxText user_type_box;
		private Gtk.ComboBoxText language_box;
		private Gtk.Switch autologin_switch;

		//lock widgets
		private Gtk.Image full_name_lock = new Gtk.Image.from_icon_name ("changes-prevent-symbolic", Gtk.IconSize.BUTTON);
		private Gtk.Image user_type_lock = new Gtk.Image.from_icon_name ("changes-prevent-symbolic", Gtk.IconSize.BUTTON);
		private Gtk.Image language_lock = new Gtk.Image.from_icon_name ("changes-prevent-symbolic", Gtk.IconSize.BUTTON);
		private Gtk.Image autologin_lock = new Gtk.Image.from_icon_name ("changes-prevent-symbolic", Gtk.IconSize.BUTTON);
		private Gtk.Image password_lock = new Gtk.Image.from_icon_name ("changes-prevent-symbolic", Gtk.IconSize.BUTTON);
		private Gtk.Image enable_lock = new Gtk.Image.from_icon_name ("changes-prevent-symbolic", Gtk.IconSize.BUTTON);

		public UserSettings (Act.User _user) {
			user = _user;
			user.changed.connect (update_ui);
			build_ui ();
		}
		
		public void build_ui () {
			margin = 20;
			set_row_spacing (10);
			set_column_spacing (20);
			set_valign (Gtk.Align.START);
			set_halign (Gtk.Align.CENTER);

			full_name_entry = new Gtk.Entry ();
			full_name_entry.get_style_context ().add_class ("h3");
			full_name_entry.activate.connect (change_full_name);
			attach (full_name_entry, 1, 0, 1, 1);

			Gtk.Label user_type_label = new Gtk.Label (_("Account type:"));
			user_type_label.halign = Gtk.Align.END;
			attach (user_type_label,0, 1, 1, 1);

			user_type_box = new Gtk.ComboBoxText ();
			user_type_box.append_text (_("Standard"));
			user_type_box.append_text (_("Administrator"));
			user_type_box.changed.connect (change_user_type);
			attach (user_type_box, 1, 1, 1, 1);

			Gtk.Label lang_label = new Gtk.Label (_("Language:"));
			lang_label.halign = Gtk.Align.END;
			attach (lang_label, 0, 2, 1, 1);

			language_box = new Gtk.ComboBoxText ();
			foreach (string s in get_installed_languages ())
				language_box.append_text (s);
			language_box.changed.connect (change_lang);
			attach (language_box, 1, 2, 1, 1);

			Gtk.Label login_label = new Gtk.Label (_("Log In automatically:"));
			login_label.halign = Gtk.Align.END;
			login_label.margin_top = 20;
			attach (login_label, 0, 3, 1, 1);

			autologin_switch = new Gtk.Switch ();
			autologin_switch.hexpand = true;
			autologin_switch.halign = Gtk.Align.START;
			autologin_switch.margin_top = 20;
			autologin_switch.notify["active"].connect (change_autologin);
			attach (autologin_switch, 1, 3, 1, 1);

			Gtk.Label change_password_label = new Gtk.Label (_("Password:"));
			change_password_label.halign = Gtk.Align.END;
			attach (change_password_label, 0, 4, 1, 1);

			change_password_button = new Gtk.Button ();
			change_password_button.clicked.connect (() => {
				Dialogs.PasswordDialog pw_dialog = new Dialogs.PasswordDialog (user);
				pw_dialog.request_password_change.connect (change_password);
				pw_dialog.show ();
			});
			attach (change_password_button, 1, 4, 1, 1);

			enable_user_button = new Gtk.Button ();
			enable_user_button.clicked.connect (change_lock);
			enable_user_button.set_sensitive (false);
			enable_user_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
			attach (enable_user_button, 1, 5, 1, 1);

			//attach locks
			attach (full_name_lock, 2, 0, 1, 1);
			attach (user_type_lock, 2, 1, 1, 1);
			attach (language_lock, 2, 2, 1, 1);
			autologin_lock.margin_top = 20;
			attach (autologin_lock, 2, 3, 1, 1);
			attach (password_lock, 2, 4, 1, 1);
			attach (enable_lock, 2, 5, 1, 1);

			update_ui ();
			attach (avatar, 0, 0, 1, 1);

			permission.notify["allowed"].connect (update_ui);
		}
		
		public void update_ui () {
			full_name_entry.set_sensitive (false);
			user_type_box.set_sensitive (false);
			language_box.set_sensitive (false);
			change_password_button.set_sensitive (false);
			autologin_switch.set_sensitive (false);

			full_name_lock.set_opacity (1);
			user_type_lock.set_opacity (1);
			language_lock.set_opacity (1);
			autologin_lock.set_opacity (1);
			password_lock.set_opacity (1);
			enable_lock.set_opacity (1);

			if (get_current_user () == user || get_permission ().allowed) {
				full_name_entry.set_sensitive (true);
				full_name_lock.set_opacity (0);
				language_box.set_sensitive (true);
				language_lock.set_opacity (0);
				if (!user.get_locked ()) {
					change_password_button.set_sensitive (true);
					password_lock.set_opacity (0);
				}
				if (get_permission ().allowed) {
					if (!user.get_locked ()) {
						autologin_switch.set_sensitive (true);
						autologin_lock.set_opacity (0);
					}
					if (!is_last_admin (user) && get_current_user () != user) {
						user_type_box.set_sensitive (true);
						user_type_lock.set_opacity (0);
					}
				}
			}
			try {
				avatar_pixbuf = new Gdk.Pixbuf.from_file_at_scale (user.get_icon_file (), 72, 72, true);
				avatar = new Gtk.Image.from_pixbuf (avatar_pixbuf);
			} catch (Error e) {
				Gtk.IconTheme icon_theme = Gtk.IconTheme.get_default ();
				try {
					avatar_pixbuf = icon_theme.load_icon ("avatar-default", 72, 0);
					avatar = new Gtk.Image.from_pixbuf (avatar_pixbuf);
				} catch (Error e) { }
			}
			avatar.halign = Gtk.Align.END;

			full_name_entry.set_text (user.get_real_name ());

			//set user_type_box according to accounttype
			if (user.get_account_type () == Act.UserAccountType.ADMINISTRATOR)
				user_type_box.set_active (1);
			else
				user_type_box.set_active (0);

			//set autologin_switch according to autologin
			if (user.get_automatic_login () && !autologin_switch.get_active ())
				autologin_switch.set_active (true);
			else if (!user.get_automatic_login () && autologin_switch.get_active ())
				autologin_switch.set_active (false);

			if (user.get_password_mode () == Act.UserPasswordMode.NONE || user.get_locked ())
				change_password_button.set_label (_("Create password"));
			else
				change_password_button.set_label (_("Change password"));

			if (user.get_locked ()) {
				enable_user_button.set_label (_("Enable user account"));
				enable_user_button.get_style_context ().remove_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
			} else if (!user.get_locked ())
				enable_user_button.set_label (_("Disable user account"));

			if (get_permission ().allowed && get_current_user () != user && !is_last_admin (user)) {
				enable_user_button.set_sensitive (true);
				enable_lock.set_opacity (0);
				if (!user.get_locked ())
					enable_user_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
			}

			int i = 0;
			foreach (string s in get_installed_languages ()) {
				if (user.get_language () == s) {
					language_box.set_active (i);
					break;
				}
				i++;
			}

			show_all ();
		}

		private void change_full_name () {
			string new_full_name = full_name_entry.get_text ();
			if (new_full_name != user.get_real_name ()) {
				if (get_current_user () == user || get_permission ().allowed) {
					debug ("changed real name");
					user.set_real_name (new_full_name);
				} else {
					debug ("Insuffienct permission to change real name");
					update_ui ();
				}
			}
		}

		private void change_lang () {
			string new_lang = language_box.get_active_text ();
			if (new_lang != user.get_language ()) {
				if (get_current_user () == user || get_permission ().allowed) {
					debug ("changed language for %s".printf (user.get_user_name ()));
					user.set_language (new_lang);
				} else {
					debug ("Insuffienct permission to change language");
					update_ui ();
				}
			}
		}

		private void change_lock () {
			if (get_permission ().allowed && get_current_user () != user) {
				if (user.get_locked ()) {
					user.set_password_mode (Act.UserPasswordMode.NONE);
					user.set_locked (false);
				} else {
					user.set_automatic_login (false);
					user.set_locked (true);
				}
			} else {
				debug ("Insuffienct permission to change lock state");
			}
		}

		private void change_user_type () {
			if (get_permission ().allowed) {
				if (user.get_account_type () == Act.UserAccountType.STANDARD && user_type_box.get_active () == 1)
					user.set_account_type (Act.UserAccountType.ADMINISTRATOR);
				else if (user.get_account_type () == Act.UserAccountType.ADMINISTRATOR && user_type_box.get_active () == 0 && !is_last_admin (user))
					user.set_account_type (Act.UserAccountType.STANDARD);
				else
					update_ui ();
			}
		}

		private void change_autologin () {
			if (get_permission ().allowed) {
				if (user.get_automatic_login () && !autologin_switch.get_active ()) {
					user.set_automatic_login (false);
				} else if (!user.get_automatic_login () && autologin_switch.get_active ()) {
					foreach (Act.User temp_user in get_usermanager ().list_users ()) {
						if (temp_user.get_automatic_login () && temp_user != user)
							temp_user.set_automatic_login (false);
					}
					user.set_automatic_login (true);
				}
			}
		}

		private void change_password (PassChangeType _type, string? _new_password) {

		}
	}
}
