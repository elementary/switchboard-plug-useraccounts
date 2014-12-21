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
namespace SwitchboardPlugUsers {
	public enum PassChangeType {
		NEW_PASSWORD,
		NO_PASSWORD,
		DEACTIVATE_USER
	}
}

namespace SwitchboardPlugUsers.Dialogs {
	public class PasswordDialog : Gtk.Dialog {
		private Gtk.Grid main_grid;
		private Gtk.Grid content_grid_1;
		private Gtk.Grid content_grid_2;
		private Gtk.Grid content_grid_3;
		private Gtk.Box header_box;
		private Gtk.Image header_image;
		private Gtk.ComboBoxText action_combobox;

		private Gtk.Stack content_stack;
		private Gtk.Entry current_password_entry;
		private Gtk.Entry new_password_entry;
		private Gtk.Entry renew_password_entry;

		private Gtk.Widget button_change;
		private Gtk.Widget button_cancel;

		public signal void request_password_change (PassChangeType type, string? new_password);

		public PasswordDialog () {
			set_size_request (500, 450);
			set_resizable (false);
			build_ui ();
			build_buttons ();
			show_all ();
		}

		public void build_ui () {
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

			header_image = new Gtk.Image.from_icon_name ("channel-secure-symbolic", Gtk.IconSize.DND);
			header_box.pack_start (header_image);

			var header_label = new Gtk.Label (_("Set New Password"));
			header_label.get_style_context ().add_class ("h2");
			header_box.pack_start (header_label);

			/*var action_label = new Gtk.Label (_("Choose Action:"));
			action_label.halign = Gtk.Align.END;
			main_grid.attach (action_label, 0, 1, 1, 1);*/

			action_combobox = new Gtk.ComboBoxText ();
			action_combobox.halign = Gtk.Align.CENTER;
			action_combobox.append_text (_("Set New Password"));
			action_combobox.append_text (_("Set no Password for Login"));
			action_combobox.append_text (_("Deactivate User Account"));
			action_combobox.set_active (0);
			main_grid.attach (action_combobox, 0, 1, 2, 1);

			content_grid_1 = new Gtk.Grid ();
			content_grid_1.expand = true;
			content_grid_1.halign = Gtk.Align.CENTER;
			content_grid_1.margin = 10;
			content_grid_1.margin_start = 0;
			content_grid_1.row_spacing = 10;
			content_grid_1.column_spacing = 20;
			content_grid_2 = new Gtk.Grid ();
			content_grid_2.expand = true;
			content_grid_3 = new Gtk.Grid ();
			content_grid_3.expand = true;

			content_stack = new Gtk.Stack ();
			main_grid.attach (content_stack, 0, 2, 2, 1);
			content_stack.add_named (content_grid_1, "new_password");
			content_stack.add_named (content_grid_2, "no_password");
			content_stack.add_named (content_grid_3, "deactivate_user");
			content_stack.set_visible_child_name ("new_password");

			var current_password_label = new Gtk.Label (_("Current Password:"));
			current_password_label.halign = Gtk.Align.END;
			content_grid_1.attach (current_password_label, 0, 0, 1, 1);
			current_password_entry = new Gtk.Entry ();
			current_password_entry.halign = Gtk.Align.START;
			current_password_entry.set_size_request (160, 0);
			content_grid_1.attach (current_password_entry, 1, 0, 1, 1);

			content_grid_1.show_all ();
			content_grid_2.show_all ();
			content_grid_3.show_all ();

		}
		
		public void build_buttons () {
			button_cancel = add_button (_("Cancel"), Gtk.ResponseType.CLOSE);
			button_change = add_button (_("Change"), Gtk.ResponseType.OK);
			button_change.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
			this.response.connect (on_response);
		}

		private void on_response (Gtk.Dialog source, int response_id) {
			if (response_id == Gtk.ResponseType.OK) {
				
			}
			hide ();
			destroy ();
		}
	}
}
