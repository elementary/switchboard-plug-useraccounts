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

public class SwitchboardPlugUserAccounts.ChangePasswordDialog : Gtk.Dialog {
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
        var form_grid = new Gtk.Grid ();
        form_grid.margin_start = form_grid.margin_end = 12;
        form_grid.orientation = Gtk.Orientation.VERTICAL;
        form_grid.row_spacing = 3;

        is_authenticated = get_permission ().allowed;

        if (!is_authenticated) {
            var current_pw_label = new Granite.HeaderLabel (_("Current Password"));

            current_pw_entry = new Gtk.Entry ();
            current_pw_entry.visibility = false;
            current_pw_entry.set_icon_tooltip_text (Gtk.EntryIconPosition.SECONDARY, _("Press to authenticate"));

            current_pw_error = new ErrorRevealer (_("Authentication failed"));
            current_pw_error.label_widget.get_style_context ().add_class (Gtk.STYLE_CLASS_ERROR);

            form_grid.add (current_pw_label);
            form_grid.add (current_pw_entry);
            form_grid.add (current_pw_error);

            current_pw_entry.changed.connect (() => {
                if (current_pw_entry.text.length > 0) {
                    current_pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "go-jump-symbolic");
                } else {
                    current_pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, null);
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

        form_grid.add (pw_editor);
        form_grid.show_all ();

        deletable = false;
        modal = true;
        resizable= false;
        width_request = 560;
        window_position = Gtk.WindowPosition.CENTER_ON_PARENT;
        get_content_area ().add (form_grid);

        var cancel_button = add_button (_("Cancel"), Gtk.ResponseType.CANCEL);
        cancel_button.margin_bottom = 6;
        cancel_button.margin_top = 14;

        var button_change = add_button (_("Change Password"), Gtk.ResponseType.OK);
        button_change.margin = 6;
        button_change.margin_top = 14;
        button_change.margin_start = 0;
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
        current_pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "process-working-symbolic");
        current_pw_entry.get_style_context ().add_class ("spin");

        Passwd.passwd_authenticate (get_passwd_handler (true), current_pw_entry.text, (h, e) => {
            if (e != null) {
                debug ("Authentication error: %s".printf (e.message));
                current_pw_error.reveal_child = true;
                is_authenticated = false;
                current_pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "process-error-symbolic");
            } else {
                debug ("User is authenticated for password change now");
                is_authenticated = true;

                current_pw_entry.sensitive = false;
                current_pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "process-completed-symbolic");
            }
            current_pw_entry.get_style_context ().remove_class ("spin");
        });
    }
}
