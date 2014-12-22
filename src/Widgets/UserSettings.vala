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
	public class UserSettings : Gtk.Grid {
		private Act.User user;
		private unowned Act.User current_user;
		private unowned string[]? installed_lang;

		private Gtk.Image avatar;
		private Gdk.Pixbuf? avatar_pixbuf;
		private Gtk.Entry full_name_entry;
		private Gtk.Button change_password_button;
		private Gtk.ComboBoxText user_type_box;
		private Gtk.Switch autologin_switch;
		private Gtk.Box box;

		private unowned Polkit.Permission permission;

		public UserSettings (Act.User _user, Act.User _current_user, string[]? _installed_lang, Polkit.Permission _permission) {
			user = _user;
			user.changed.connect (update_ui);
			current_user = _current_user;
			installed_lang = _installed_lang;
			permission = _permission;
			build_ui ();
		}
		
		public void build_ui () {
			margin = 20;
			set_row_spacing (7);
			set_column_spacing (20);
			set_valign (Gtk.Align.START);
			set_halign (Gtk.Align.CENTER);

			box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
			attach (box, 1, 0, 1, 1);

			full_name_entry = new Gtk.Entry ();
			full_name_entry.set_sensitive (false);
			full_name_entry.activate.connect (change_full_name);
			box.pack_start (full_name_entry, false, false, 7);

			user_type_box = new Gtk.ComboBoxText ();
			user_type_box.append_text (_("Administrator"));
			user_type_box.append_text (_("User"));
			user_type_box.set_sensitive (false);
			box.pack_end (user_type_box, false, false, 7);


			Gtk.Label login_label = new Gtk.Label (_("Log In automatically:"));
			login_label.halign = Gtk.Align.END;
			login_label.margin_top = 30;
			attach (login_label, 0, 2, 1, 1);

			autologin_switch = new Gtk.Switch ();
			autologin_switch.hexpand = true;
			autologin_switch.halign = Gtk.Align.START;
			autologin_switch.margin_top = 30;
			autologin_switch.set_sensitive (false);
			attach (autologin_switch, 1, 2, 1, 1);

			change_password_button = new Gtk.Button ();
			change_password_button.margin_top = 7;
			change_password_button.set_sensitive (false);
			change_password_button.clicked.connect (show_password_dialog);
			attach (change_password_button, 1, 3, 1, 1);

			update_ui ();
			attach (avatar, 0, 0, 1, 1);

			permission.notify["allowed"].connect (update_ui);
		}
		
		public void update_ui () {
			if (current_user == user || permission.allowed) {
				full_name_entry.set_sensitive (true);
				user_type_box.set_sensitive (true);
				change_password_button.set_sensitive (true);
			}
			if (permission.allowed)
				autologin_switch.set_sensitive (true);

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

			show_all ();
		}

		public void show_password_dialog () {
			Dialogs.PasswordDialog password_dialog = new Dialogs.PasswordDialog (permission, (user == current_user), user.get_locked ());
			password_dialog.show ();
		}

		public void change_full_name () {
			if (user == current_user || permission.allowed) {
				string new_full_name = full_name_entry.get_text ();
				user.set_real_name (new_full_name);
			} else {
				warning ("Insuffienct permissions to change name");
				update_ui ();
			}
		}
	}
}
