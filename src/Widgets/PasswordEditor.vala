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
		private const string new_password = _("Set New Password");
		private const string no_password = _("Set no Password for Login");
		private const string disable_user = _("Disable User Account");

		private Gtk.ComboBoxText action_combobox;
		/*private Gtk.Stack content_stack;
		private Gtk.CheckButton show_password_checkbutton;
		private Gtk.Entry current_password_entry;
		private Gtk.Entry current_password_entry_nopw;
		private Gtk.Entry new_password_entry;
		private Gtk.Entry confirm_password_entry;
		private Gtk.Widget button_change;
		private Gtk.Widget button_cancel;*/

		public PasswordEditor () {
			build_ui ();
		}

		private void build_ui () {
			set_row_spacing (10);
			set_column_spacing (20);
			set_valign (Gtk.Align.START);
			set_halign (Gtk.Align.CENTER);

			action_combobox = new Gtk.ComboBoxText ();
			action_combobox.halign = Gtk.Align.CENTER;
			action_combobox.append_text (new_password);
			action_combobox.append_text (no_password);
			attach (action_combobox, 0, 0, 2, 1);

			show_all ();
		}
	}
}
