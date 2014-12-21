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

namespace SwitchboardPlugUsers.Dialogs {
	public class NewUserDialog : Gtk.Dialog {
		private Gtk.Grid main_grid;
		private Gtk.Box header_box;
		private Gtk.Label header_label;
		private Gtk.Image header_image;
		private Gtk.Label realname_label;
		private Gtk.Entry realname_entry;
		private Gtk.Label username_label;
		private Gtk.ComboBoxText username_combobox;
		private Gtk.Label accounttype_label;
		private Gtk.ComboBoxText accounttype_combobox;

		public NewUserDialog () {
			set_size_request (500, 400);
			set_resizable (false);
			build_ui ();
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

			header_label = new Gtk.Label (_("Add User Account"));
			header_label.get_style_context ().add_class ("h2");
			header_box.pack_start (header_label);

			realname_label = new Gtk.Label (_("Full Name:"));
			realname_label.halign = Gtk.Align.END;
			main_grid.attach (realname_label, 0, 1, 1, 1);

			realname_entry = new Gtk.Entry ();
			realname_entry.halign = Gtk.Align.START;
			realname_entry.set_size_request (50, 0);
			main_grid.attach (realname_entry, 1, 1, 1, 1);

			username_label = new Gtk.Label (_("User Name:"));
			username_label.halign = Gtk.Align.END;
			main_grid.attach (username_label, 0, 2, 1, 1);

			username_combobox = new Gtk.ComboBoxText.with_entry ();
			username_combobox.halign = Gtk.Align.START;
			main_grid.attach (username_combobox, 1, 2, 1, 1);

			accounttype_label = new Gtk.Label (_("Account Type:"));
			accounttype_label.halign = Gtk.Align.END;
			main_grid.attach (accounttype_label, 0, 3, 1, 1);

			accounttype_combobox = new Gtk.ComboBoxText ();
			accounttype_combobox.halign = Gtk.Align.START;
			accounttype_combobox.append_text (_("Administrator"));
			accounttype_combobox.append_text (_("User"));
			accounttype_combobox.set_active (1);
			main_grid.attach (accounttype_combobox, 1, 3, 1, 1);

			show_all ();
		}
	}
}
