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
	public class ListFooter : Gtk.Toolbar {
		public Gtk.ToolButton button_add;
		public Gtk.ToolButton button_remove;

		public ListFooter () {
			get_permission ().notify["allowed"].connect (update_ui);
			build_ui ();
		}

		private void build_ui () {
			set_style (Gtk.ToolbarStyle.ICONS);
        	get_style_context ().add_class ("inline-toolbar");
			get_style_context ().add_class (Gtk.STYLE_CLASS_INLINE_TOOLBAR);
			get_style_context ().set_junction_sides (Gtk.JunctionSides.TOP);
			set_icon_size (Gtk.IconSize.SMALL_TOOLBAR);
			set_show_arrow (false);
			hexpand = true;

			button_add = new Gtk.ToolButton (null, _("Create user account"));
			button_add.set_tooltip_text (_("Create user account"));
			button_add.set_icon_name ("list-add-symbolic");
			button_add.set_sensitive (false);
			button_add.clicked.connect (show_new_user_dialog);
			insert (button_add, -1);

			button_remove = new Gtk.ToolButton (null, _("Mark user account for removal"));
			button_remove.set_tooltip_text (_("Mark user account for removal"));
			button_remove.set_icon_name ("list-remove-symbolic");
			button_remove.set_sensitive (false);
			insert (button_remove, -1);

			show_all ();
		}

		private void update_ui () {
			if (permission.allowed) {
				button_add.set_sensitive (true);
				button_remove.set_sensitive (true);
			}
		}

		private void show_new_user_dialog () {
			Dialogs.NewUserDialog new_user_d = new Dialogs.NewUserDialog ();
			new_user_d.show ();
		}
	}
}
