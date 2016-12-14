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

Authored by: Corentin Noël <tintou@mailoo.org>
Authored by: Marvin Beckers <beckersmarvin@gmail.com>
***/

namespace SwitchboardPlugUserAccounts {
    public static UserAccountsPlug plug;

    public class UserAccountsPlug : Switchboard.Plug {
        private Gtk.Grid?           main_grid;
        private Gtk.InfoBar         infobar;
        private Gtk.InfoBar         infobar_error;
        private Gtk.InfoBar         infobar_reboot;
        private Gtk.LockButton      lock_button;
        private Widgets.MainView    main_view;

        //translatable string for org.pantheon.user-accounts.administration policy
        public const string policy_message = _("Authentication is required to change user data");

        public UserAccountsPlug () {
            var settings = new Gee.TreeMap<string, string?> (null, null);
            settings.set ("accounts", "null");
            Object (category: Category.SYSTEM,
                code_name: "system-pantheon-useraccounts",
                display_name: _("User Accounts"),
                description: _("Manage account permissions and configure user names, passwords, and photos"),
                icon: "system-users",
                supported_settings: settings);

            plug = this;
        }

        public override Gtk.Widget get_widget () {
            if (main_grid != null)
                return main_grid;

            main_grid = new Gtk.Grid ();
            main_grid.expand = true;

            infobar_error = new Gtk.InfoBar ();
            infobar_error.message_type = Gtk.MessageType.ERROR;
            infobar_error.no_show_all = true;

            var error_content = infobar_error.get_content_area () as Gtk.Container;
            Gtk.Label error_label = new Gtk.Label ("");
            error_content.add (error_label);

            main_grid.attach (infobar_error, 0, 0, 1, 1);

            InfobarNotifier.get_default ().error_notified.connect (() => {
                if (InfobarNotifier.get_default ().is_error ()) {
                    infobar_error.no_show_all = false;
                    error_label.set_label (("%s: %s".printf
                        (_("Password change failed"), InfobarNotifier.get_default ().get_error_message ())));
                    infobar_error.show_all ();
                } else {
                    infobar_error.no_show_all = true;
                    infobar_error.hide ();
                }
            });

            infobar_reboot = new Gtk.InfoBar ();
            infobar_reboot.message_type = Gtk.MessageType.INFO;
            infobar_reboot.no_show_all = true;
            main_grid.attach (infobar_reboot, 0, 1, 1, 1);

            var reboot_content = infobar_reboot.get_content_area () as Gtk.Container;
            Gtk.Label reboot_label = new Gtk.Label (_("Guest session changes will not take effect until you restart your system"));
            reboot_content.add (reboot_label);

            InfobarNotifier.get_default ().reboot_notified.connect (() => {
                if (InfobarNotifier.get_default ().is_reboot ()) {
                    infobar_reboot.no_show_all = false;
                    infobar_reboot.show_all ();
                }
            });

            infobar = new Gtk.InfoBar ();
            infobar.message_type = Gtk.MessageType.INFO;
            main_grid.attach (infobar, 0, 2, 1, 1);

            var area = infobar.get_action_area () as Gtk.Container;
            lock_button = new Gtk.LockButton (get_permission ());
            area.add (lock_button);

            var content = infobar.get_content_area () as Gtk.Container;
            var label = new Gtk.Label (_("Some settings require administrator rights to be changed"));
            content.add (label);

            main_view = new Widgets.MainView ();
            main_grid.attach (main_view, 0, 3, 1, 1);
            main_grid.show_all ();

            get_permission ().notify["allowed"].connect (() => {
                if (get_permission ().allowed) {
                    infobar.no_show_all = true;
                    infobar.hide ();
                }
            });

            return main_grid;
        }

        public override void shown () {
            if (!get_permission ().allowed) {
                infobar.no_show_all = false;
                infobar.show_all ();
            }
        }

        public override void hidden () {
            try {
                foreach (Act.User user in get_removal_list ()) {
                    debug ("Removing user %s from system".printf (user.get_user_name ()));
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
            return new Gee.TreeMap<string, string> (null, null);
        }
    }
}

public Switchboard.Plug get_plug (Module module) {
    debug ("Activating User Accounts plug");
    var plug = new SwitchboardPlugUserAccounts.UserAccountsPlug ();
    return plug;
}
