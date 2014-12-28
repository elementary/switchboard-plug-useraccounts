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
		private Gtk.Grid pw_grid;
		private Gtk.ComboBoxText accounttype_combobox;
		private Gtk.Entry fullname_entry;
		private Gtk.Entry username_entry;
		private Gtk.Entry new_pw_entry;
		private Gtk.Entry confirm_pw_entry;
		private Gtk.RadioButton option_nopw;
		private Gtk.RadioButton option_onlogin;
		private Gtk.RadioButton option_setpw;

		private Gtk.Widget button_create;
		private Gtk.Widget button_cancel;

		public signal void request_user_creation (string fullname, string username, Act.UserAccountType usertype, PassChangeType type, string? pw = null);

		public NewUserDialog () {
			set_size_request (500, 0);
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
			main_grid.column_spacing = 10;
			main_grid.halign = Gtk.Align.CENTER;
			content.add (main_grid);

			var accounttype_label = new Gtk.Label (_("Account Type:"));
			accounttype_label.halign = Gtk.Align.END;
			main_grid.attach (accounttype_label, 0, 0, 1, 1);

			accounttype_combobox = new Gtk.ComboBoxText ();
			accounttype_combobox.set_size_request (160, 0);
			accounttype_combobox.halign = Gtk.Align.START;
			accounttype_combobox.append_text (_("Standard"));
			accounttype_combobox.append_text (_("Administrator"));
			accounttype_combobox.set_active (0);
			main_grid.attach (accounttype_combobox, 1, 0, 1, 1);

			var fullname_label = new Gtk.Label (_("Full name:"));
			fullname_label.halign = Gtk.Align.END;
			main_grid.attach (fullname_label, 0, 1, 1, 1);

			fullname_entry = new Gtk.Entry ();
			fullname_entry.halign = Gtk.Align.START;
			fullname_entry.changed.connect (check_input);
			main_grid.attach (fullname_entry, 1, 1, 1, 1);

			var username_label = new Gtk.Label (_("User name:"));
			username_label.halign = Gtk.Align.END;
			main_grid.attach (username_label, 0, 2, 1, 1);

			username_entry = new Gtk.Entry ();
			username_entry.halign = Gtk.Align.START;
			username_entry.changed.connect (check_input);
			main_grid.attach (username_entry, 1, 2, 1, 1);

			option_nopw = new Gtk.RadioButton.with_label (null, _("Set no password for login"));
			option_onlogin = new Gtk.RadioButton.with_label_from_widget (option_nopw, _("Let user create password on first login"));
			option_setpw = new Gtk.RadioButton.with_label_from_widget (option_nopw, _("Set password now"));
			option_nopw.toggled.connect (toggled_pw);
			option_onlogin.toggled.connect (toggled_pw);
			option_setpw.toggled.connect (toggled_pw);
			main_grid.attach (option_nopw, 0, 3, 2, 1);
			//main_grid.attach (option_onlogin, 0, 4, 2, 1);
			main_grid.attach (option_setpw, 0, 5, 2, 1);

			pw_grid = new Gtk.Grid ();
			pw_grid.expand = true;
			pw_grid.row_spacing = 10;
			pw_grid.column_spacing = 10;
			pw_grid.halign = Gtk.Align.END;
			pw_grid.set_no_show_all (true);

			main_grid.attach (pw_grid, 0, 6, 2, 1);

			var new_pw_label = new Gtk.Label (_("Password:"));
			new_pw_label.halign = Gtk.Align.END;
			pw_grid.attach (new_pw_label, 0, 0, 1, 1);

			new_pw_entry = new Gtk.Entry ();
			new_pw_entry.halign = Gtk.Align.START;
			new_pw_entry.set_visibility (false);
			new_pw_entry.changed.connect (check_input);
			pw_grid.attach (new_pw_entry, 1, 0, 1, 1);

			var confirm_pw_label = new Gtk.Label (_("Confirm:"));
			confirm_pw_label.halign = Gtk.Align.END;
			pw_grid.attach (confirm_pw_label, 0, 1, 1, 1);

			confirm_pw_entry = new Gtk.Entry ();
			confirm_pw_entry.halign = Gtk.Align.START;
			confirm_pw_entry.set_visibility (false);
			confirm_pw_entry.changed.connect (check_input);
			confirm_pw_entry.set_icon_tooltip_text (Gtk.EntryIconPosition.SECONDARY, _("The password does not match"));
			pw_grid.attach (confirm_pw_entry, 1, 1, 1, 1);
		}

		private void build_buttons () {
			button_cancel = add_button (_("Cancel"), Gtk.ResponseType.CLOSE);
			button_create = add_button (_("Create User"), Gtk.ResponseType.OK);
			button_create.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
			button_create.set_sensitive (false);
			this.response.connect (on_response);
		}

		private void toggled_pw () {
			if (option_setpw.get_active ()) {
					pw_grid.set_no_show_all (false);
					//button_create.set_sensitive (false);
			} else {
					new_pw_entry.set_text ("");
					confirm_pw_entry.set_text ("");
					//button_create.set_sensitive (true);
					pw_grid.hide ();
					pw_grid.set_no_show_all (true);
			}
			check_input ();
			show_all ();
		}

		private void check_input () {
			if (fullname_entry.get_text() != "" && username_entry.get_text () != "") {
				if (option_setpw.get_active ()) {
					if (new_pw_entry.get_text () != "" && confirm_pw_entry.get_text () != ""
					&& new_pw_entry.get_text () == confirm_pw_entry.get_text ()) {
						button_create.set_sensitive (true);
						confirm_pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, null);
					} else {
						button_create.set_sensitive (false);
						confirm_pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "dialog-warning-symbolic");
					}
				} else
					button_create.set_sensitive (true);
			} else
				button_create.set_sensitive (false);
		}

		private void on_response (Gtk.Dialog source, int response_id) {
			if (response_id == Gtk.ResponseType.OK) {
				string fullname = fullname_entry.get_text ();
				string username = username_entry.get_text ();
				PassChangeType type = PassChangeType.NO_PASSWORD;
				string? pw = null;
				Act.UserAccountType accounttype = Act.UserAccountType.STANDARD;
				if (accounttype_combobox.get_active () == 1)
					accounttype = Act.UserAccountType.ADMINISTRATOR;
				if (option_setpw.get_active () && new_pw_entry.get_text () == confirm_pw_entry.get_text ()) {
					pw = new_pw_entry.get_text ();
					type = PassChangeType.NEW_PASSWORD;
				} else if (option_nopw.get_active ())
					type = PassChangeType.NO_PASSWORD;
				else if (option_onlogin.get_active ())
					type = PassChangeType.ON_LOGIN;

				request_user_creation (fullname, username, accounttype, type, pw);
			}
			hide ();
			destroy ();
		}
	}
}
