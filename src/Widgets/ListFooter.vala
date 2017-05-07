/*
* Copyright (c) 2014-2017 elementary LLC. (https://elementary.io)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*/

namespace SwitchboardPlugUserAccounts.Widgets {
    public class ListFooter : Gtk.Toolbar {
        private Gtk.ToolButton  button_add;
        private Gtk.ToolButton  button_remove;

        private Act.User? selected_user = null;

        public signal void removal_changed ();
        public signal void unfocused ();

        public signal void send_undo_notification ();
        public signal void hide_undo_notification ();

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
            button_add.clicked.connect (() => {
                Widgets.NewUserPopover new_user = new Widgets.NewUserPopover (button_add);
                new_user.show_all ();
                new_user.request_user_creation.connect (create_new_user);
            });
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
        }

        public void undo_user_removal () {
            undo_removal ();
            removal_changed ();
            update_ui ();
        }

        private void update_ui () {
            if (get_permission ().allowed) {
                button_add.set_sensitive (true);
                if (selected_user != null && selected_user != get_current_user ()
                && !is_last_admin (selected_user) && !selected_user.get_automatic_login ()) {
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
                    hide_undo_notification ();
                }
            } else if (selected_user == null) {
                button_remove.set_sensitive (false);
            } else {
                button_add.set_sensitive (false);
                button_remove.set_sensitive (false);
                hide_undo_notification ();
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
            debug ("Marking user %s for removal".printf (selected_user.get_user_name ()));
            mark_removal (selected_user);
            removal_changed ();
            selected_user = null;
            unfocused ();
            update_ui ();
            send_undo_notification ();
        }
    }
}
