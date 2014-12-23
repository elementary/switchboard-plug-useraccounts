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
		private bool is_current_user;

		private Gtk.Image avatar;
		private Gdk.Pixbuf? avatar_pixbuf;
		private Gtk.Entry full_name_entry;
		private Gtk.Button change_password_button;
		private Gtk.ComboBoxText user_type_box;
		private Gtk.ComboBoxText language_box;
		private Gtk.Switch autologin_switch;
		private Gtk.Grid header_grid;

		/*
		//lock widgets
		private Gtk.Image full_name_lock = new Gtk.Image.from_icon_name ("changes-prevent-symbolic", Gtk.IconSize.BUTTON);
		private Gtk.Image user_type_lock = new Gtk.Image.from_icon_name ("changes-prevent-symbolic", Gtk.IconSize.BUTTON);
		private Gtk.Image language_lock = new Gtk.Image.from_icon_name ("changes-prevent-symbolic", Gtk.IconSize.BUTTON);
		private Gtk.Image autologin_lock = new Gtk.Image.from_icon_name ("changes-prevent-symbolic", Gtk.IconSize.BUTTON);
		*/
	
		public UserSettings (Act.User _user, bool _is_current_user) {
			user = _user;
			user.changed.connect (update_ui);
			is_current_user = _is_current_user;
			build_ui ();
		}
		
		public void build_ui () {
			margin = 20;
			set_row_spacing (7);
			set_column_spacing (20);
			set_valign (Gtk.Align.START);
			set_halign (Gtk.Align.CENTER);

			header_grid = new Gtk.Grid ();
			header_grid.margin_top = 20;
			header_grid.margin_bottom = 15;
			header_grid.set_row_spacing (15);
			header_grid.set_column_spacing (20);
			header_grid.expand = true;
			attach (header_grid, 1, 0, 1, 1);

			full_name_entry = new Gtk.Entry ();
			full_name_entry.set_size_request (50, 0);
			full_name_entry.activate.connect (change_full_name);
			header_grid.attach (full_name_entry, 0, 0, 1, 1);

			user_type_box = new Gtk.ComboBoxText ();
			user_type_box.append_text (_("Administrator"));
			user_type_box.append_text (_("User"));
			header_grid.attach (user_type_box, 0, 1, 1, 1);

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
			login_label.margin_top = 30;
			attach (login_label, 0, 3, 1, 1);

			autologin_switch = new Gtk.Switch ();
			autologin_switch.hexpand = true;
			autologin_switch.halign = Gtk.Align.START;
			autologin_switch.margin_top = 30;
			attach (autologin_switch, 1, 3, 1, 1);

			change_password_button = new Gtk.Button ();
			change_password_button.margin_top = 7;
			change_password_button.clicked.connect (show_password_dialog);
			attach (change_password_button, 1, 4, 1, 1);

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

			if (is_current_user || get_permission ().allowed) {
				full_name_entry.set_sensitive (true);
				language_box.set_sensitive (true);
				change_password_button.set_sensitive (true);

				if (get_permission ().allowed) {
					autologin_switch.set_sensitive (true);
					user_type_box.set_sensitive (true);
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
				user_type_box.set_active (0);
			else
				user_type_box.set_active (1);

			//set change_password_button's label according to lock state
			if (user.get_locked ())
				change_password_button.set_label (_("Activate user"));
			else
				change_password_button.set_label (_("Change password"));

			//set autologin_switch according to autologin
			if (user.get_automatic_login ())
				autologin_switch.set_active (true);
			else
				autologin_switch.set_active (false);

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

		public void show_password_dialog () {
			Dialogs.PasswordDialog password_dialog = new Dialogs.PasswordDialog (is_current_user, user.get_locked ());
			password_dialog.show ();
		}

		public void change_full_name () {
			string new_full_name = full_name_entry.get_text ();
			if (new_full_name != user.get_real_name ()) {
				if (is_current_user || get_permission ().allowed) {
					warning ("changed username");
					user.set_real_name (new_full_name);
				} else {
					warning ("Insuffienct permissions to change name");
					update_ui ();
				}
			}
		}

		public void change_lang () {
			string new_lang = language_box.get_active_text ();
			if (new_lang != user.get_language ()) {
				if (is_current_user || get_permission ().allowed) {
					warning ("changed lang");
					user.set_language (new_lang);
				} else {
					warning ("Insuffienct permissions to change lang");
					update_ui ();
				}
			}
		}
	}
}
