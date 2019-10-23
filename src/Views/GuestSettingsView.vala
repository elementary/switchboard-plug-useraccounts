/*
* Copyright (c) 2014-2018 elementary LLC. (https://elementary.io)
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
    public class GuestSettingsView : Granite.SimpleSettingsPage {
        public signal void guest_switch_changed ();

        public GuestSettingsView () {
            Object (
                activatable: true,
                description: "%s %s".printf (
                    _("The Guest Session allows someone to use a temporary default account without a password."),
                    _("Once they log out, all of their settings and data will be deleted.")),
                icon_name: "avatar-default",
                title: _("Guest Session")
            );
        }

        construct {
            var guest_autologin_switch = new Gtk.Switch ();
            guest_autologin_switch.halign = Gtk.Align.START;

            var guest_autologin_label = new Gtk.Label (_("Log In automatically:"));
            guest_autologin_label.xalign = 0;

            content_area.attach (guest_autologin_label, 0, 0, 1, 1);
            content_area.attach (guest_autologin_switch, 1, 0, 1, 1);

            margin = 12;
            show_all ();

            status_switch.active = get_guest_session_state ("show");

            guest_autologin_switch.active = get_guest_session_state ("show-autologin");

            var permission = get_permission ();
            sensitive = permission.allowed;

            permission.notify["allowed"].connect (() => {
                sensitive = permission.allowed;
            });

            status_switch.bind_property ("active", content_area, "sensitive", BindingFlags.DEFAULT);

            status_switch.notify["active"].connect (() => {
                if (get_guest_session_state ("show") != status_switch.active) {
                    InfobarNotifier.get_default ().reboot_required = true;

                    if (status_switch.active) {
                        set_guest_session_state ("on");
                    } else {
                        set_guest_session_state ("off");
                        guest_autologin_switch.active = false;
                    }

                    guest_switch_changed ();
                }
            });

            guest_autologin_switch.notify["active"].connect (() => {
                if (get_guest_session_state ("show-autologin") != guest_autologin_switch.active) {
                    InfobarNotifier.get_default ().reboot_required = true;

                    if (guest_autologin_switch.active) {
                        set_guest_session_state ("autologin-on");
                    } else {
                        set_guest_session_state ("autologin-off");
                    }
                }
            });
        }
    }
}
