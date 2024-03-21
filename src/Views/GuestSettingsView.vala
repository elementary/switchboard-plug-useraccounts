/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2014-2023 elementary, Inc. (https://elementary.io)
 *
 */

public class SwitchboardPlugUserAccounts.Widgets.GuestSettingsView : Switchboard.SettingsPage {
    public signal void guest_switch_changed ();

    public GuestSettingsView () {
        Object (
            activatable: true,
            description: "%s %s".printf (
                _("The Guest Session allows someone to use a temporary default account without a password."),
                _("Once they log out, all of their settings and data will be deleted.")),
            icon: new ThemedIcon ("avatar-default"),
            title: _("Guest Session")
        );
    }

    construct {
        var guest_autologin_switch = new Gtk.Switch () {
            halign = START
        };

        var guest_autologin_label = new Gtk.Label (_("Log In automatically:"));

        var autologin_box = new Gtk.Box (HORIZONTAL, 12);
        autologin_box.append (guest_autologin_label);
        autologin_box.append (guest_autologin_switch);

        var infobar_reboot = new Gtk.InfoBar () {
            message_type = WARNING,
            revealed = false
        };
        infobar_reboot.add_child (new Gtk.Label (_("Guest session changes will not take effect until you restart your system")));
        infobar_reboot.add_css_class (Granite.STYLE_CLASS_FRAME);

        var box = new Gtk.Box (VERTICAL, 24);
        box.append (autologin_box);
        box.append (infobar_reboot);

        child = box;
        show_end_title_buttons = true;

        status_switch.active = get_guest_session_state ("show");

        guest_autologin_switch.active = get_guest_session_state ("show-autologin");

        status_switch.bind_property ("active", autologin_box, "sensitive", BindingFlags.DEFAULT);

        status_switch.notify["active"].connect (() => {
            if (get_guest_session_state ("show") != status_switch.active) {
                if (!acquire_permission ()) {
                    status_switch.active = get_guest_session_state ("show");
                    return;
                }

                infobar_reboot.revealed = true;

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
                if (!acquire_permission ()) {
                    guest_autologin_switch.state = get_guest_session_state ("show-autologin");
                    return;
                }

                infobar_reboot.revealed = true;

                if (guest_autologin_switch.active) {
                    set_guest_session_state ("autologin-on");
                } else {
                    set_guest_session_state ("autologin-off");
                }
            }
        });
    }

    private bool acquire_permission () {
        var permission = get_permission ();
        if (!permission.allowed) {
            try {
                permission.acquire ();
            } catch (Error e) {
                if (!e.matches (GLib.IOError.quark (), GLib.IOError.CANCELLED)) {
                    var message_dialog = new Granite.MessageDialog (
                        _("Unable to acquire permission"),
                        _("The guest account cannot be modified without the required system permission."),
                        new ThemedIcon ("dialog-password"),
                        Gtk.ButtonsType.CLOSE
                    ) {
                        badge_icon = new ThemedIcon ("dialog-error"),
                        modal = true,
                        transient_for = (Gtk.Window) get_root ()
                    };
                    message_dialog.show_error_details (e.message);
                    message_dialog.response.connect (message_dialog.destroy);
                    message_dialog.present ();
                }

                return false;
            }
        }

        return true;
    }
}
