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
		private Gtk.ComboBoxText accounttype_combobox;
		private Gtk.Entry fullname_entry;
		private Gtk.Entry username_entry;
		private Gtk.RadioButton option_nopw;
		private Gtk.RadioButton option_onlogin;
		private Gtk.RadioButton option_setpw;

		private Gtk.Revealer pw_revealer;
		private Widgets.PasswordEditor pw_editor;

		private Gtk.Widget button_create;
		private Gtk.Widget button_cancel;

		public signal void request_user_creation (string _fullname, string _username, Act.UserAccountType _usertype, Act.UserPasswordMode _mode, string? _pw = null);

		public NewUserDialog () {
			set_size_request (500, 0);
			set_resizable (false);
			build_ui ();
			build_buttons ();
			show_all ();
		}
		private void build_ui () {
			var content = get_content_area () as Gtk.Box;
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

			pw_editor = new Widgets.PasswordEditor ();
			pw_editor.validation_changed.connect (check_input);

			pw_revealer = new Gtk.Revealer ();
			pw_revealer.add (pw_editor);
			pw_revealer.set_transition_duration (250);
			pw_revealer.set_reveal_child (false);
			main_grid.attach (pw_revealer, 0, 6, 2, 1);

			show_all ();
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
					pw_editor.reset ();
					pw_revealer.set_reveal_child (true);
			} else {
					pw_revealer.set_reveal_child (false);
			}
			check_input ();
			show_all ();
		}
		
		private void check_input () {
			if (fullname_entry.get_text() != "" && username_entry.get_text () != "") {
				if (option_setpw.get_active ()) {
					if (pw_editor.is_valid)
						button_create.set_sensitive (true);
					else
						button_create.set_sensitive (false);
				} else
					button_create.set_sensitive (true);
			} else
				button_create.set_sensitive (false);
		}

		private void on_response (Gtk.Dialog source, int response_id) {
			if (response_id == Gtk.ResponseType.OK) {
				string fullname = fullname_entry.get_text ();
				string username = username_entry.get_text ();
				Act.UserPasswordMode mode = Act.UserPasswordMode.NONE;
				string? pw = null;
				Act.UserAccountType accounttype = Act.UserAccountType.STANDARD;
				if (accounttype_combobox.get_active () == 1)
					accounttype = Act.UserAccountType.ADMINISTRATOR;

				if (option_setpw.get_active () && pw_editor.is_valid) {
					pw = pw_editor.get_password ();
					mode = Act.UserPasswordMode.REGULAR;
				} else if (option_onlogin.get_active ())
					mode = Act.UserPasswordMode.SET_AT_LOGIN;

				request_user_creation (fullname, username, accounttype, mode, pw);
			}
			hide ();
			destroy ();
		}
	}
}
