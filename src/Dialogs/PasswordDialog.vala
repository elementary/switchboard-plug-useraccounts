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
		DISABLE_USER,
		ENABLE_USER
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
		private Gtk.CheckButton show_password_checkbutton;
		private Gtk.Entry current_password_entry;
		private Gtk.Entry current_password_entry_nopw;
		private Gtk.Entry new_password_entry;
		private Gtk.Entry confirm_password_entry;

		private Gtk.Widget button_change;
		private Gtk.Widget button_cancel;

		private unowned Polkit.Permission permission;
		private unowned bool is_current_user;
		private unowned bool enable;

		private const string new_password = _("Set New Password");
		private const string no_password = _("Set no Password for Login");
		private const string disable_user = _("Disable User Account");
		private const string enable_user =_("Enable User Account");

		public signal void request_password_change (PassChangeType type, string? new_password);

		public PasswordDialog (Polkit.Permission _permission, bool _is_current_user, bool _enable = false) {
			permission = _permission;
			is_current_user = _is_current_user;
			enable = _enable;
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
			content.add (main_grid);

			header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);
			header_box.hexpand = true;
			header_box.halign = Gtk.Align.CENTER;
			header_box.margin_bottom = 20;
			main_grid.attach (header_box, 0, 0, 2, 1);

			header_image = new Gtk.Image.from_icon_name ("channel-secure-symbolic", Gtk.IconSize.DND);
			header_box.pack_start (header_image);

			var header_label = new Gtk.Label (_("Change Password"));
			header_label.get_style_context ().add_class ("h2");
			header_box.pack_start (header_label);

			action_combobox = new Gtk.ComboBoxText ();
			action_combobox.halign = Gtk.Align.CENTER;

			main_grid.attach (action_combobox, 0, 1, 2, 1);
			if (!enable)
				build_ui_change ();
			else
				build_ui_enable ();
		}

		public void build_ui_enable () {
			action_combobox.append_text (_("Enable User Account"));
			action_combobox.set_active (0);
		}

		public void build_ui_change () {
			content_stack = new Gtk.Stack ();
			content_stack.set_transition_type (Gtk.StackTransitionType.SLIDE_UP_DOWN);
			main_grid.attach (content_stack, 0, 2, 2, 1);

			action_combobox.append_text (new_password);
			action_combobox.append_text (no_password);
			if (is_current_user == false)
				action_combobox.append_text (disable_user);
			action_combobox.set_active (0);

			action_combobox.changed.connect (() => {
				switch (action_combobox.get_active ()) {
					case 0:
						content_stack.set_visible_child_name ("new_password");
						current_password_entry.set_text ("");
						new_password_entry.set_text ("");
						confirm_password_entry.set_text ("");
						button_change.set_sensitive (true);
						content_grid_1.show_all ();
						content_grid_2.hide ();
						content_grid_3.hide ();
						break;
					case 1:
						content_stack.set_visible_child_name ("no_password");
						current_password_entry_nopw.set_text ("");
						button_change.set_sensitive (true);
						content_grid_1.hide ();
						content_grid_2.show_all ();
						content_grid_3.hide ();
						break;
					case 2:
						content_stack.set_visible_child_name ("deactivate_user");
						button_change.set_sensitive (true);
						content_grid_1.hide ();
						content_grid_2.hide ();
						content_grid_3.show_all ();
						break;
					default: break;
				}
			});

			content_grid_1 = new Gtk.Grid ();
			content_grid_1.expand = true;
			content_grid_1.halign = Gtk.Align.CENTER;
			content_grid_1.margin = 10;
			content_grid_1.margin_start = 0;
			content_grid_1.row_spacing = 10;
			content_grid_1.column_spacing = 20;

			content_grid_2 = new Gtk.Grid ();
			content_grid_2.expand = true;
			content_grid_2.halign = Gtk.Align.CENTER;
			content_grid_2.margin = 10;
			content_grid_2.margin_start = 0;
			content_grid_2.row_spacing = 10;
			content_grid_2.column_spacing = 20;

			content_grid_3 = new Gtk.Grid ();
			content_grid_3.expand = true;
			content_grid_3.halign = Gtk.Align.CENTER;
			content_grid_3.margin = 10;
			content_grid_3.margin_start = 0;
			content_grid_3.row_spacing = 10;
			content_grid_3.column_spacing = 20;

			content_stack.add_named (content_grid_1, "new_password");
			content_stack.add_named (content_grid_2, "no_password");
			content_stack.add_named (content_grid_3, "disable_user");

			var current_password_label = new Gtk.Label (_("Current Password:"));
			current_password_label.halign = Gtk.Align.END;
			content_grid_1.attach (current_password_label, 0, 0, 1, 1);
			current_password_entry = new Gtk.Entry ();
			current_password_entry.halign = Gtk.Align.START;
			current_password_entry.set_visibility (false);
			content_grid_1.attach (current_password_entry, 1, 0, 1, 1);

			var new_password_label = new Gtk.Label (_("New Password:"));
			new_password_label.halign = Gtk.Align.END;
			content_grid_1.attach (new_password_label, 0, 1, 1, 1);
			new_password_entry = new Gtk.Entry ();
			new_password_entry.halign = Gtk.Align.START;
			new_password_entry.set_visibility (false);
			new_password_entry.changed.connect (check_entry);
			content_grid_1.attach (new_password_entry, 1, 1, 1, 1);

			var confirm_password_label = new Gtk.Label (_("Confirm new Password:"));
			confirm_password_label.halign = Gtk.Align.END;
			content_grid_1.attach (confirm_password_label, 0, 2, 1, 1);
			confirm_password_entry = new Gtk.Entry ();
			confirm_password_entry.halign = Gtk.Align.START;
			confirm_password_entry.set_visibility (false);
			confirm_password_entry.set_icon_tooltip_text (Gtk.EntryIconPosition.SECONDARY, _("The new password does not match"));
			confirm_password_entry.changed.connect (check_entry);
			content_grid_1.attach (confirm_password_entry, 1, 2, 1, 1);

			show_password_checkbutton = new Gtk.CheckButton.with_label (_("Show new Passwords"));
			show_password_checkbutton.halign = Gtk.Align.END;
			show_password_checkbutton.toggled.connect (() => {
				if (show_password_checkbutton.get_active ()) {
					new_password_entry.set_visibility (true);
					confirm_password_entry.set_visibility (true);
				} else {
					new_password_entry.set_visibility (false);
					confirm_password_entry.set_visibility (false);
				}
			});
			content_grid_1.attach (show_password_checkbutton, 0, 3, 2, 1);

			var current_password_label_nopw = new Gtk.Label (_("Current Password:"));
			current_password_label_nopw.halign = Gtk.Align.END;
			content_grid_2.attach (current_password_label_nopw, 0, 0, 1, 1);
			current_password_entry_nopw = new Gtk.Entry ();
			current_password_entry_nopw.halign = Gtk.Align.START;
			current_password_entry_nopw.set_visibility (false);
			content_grid_2.attach (current_password_entry_nopw, 1, 0, 1, 1);

			content_stack.set_visible_child_name ("new_password");
			content_grid_1.show_all ();

			if (permission.allowed) {
				current_password_entry.set_sensitive (false);
				current_password_entry_nopw.set_sensitive (false);
			}
		}
		
		public void build_buttons () {
			button_cancel = add_button (_("Cancel"), Gtk.ResponseType.CLOSE);
			button_change = add_button (_("Apply Changes"), Gtk.ResponseType.OK);
			button_change.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
			this.response.connect (on_response);
		}

		private void check_entry () {
			if (new_password_entry.get_text () == confirm_password_entry.get_text ()) {
				button_change.set_sensitive (true);
				confirm_password_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, null);
			} else {
				button_change.set_sensitive (false);
				confirm_password_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "dialog-warning-symbolic");
			}
		}

		private void on_response (Gtk.Dialog source, int response_id) {
			if (response_id == Gtk.ResponseType.OK) {
				switch (action_combobox.get_active_text ()) {
					case new_password:
						request_password_change (PassChangeType.NEW_PASSWORD, new_password_entry.get_text ());
						break;
					case no_password:
						request_password_change (PassChangeType.NO_PASSWORD, null);
						break;
					case disable_user:
						request_password_change (PassChangeType.DISABLE_USER, null);
						break;
					case enable_user:
						request_password_change (PassChangeType.ENABLE_USER, null);
						break;
					default: break;
				}
			}
			hide ();
			destroy ();
		}
	}
}
