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

namespace SwitchboardPlugUserAccounts.Dialogs {
	public class NewUserDialog : Gtk.Dialog {
		private Gtk.Grid main_grid;
		private Gtk.Box header_box;
		private Gtk.Image header_image;
		private Gtk.Entry fullname_entry;
		private Gtk.ComboBoxText username_combobox;
		private Gtk.ComboBoxText accounttype_combobox;

		private Gtk.Widget button_create;
		private Gtk.Widget button_cancel;

		public signal void request_user_creation (string fullname, string username, int usertype);

		public NewUserDialog () {
			set_size_request (500, 425);
			set_resizable (false);
			build_ui ();
			build_buttons ();
			show_all ();
		}
		private void build_ui () {
			Gtk.Box content = get_content_area () as Gtk.Box;
			main_grid = new Gtk.Grid ();
			main_grid.expand = true;
			main_grid.margin = 10;
			main_grid.row_spacing = 10;
			main_grid.column_spacing = 20;
			content.add (main_grid);

			header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);
			header_box.hexpand = true;
			header_box.halign = Gtk.Align.CENTER;
			header_box.margin_bottom = 20;
			main_grid.attach (header_box, 0, 0, 2, 1);

			header_image = new Gtk.Image.from_icon_name ("system-users-symbolic", Gtk.IconSize.DND);
			header_box.pack_start (header_image);

			var header_label = new Gtk.Label (_("Create User Account"));
			header_label.get_style_context ().add_class ("h2");
			header_box.pack_start (header_label);

			var fullname_label = new Gtk.Label (_("Full Name:"));
			fullname_label.halign = Gtk.Align.END;
			main_grid.attach (fullname_label, 0, 1, 1, 1);

			fullname_entry = new Gtk.Entry ();
			fullname_entry.set_size_request (180, 0);
			fullname_entry.halign = Gtk.Align.START;
			fullname_entry.set_size_request (50, 0);
			main_grid.attach (fullname_entry, 1, 1, 1, 1);

			var username_label = new Gtk.Label (_("User Name:"));
			username_label.halign = Gtk.Align.END;
			main_grid.attach (username_label, 0, 2, 1, 1);

			username_combobox = new Gtk.ComboBoxText.with_entry ();
			//username_combobox.set_size_request (160, 0);
			username_combobox.get_child ().set_size_request (50, 0);
			username_combobox.halign = Gtk.Align.START;
			main_grid.attach (username_combobox, 1, 2, 1, 1);

			var accounttype_label = new Gtk.Label (_("Account Type:"));
			accounttype_label.halign = Gtk.Align.END;
			main_grid.attach (accounttype_label, 0, 3, 1, 1);

			accounttype_combobox = new Gtk.ComboBoxText ();
			accounttype_combobox.set_size_request (160, 0);
			accounttype_combobox.halign = Gtk.Align.START;
			accounttype_combobox.append_text (_("Administrator"));
			accounttype_combobox.append_text (_("User"));
			accounttype_combobox.set_active (1);
			main_grid.attach (accounttype_combobox, 1, 3, 1, 1);
		}

		private void build_buttons () {
			button_cancel = add_button (_("Cancel"), Gtk.ResponseType.CLOSE);
			button_create = add_button (_("Create User"), Gtk.ResponseType.OK);
			button_create.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
			this.response.connect (on_response);
		}

		private void on_response (Gtk.Dialog source, int response_id) {
			if (response_id == Gtk.ResponseType.OK) {
				string fullname = fullname_entry.get_text ();
				string username = username_combobox.get_active_text ();
				int accounttype = 0;
				if (accounttype_combobox.get_active () == 0)
					accounttype = 1;
				request_user_creation (fullname, username, accounttype);
			}
			hide ();
			destroy ();
		}
	}
}
