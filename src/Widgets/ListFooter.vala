/***
Copyright (C) 2014-2015 Marvin Beckers
This program is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License version 3, as published
by the Free Software Foundation.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranties of
MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along
with this program. If not, see http://www.gnu.org/licenses/.
***/

namespace SwitchboardPlugUserAccounts.Widgets {
	public class ListFooter : Gtk.Toolbar {
		private Gtk.ToolButton button_add;
		private Gtk.ToolButton button_remove;
		private Gtk.ToolButton button_undo;

		public Dialogs.NewUserDialog new_user_d;
		private Act.User? selected_user = null;

		public signal void removal_changed ();

		public ListFooter () {
			get_permission ().notify["allowed"].connect (update_ui);
			get_usermanager ().user_removed.connect (update_ui);
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

			button_remove = new Gtk.ToolButton (null, _("Remove user account and its data"));
			button_remove.set_tooltip_text (_("Remove user account and its data"));
			button_remove.set_icon_name ("list-remove-symbolic");
			button_remove.set_sensitive (false);
			button_remove.clicked.connect (mark_user_removal);
			insert (button_remove, -1);

			var separator = new Gtk.SeparatorToolItem ();
			separator.set_draw (false);
			separator.set_expand (true);
			insert (separator, -1);

			button_undo = new Gtk.ToolButton (null, _("Undo last user account removal"));
			button_undo.set_tooltip_text (_("Undo last user account removal"));
			button_undo.set_icon_name ("edit-undo-symbolic");
			button_undo.set_no_show_all (true);
			button_undo.clicked.connect (() => {
				undo_removal ();
				removal_changed ();
				update_ui ();
			});
			insert (button_undo, -1);

			update_ui ();
		}

		private void update_ui () {
			if (get_permission ().allowed) {
				button_add.set_sensitive (true);
				if (selected_user != null && selected_user != get_current_user () && !is_last_admin (selected_user) && !selected_user.get_automatic_login ()) {
					button_remove.set_sensitive (true);
					button_remove.set_tooltip_text (_("Remove user account and its data"));
				} else {
					button_remove.set_sensitive (false);
					if (selected_user != null)
						button_remove.set_tooltip_text (_("You cannot remove your own user account"));
					else
						button_remove.set_tooltip_text ("");
				}

				if (get_removal_list () == null || get_removal_list ().last () == null) {
					button_undo.set_no_show_all (true);
					button_undo.hide ();
				} else if (get_removal_list () != null && get_removal_list ().last () != null)
					button_undo.set_no_show_all (false);
			} else {
				button_remove.set_sensitive (false);
				button_add.set_sensitive (false);
			}
			show_all ();
		}

		public void set_selected_user (Act.User? _user) {
			selected_user =_user;
			if (selected_user != null)
				selected_user.changed.connect (update_ui);
			update_ui ();
		}

		private void mark_user_removal () {
			mark_removal (selected_user);
			removal_changed ();
			update_ui ();
		}

		private void show_new_user_dialog () {
			new_user_d = new Dialogs.NewUserDialog ();
			new_user_d.show ();
			new_user_d.request_user_creation.connect (create_new_user);
		}
	}
}
