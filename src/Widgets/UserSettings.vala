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

		private Gtk.Image avatar;
		private Gdk.Pixbuf? avatar_pixbuf;
		private Gtk.Entry full_name_entry;
		private Gtk.Button new_password_button;
		private Gtk.ComboBoxText user_type_box;
		private Gtk.ComboBoxText language_box;
		private Gtk.Box box;

		public UserSettings (Act.User user) {
			this.user = user;
			this.build_ui ();
		}
		
		public void build_ui () {
			this.margin = 40;
			this.row_spacing = 10;
			this.column_spacing = 20;
			this.set_valign (Gtk.Align.START);
			this.set_halign (Gtk.Align.CENTER);

			box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
			attach (box, 1, 0, 1, 1);

			full_name_entry = new Gtk.Entry ();
			full_name_entry.set_sensitive (false);
			box.pack_start (full_name_entry, false, false, 10);

			user_type_box = new Gtk.ComboBoxText ();
			user_type_box.append_text (_("Administrator"));
			user_type_box.append_text (_("User"));
			box.pack_end (user_type_box, false, false, 10);

			Gtk.Label lang_label = new Gtk.Label (_("Language:"));
			//lang_label.get_style_context ().add_class ("h3");
			lang_label.halign = Gtk.Align.END;
			attach (lang_label, 0, 2, 1, 1);

			language_box = new Gtk.ComboBoxText ();
			language_box.append_text (_("German"));
			language_box.append_text (_("English"));
			attach (language_box, 1, 2, 1, 1);

			Gtk.Label login_label = new Gtk.Label (_("Log In automatically:"));
			//login_label.get_style_context ().add_class ("h3");
			login_label.halign = Gtk.Align.END;
			login_label.margin_top = 30;
			attach (login_label, 0, 4, 1, 1);

			new_password_button = new Gtk.Button.with_label (_("Set new password"));
			new_password_button.set_sensitive (false);
			attach (new_password_button, 1, 5, 1, 1);

			update_ui ();
		}
		
		public void update_ui () {
			try {
				avatar_pixbuf = new Gdk.Pixbuf.from_file_at_scale (user.get_icon_file (), 64, 64, true);
				avatar = new Gtk.Image.from_pixbuf (avatar_pixbuf);
			} catch (Error e) {
				Gtk.IconTheme icon_theme = Gtk.IconTheme.get_default ();
				try {
					avatar_pixbuf = icon_theme.load_icon ("image-loading", 64, 0);
					avatar = new Gtk.Image.from_pixbuf (avatar_pixbuf);
				} catch (Error e) { }
			}
			avatar.halign = Gtk.Align.END;
			attach (avatar, 0, 0, 1, 1);

			full_name_entry.set_text (user.get_real_name ());

			if (user.get_account_type () == Act.UserAccountType.ADMINISTRATOR)
				user_type_box.set_active (0);
			else
				user_type_box.set_active (1);

			language_box.set_active (0);
			show_all ();
		}
	}
}
