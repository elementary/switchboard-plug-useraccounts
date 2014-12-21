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
		private unowned string[]? installed_lang;

		private Gtk.Image avatar;
		private Gdk.Pixbuf? avatar_pixbuf;
		private Gtk.Entry full_name_entry;
		private Gtk.Button new_password_button;
		private Gtk.ComboBoxText user_type_box;
		private Gtk.ComboBoxText language_box;
		private Gtk.Switch autologin_switch;
		private Gtk.Box box;


		public UserSettings (Act.User _user, string[]? _installed_lang) {
			user = _user;
			installed_lang = _installed_lang;
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
			box.pack_start (full_name_entry, false, false, 7);

			user_type_box = new Gtk.ComboBoxText ();
			user_type_box.append_text (_("Administrator"));
			user_type_box.append_text (_("User"));
			user_type_box.set_sensitive (false);
			box.pack_end (user_type_box, false, false, 7);

			Gtk.Label lang_label = new Gtk.Label (_("Language:"));
			lang_label.halign = Gtk.Align.END;
			attach (lang_label, 0, 2, 1, 1);

			language_box = new Gtk.ComboBoxText ();
			foreach (string s in installed_lang)
				language_box.append_text (s);
			language_box.set_sensitive (false);
			attach (language_box, 1, 2, 1, 1);

			Gtk.Label login_label = new Gtk.Label (_("Log In automatically:"));
			login_label.halign = Gtk.Align.END;
			login_label.margin_top = 30;
			attach (login_label, 0, 4, 1, 1);

			autologin_switch = new Gtk.Switch ();
			autologin_switch.hexpand = true;
			autologin_switch.halign = Gtk.Align.START;
			autologin_switch.margin_top = 30;
			autologin_switch.set_sensitive (false);
			attach (autologin_switch, 1, 4, 1, 1);

			new_password_button = new Gtk.Button ();
			new_password_button.set_sensitive (false);
			new_password_button.margin_top = 7;
			attach (new_password_button, 1, 5, 1, 1);

			update_ui ();
		}
		
		public void update_ui () {
			try {
				avatar_pixbuf = new Gdk.Pixbuf.from_file_at_scale (user.get_icon_file (), 72, 72, true);
				avatar = new Gtk.Image.from_pixbuf (avatar_pixbuf);
			} catch (Error e) {
				Gtk.IconTheme icon_theme = Gtk.IconTheme.get_default ();
				try {
					avatar_pixbuf = icon_theme.load_icon ("image-loading", 72, 0);
					avatar = new Gtk.Image.from_pixbuf (avatar_pixbuf);
				} catch (Error e) { }
			}
			avatar.halign = Gtk.Align.END;
			attach (avatar, 0, 0, 1, 1);

			full_name_entry.set_text (user.get_real_name ());

			//set user_type_box according to accounttype
			if (user.get_account_type () == Act.UserAccountType.ADMINISTRATOR)
				user_type_box.set_active (0);
			else
				user_type_box.set_active (1);

			//set new_password_button's label according to lock state
			if (user.get_locked ())
				new_password_button.set_label (_("Activate user"));
			else
				new_password_button.set_label (_("Set new password"));

			//set autologin_switch according to autologin
			if (user.get_automatic_login ())
				autologin_switch.set_active (true);
			else
				autologin_switch.set_active (false);

			int i = 0;
			foreach (string s in installed_lang) {
				if (user.get_language () == s) {
					language_box.set_active (i);
					break;
				}
				i++;
			}

			show_all ();
		}
	}
}
