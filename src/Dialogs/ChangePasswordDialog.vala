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

public class SwitchboardPlugUserAccounts.ChangePasswordDialog : Granite.Dialog {
    private bool is_authenticated { get; private set; default = false; }

    private ErrorRevealer current_pw_error;
    private Gtk.Entry current_pw_entry;

    public unowned Act.User user { get; construct; }
    public signal void request_password_change (Act.UserPasswordMode mode, string? new_password);

    public ChangePasswordDialog (Gtk.Window parent, Act.User user) {
        Object (
            transient_for: parent,
            user: user
        );
    }

    construct {
        var form_box = new Gtk.Box (VERTICAL, 3) {
            margin_start = 12,
            margin_end = 12,
            valign = START,
            vexpand = true
        };

        is_authenticated = get_permission ().allowed;

        if (!is_authenticated) {
            var current_pw_label = new Granite.HeaderLabel (_("Current Password"));

            current_pw_entry = new Gtk.Entry () {
                input_purpose = PASSWORD,
                secondary_icon_tooltip_text = _("Press to authenticate"),
                visibility = false
            };

            current_pw_error = new ErrorRevealer (_("Authentication failed"));
            current_pw_error.label_widget.get_style_context ().add_class (Gtk.STYLE_CLASS_ERROR);

            form_box.add (current_pw_label);
            form_box.add (current_pw_entry);
            form_box.add (current_pw_error);

            current_pw_entry.changed.connect (() => {
                if (current_pw_entry.text.length > 0) {
                    current_pw_entry.secondary_icon_name = "go-jump-symbolic";
                } else {
                    current_pw_entry.secondary_icon_name = null;
                }

                current_pw_error.reveal_child = false;
            });

            this.set_events (Gdk.EventMask.FOCUS_CHANGE_MASK);

            current_pw_entry.activate.connect (password_auth);
            current_pw_entry.icon_release.connect (password_auth);

            current_pw_entry.focus_out_event.connect (() => {
                password_auth ();
            });
        }

        var pw_editor = new Widgets.PasswordEditor (current_pw_entry);

        form_box.add (pw_editor);
        form_box.show_all ();

        modal = true;
        default_width = 350;
        get_content_area ().add (form_box);

        var cancel_button = add_button (_("Cancel"), Gtk.ResponseType.CANCEL);

        var button_change = add_button (_("Change Password"), Gtk.ResponseType.OK);
        button_change.sensitive = false;
        button_change.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        pw_editor.validation_changed.connect (() => {
            var permission = get_permission ();
            if (permission != null) {
                bool admin_requirements = pw_editor.is_valid && permission.allowed;
                bool standard_requirements = pw_editor.is_valid && pw_editor.is_obscure && is_authenticated;

                if (admin_requirements || standard_requirements) {
                    button_change.sensitive = true;
                } else {
                    button_change.sensitive = false;
                }
            }
        });

        response.connect ((response_id) => {
            if (response_id == Gtk.ResponseType.OK) {
                request_password_change (Act.UserPasswordMode.REGULAR, pw_editor.get_password ());
            }

            destroy ();
        });
    }

    private void password_auth () {
        current_pw_entry.secondary_icon_name = "process-working-symbolic";
        current_pw_entry.get_style_context ().add_class ("spin");

        Passwd.passwd_authenticate (get_passwd_handler (true), current_pw_entry.text, (h, e) => {
            if (e != null) {
                debug ("Authentication error: %s".printf (e.message));
                current_pw_error.reveal_child = true;
                is_authenticated = false;
                    current_pw_entry.secondary_icon_name = "process-error-symbolic";
            } else {
                debug ("User is authenticated for password change now");
                is_authenticated = true;

                current_pw_entry.sensitive = false;
                current_pw_entry.secondary_icon_name = "process-completed-symbolic";
            }
            current_pw_entry.get_style_context ().remove_class ("spin");
        });
    }
}
