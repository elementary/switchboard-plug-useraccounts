/***
  Copyright (C) 2014-2015 Switchboard User Accounts Plug Developer
  This program is free software: you can redistribute it and/or modify it
  under the terms of the GNU Lesser General Public License version 3, as published
  by the Free Software Foundation.

  This program is distributed in the hope that it will be useful, but
  WITHOUT ANY WARRANTY; without even the implied warranties of
  MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
  PURPOSE. See the GNU General Public License for more details.

  You should have received a copy of the GNU General Public License along
  with this program. If not, see http://www.gnu.org/licenses/.
***/

namespace SwitchboardPlugUserAccounts.Widgets {
    public class MainView : Gtk.Paned {
        public UserListBox          userlist;
        public Gtk.Stack            content;
        public Gtk.Box              sidebar;
        public Gtk.ScrolledWindow   scrolled_window;
        public Gtk.ScrolledWindow   content_window;
        public ListFooter           footer;

        private GuestSettingsView   guest;

        public MainView () {
            expand = true;
            set_orientation (Gtk.Orientation.HORIZONTAL);

            sidebar = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            pack1 (sidebar, true, false);
            content_window = new Gtk.ScrolledWindow (null, null);
            pack2 (content_window, true, false);

            content = new Gtk.Stack ();
            content_window.add (content);

            guest = new GuestSettingsView ();
            get_usermanager ().notify["is-loaded"].connect (update);

            if (get_usermanager ().is_loaded)
                update ();
        }

        private void update () {
            if (get_usermanager ().is_loaded) {
                get_usermanager ().user_added.connect (add_user_settings);
                get_usermanager ().user_removed.connect (remove_user_settings);

                userlist = new UserListBox ();
                userlist.row_selected.connect (userlist_selected);

                foreach (Act.User user in get_usermanager ().list_users ())
                    add_user_settings (user);

                content.add_named (guest, "guest_session");
                build_ui ();
            }
        }

        public void build_ui () {
            scrolled_window = new Gtk.ScrolledWindow (null, null);
            scrolled_window.add (userlist);

            footer = new ListFooter ();
            footer.removal_changed.connect (userlist.update_ui);
            footer.unfocused.connect (() => {
                content.set_visible_child_name (get_current_user ().get_user_name ());
                userlist.select_row (userlist.get_row_at_index (1));
            });
            sidebar.pack_start (scrolled_window, true, true);
            sidebar.pack_end (footer, false, false);

            guest.guest_switch_changed.connect (() => {
                userlist.update_guest ();
            });

            //auto select current user row in userlist widget
            userlist.select_row (userlist.get_row_at_index (0));
            set_position (240);
            show_all ();
        }

        private void add_user_settings (Act.User user) {
            debug ("Adding UserSettingsView Widget for User '%s'".printf (user.get_user_name ()));
            content.add_named (new UserSettingsView (user), user.get_user_name ());
        }

        private void remove_user_settings (Act.User user) {
            debug ("Removing UserSettingsView Widget for User '%s'".printf (user.get_user_name ()));
            content.remove (content.get_child_by_name (user.get_user_name ()));
        }

        private void userlist_selected (Gtk.ListBoxRow? user_item) {
            Act.User? user = null;
            if (user_item != null && user_item.name != "guest_session") {
                user = ((UserItem)user_item).user;
                content.set_visible_child_name (user.get_user_name ());
                footer.set_selected_user (user);
            } else if (user_item != null && user_item.name == "guest_session") {
                content.set_visible_child_name ("guest_session");
                footer.set_selected_user (null);
            }
        }
    }
}
