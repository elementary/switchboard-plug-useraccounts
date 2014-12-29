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
	public class PasswordDialog : Gtk.Dialog {
		private Gtk.Grid main_grid;
		private Gtk.ComboBoxText action_combobox;

		private Gtk.Widget button_change;
		private Gtk.Widget button_cancel;

		private unowned Act.User user;

		private const string new_password = _("Set new password");
		private const string no_password = _("Set no password for login");

		public signal void request_password_change (PassChangeType type, string? new_password);

		public PasswordDialog (Act.User _user) {
			user = _user;
			set_size_request (500, 0);
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
			main_grid.halign = Gtk.Align.CENTER;
			content.add (main_grid);

			var action_label = new Gtk.Label (_("Action:"));
			action_label.halign = Gtk.Align.END;
			main_grid.attach (action_label, 0, 0, 1, 1);

			action_combobox = new Gtk.ComboBoxText ();
			action_combobox.halign = Gtk.Align.START;
			action_combobox.append_text (new_password);
			action_combobox.append_text (no_password);
			action_combobox.set_active (0);
			main_grid.attach (action_combobox, 1, 0, 1, 1);
		}
		
		public void build_buttons () {
			button_cancel = add_button (_("Cancel"), Gtk.ResponseType.CLOSE);
			button_change = add_button (_("Change password"), Gtk.ResponseType.OK);
			button_change.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
			this.response.connect (on_response);
		}


		private void on_response (Gtk.Dialog source, int response_id) {
			if (response_id == Gtk.ResponseType.OK) {
				switch (action_combobox.get_active_text ()) {
					case new_password:
						//request_password_change (PassChangeType.NEW_PASSWORD, new_password_entry.get_text ());
						break;
					case no_password:
						request_password_change (PassChangeType.NO_PASSWORD, null);
						break;
					default: break;
				}
			}
			hide ();
			destroy ();
		}
	}
}
