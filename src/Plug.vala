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
*
* Authored by: Corentin Noël <corentin@elementary.io>
*              Marvin Beckers <beckersmarvin@gmail.com>
*/

namespace SwitchboardPlugUserAccounts {
    public static UserAccountsPlug plug;

    public class UserAccountsPlug : Switchboard.Plug {
        private Widgets.MainView? main_view;

        public UserAccountsPlug () {
            GLib.Intl.bindtextdomain (Build.GETTEXT_PACKAGE, Build.LOCALEDIR);
            GLib.Intl.bind_textdomain_codeset (Build.GETTEXT_PACKAGE, "UTF-8");

            var settings = new Gee.TreeMap<string, string?> (null, null);
            settings.set ("accounts", null);
            Object (category: Category.SYSTEM,
                code_name: "io.elementary.settings.useraccounts",
                display_name: _("User Accounts"),
                description: _("Manage account permissions and configure user names, passwords, and photos"),
                icon: "system-users",
                supported_settings: settings);

            plug = this;
        }

        public override Gtk.Widget get_widget () {
            if (main_view == null) {
                main_view = new Widgets.MainView ();
            }

            return main_view;
        }

        public override void shown () { }

        public override void hidden () {
            try {
                foreach (Act.User user in get_removal_list ()) {
                    debug ("Removing user %s from system".printf (user.get_user_name ()));
                    // Need to add a ref to stop possible crash after clearing the removal list.
                    user.ref ();
                    get_usermanager ().delete_user (user, true);
                }
                debug ("Clearing removal list");
                clear_removal_list ();
            } catch (Error e) { critical (e.message); }

            if (get_permission ().allowed) {
                try {
                    debug ("Releasing administrative permissions");
                    get_permission ().release ();
                } catch (Error e) {
                    critical (e.message);
                }
            }
        }

        public override void search_callback (string location) { }

        // 'search' returns results like ("Keyboard → Behavior → Duration", "keyboard<sep>behavior")
        public override async Gee.TreeMap<string, string> search (string search) {
            var search_results = new Gee.TreeMap<string, string> ((GLib.CompareDataFunc<string>)strcmp, (Gee.EqualDataFunc<string>)str_equal);
            search_results.set ("%s → %s".printf (display_name, _("Avatar")), "");
            search_results.set ("%s → %s".printf (display_name, _("Full name")), "");
            search_results.set ("%s → %s".printf (display_name, _("Account type")), "");
            search_results.set ("%s → %s".printf (display_name, _("Language")), "");
            search_results.set ("%s → %s".printf (display_name, _("Log in automatically")), "");
            search_results.set ("%s → %s".printf (display_name, _("Change Password")), "");
            search_results.set ("%s → %s".printf (display_name, _("Guest Session")), "");
            return search_results;
        }
    }
}

public Switchboard.Plug get_plug (Module module) {
    debug ("Activating User Accounts plug");
    var plug = new SwitchboardPlugUserAccounts.UserAccountsPlug ();
    return plug;
}
