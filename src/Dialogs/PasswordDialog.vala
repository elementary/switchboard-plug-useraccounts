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
		private Gtk.Revealer pw_revealer;
		private Widgets.PasswordEditor pw_editor;
		private Gtk.Widget button_change;
		private Gtk.Widget button_cancel;

		private unowned Act.User user;
		public signal void request_password_change (Act.UserPasswordMode _mode, string? _new_password);

		public PasswordDialog (Act.User _user) {
			user = _user;
			set_size_request (475, 0);
			set_resizable (false);
			set_deletable (false);
			set_modal (true);

			build_ui ();
			build_buttons ();
			show_all ();
		}
		
		public void build_ui () {
			var content = get_content_area () as Gtk.Box;
			get_action_area ().margin = 6;
			main_grid = new Gtk.Grid ();
			main_grid.expand = true;
			main_grid.margin = 12;
			main_grid.row_spacing = 10;
			main_grid.column_spacing = 20;
			main_grid.halign = Gtk.Align.END;
			content.add (main_grid);

			pw_editor = new Widgets.PasswordEditor ();
			pw_editor.validation_changed.connect (() => {
				if (pw_editor.is_valid)
					button_change.set_sensitive (true);
				else
					button_change.set_sensitive (false);
			});

			pw_revealer = new Gtk.Revealer ();
			pw_revealer.add (pw_editor);
			pw_revealer.set_transition_duration (250);
			pw_revealer.set_reveal_child (true);
			main_grid.attach (pw_revealer, 0, 1, 2, 1);
		}
		
		public void build_buttons () {
			button_cancel = add_button (_("Cancel"), Gtk.ResponseType.CLOSE);
			button_change = add_button (_("Change Password"), Gtk.ResponseType.OK);
			button_change.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
			button_change.set_sensitive (false);
			this.response.connect (on_response);
		}


		private void on_response (Gtk.Dialog source, int response_id) {
			if (response_id == Gtk.ResponseType.OK && pw_editor.is_valid)
				request_password_change (Act.UserPasswordMode.REGULAR, pw_editor.get_password ());

			hide ();
			destroy ();
		}
	}
}var content = get_content_area () as Gtk.Box;
			content.margin = 0;
			get_action_area ().margin = 6;
			main_grid = new Gtk.Grid ();
			main_grid.expand = true;
			main_grid.margin = 12;
			main_grid.row_spacing = 10;
			main_grid.column_spacing = 20;
			main_grid.halign = Gtk.Align.END;
			content.add (main_grid);
