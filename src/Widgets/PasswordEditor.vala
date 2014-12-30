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
namespace SwitchboardPlugUserAccounts.Widgets {
	public class PasswordEditor : Gtk.Grid {
		private Gtk.Entry current_pw_entry;
		private Gtk.Entry new_pw_entry;
		private Gtk.Entry confirm_pw_entry;
		private Gtk.CheckButton show_pw_check;

		public bool is_valid = false;
		public signal void validation_changed ();

		public PasswordEditor () {
			build_ui ();
		}

		private void build_ui () {
			expand = true;
			row_spacing = 10;
			column_spacing = 10;
			halign = Gtk.Align.END;

			if (!get_permission ().allowed) {
				Gtk.Label current_pw_label = new Gtk.Label (_("Current password:"));
				current_pw_label.halign = Gtk.Align.END;
				attach (current_pw_label, 0, 0, 1, 1);

				current_pw_entry = new Gtk.Entry ();
				current_pw_entry.halign = Gtk.Align.START;
				current_pw_entry.set_visibility (false);
				current_pw_entry.set_sensitive (false);
				attach (current_pw_entry, 1, 0, 1, 1);
			}

			Gtk.Label new_pw_label = new Gtk.Label (_("Password:"));
			new_pw_label.halign = Gtk.Align.END;
			attach (new_pw_label, 0, 1, 1, 1);

			new_pw_entry = new Gtk.Entry ();
			new_pw_entry.halign = Gtk.Align.START;
			new_pw_entry.set_visibility (false);
			new_pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "dialog-error-symbolic");
			new_pw_entry.set_icon_tooltip_text (Gtk.EntryIconPosition.SECONDARY, _("Password cannot be empty"));
			new_pw_entry.changed.connect (compare_passwords);
			attach (new_pw_entry, 1, 1, 1, 1);

			Gtk.Label confirm_pw_label = new Gtk.Label (_("Confirm:"));
			confirm_pw_label.halign = Gtk.Align.END;
			attach (confirm_pw_label, 0, 2, 1, 1);

			confirm_pw_entry = new Gtk.Entry ();
			confirm_pw_entry.halign = Gtk.Align.START;
			confirm_pw_entry.set_visibility (false);
			confirm_pw_entry.set_icon_tooltip_text (Gtk.EntryIconPosition.SECONDARY, _("Passwords do not match"));
			confirm_pw_entry.changed.connect (compare_passwords);
			attach (confirm_pw_entry, 1, 2, 1, 1);

			show_pw_check = new Gtk.CheckButton.with_label ("Show passwords");
			show_pw_check.clicked.connect (() => {
				if (show_pw_check.get_active ()) {
					new_pw_entry.set_visibility (true);
					confirm_pw_entry.set_visibility (true);
				} else {
					new_pw_entry.set_visibility (false);
					confirm_pw_entry.set_visibility (false);
				}
			});
			attach (show_pw_check, 1, 3, 1, 1);

			show_all ();
		}

		private void compare_passwords () {
			if (new_pw_entry.get_text () == confirm_pw_entry.get_text () && new_pw_entry.get_text () != "") {
				is_valid = true;
				new_pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, null);
				confirm_pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, null);
			} else {
				is_valid = false;

				if (new_pw_entry.get_text () != confirm_pw_entry.get_text ())
					confirm_pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "dialog-error-symbolic");
				else
					confirm_pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, null);

				if (new_pw_entry.get_text () == "")
					new_pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "dialog-error-symbolic");
				else
					new_pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, null);
			}
			validation_changed ();
		}

		public string? get_password () {
			if (is_valid)
				return new_pw_entry.get_text ();
			else
				return null;
		}

		public void reset () {
			new_pw_entry.set_text ("");
			confirm_pw_entry.set_text ("");
		}
	}
}
