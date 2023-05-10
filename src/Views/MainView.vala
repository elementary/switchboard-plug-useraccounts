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
    public class MainView : Gtk.Paned {
        private UserListBox userlist;
        private Granite.Widgets.Toast toast;
        private Gtk.Stack content;
        private Gtk.ScrolledWindow scrolled_window;
        private GuestSettingsView guest;

        public MainView () {
            Object (
                orientation: Gtk.Orientation.HORIZONTAL,
                position: 240
            );
        }

        construct {
            scrolled_window = new Gtk.ScrolledWindow (null, null);
            scrolled_window.expand = true;
            scrolled_window.hscrollbar_policy = Gtk.PolicyType.NEVER;

            var button_add = new Gtk.Button.with_label ("Create user account…") {
                always_show_image = true,
                image = new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.SMALL_TOOLBAR),
                margin_top = 3,
                margin_bottom = 3
            };
            button_add.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

            var actionbar = new Gtk.ActionBar ();
            actionbar.get_style_context ().add_class (Gtk.STYLE_CLASS_INLINE_TOOLBAR);
            actionbar.add (button_add);

            var sidebar = new Gtk.Grid ();
            sidebar.orientation = Gtk.Orientation.VERTICAL;
            sidebar.add (scrolled_window);
            sidebar.add (actionbar);

            guest = new GuestSettingsView ();

            content = new Gtk.Stack ();
            content.add_named (guest, "guest_session");

            toast = new Granite.Widgets.Toast ("");
            toast.set_default_action (_("Undo"));

            var overlay = new Gtk.Overlay ();
            overlay.add (content);
            overlay.add_overlay (toast);

            pack1 (sidebar, false, false);
            pack2 (overlay, true, false);

            get_usermanager ().notify["is-loaded"].connect (update);

            if (get_usermanager ().is_loaded) {
                update ();
            }

            button_add.clicked.connect (() => {
                var permission = get_permission ();
                if (!permission.allowed) {
                    try {
                        permission.acquire ();
                    } catch (Error e) {
                        if (!e.matches (GLib.IOError.quark (), GLib.IOError.CANCELLED)) {
                            var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
                                _("Unable to acquire permission"),
                                _("A new account cannot be created without the required system permission."),
                                "dialog-password",
                                Gtk.ButtonsType.CLOSE
                            ) {
                                badge_icon = new ThemedIcon ("dialog-error"),
                                transient_for = (Gtk.Window) get_toplevel ()
                            };
                            message_dialog.show_error_details (e.message);
                            message_dialog.run ();
                            message_dialog.destroy ();
                        }

                        return;
                    }
                }

                var new_user = new SwitchboardPlugUserAccounts.NewUserDialog ((Gtk.Window) this.get_toplevel ());
                new_user.present ();
            });

            get_permission ().notify["allowed"].connect (() => {
                if (!get_permission ().allowed) {
                    toast.reveal_child = false;
                }
            });

            toast.default_action.connect (() => {
                undo_removal ();
                userlist.update_ui ();
            });
        }

        private void update () {
            get_usermanager ().user_added.connect (add_user_settings);

            get_usermanager ().user_removed.connect ((user) => {
                remove_user_settings (user);

                if (get_removal_list ().last () == null) {
                    toast.reveal_child = false;
                }
            });

            userlist = new UserListBox ();
            userlist.row_selected.connect (userlist_selected);

            foreach (Act.User user in get_usermanager ().list_users ()) {
                add_user_settings (user);
            }

            scrolled_window.add (userlist);

            guest.guest_switch_changed.connect (() => {
                userlist.update_guest ();
            });

            //auto select current user row in userlist widget
            userlist.select_row (userlist.get_row_at_index (0));
            show_all ();
        }

        private void remove_user () {
            var permission = get_permission ();
            if (!permission.allowed) {
                try {
                    permission.acquire ();
                } catch (Error e) {
                    if (!e.matches (GLib.IOError.quark (), GLib.IOError.CANCELLED)) {
                        var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
                            _("Unable to acquire permission"),
                            _("An account cannot be removed without the required system permission."),
                            "dialog-password",
                            Gtk.ButtonsType.CLOSE
                        ) {
                            badge_icon = new ThemedIcon ("dialog-error"),
                            transient_for = (Gtk.Window) get_toplevel ()
                        };
                        message_dialog.show_error_details (e.message);
                        message_dialog.present ();
                        message_dialog.destroy ();
                    }

                    return;
                }
            }

            var selected_user = ((UserItem) userlist.get_selected_row ()).user;
            mark_removal (selected_user);

            userlist.update_ui ();
            userlist.select_row (userlist.get_row_at_index (0));

            toast.title = _("Removed “%s”").printf (selected_user.get_user_name ());
            toast.send_notification ();
        }

        private void add_user_settings (Act.User user) {
            debug ("Adding UserSettingsView Widget for User '%s'".printf (user.get_user_name ()));
            var page = new UserSettingsView (user);
            page.remove_user.connect (remove_user);
            content.add_named (page, user.get_user_name ());
        }

        private void remove_user_settings (Act.User user) {
            debug ("Removing UserSettingsView Widget for User '%s'".printf (user.get_user_name ()));
            content.remove (content.get_child_by_name (user.get_user_name ()));
        }

        private void userlist_selected (Gtk.ListBoxRow? user_item) {
            Act.User? user = null;
            if (user_item != null && user_item.name != "guest_session") {
                user = ((UserItem)user_item).user;
                var username = user.get_user_name ();
                content.set_visible_child_name (username);
            } else if (user_item != null && user_item.name == "guest_session") {
                content.set_visible_child_name ("guest_session");
            }
        }
    }
}
