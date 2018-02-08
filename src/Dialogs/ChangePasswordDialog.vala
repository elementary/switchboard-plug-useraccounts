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

            current_pw_entry.activate.connect (password_auth);
            current_pw_entry.icon_release.connect (password_auth);

            //use TAB to "activate" the GtkEntry for the current password
            key_press_event.connect ((e) => {
                if (e.keyval == Gdk.Key.Tab && current_pw_entry.sensitive == true) {
                    password_auth ();
                }
                return false;
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

        var cancel_button = new Gtk.Button.with_label (_("Cancel"));

        var button_change = new Gtk.Button.with_label (_("Change Password"));
        button_change.sensitive = false;
        button_change.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        var action_area = (Gtk.Container) get_action_area ();
        action_area.margin = 6;
        action_area.margin_top = 14;
        action_area.add (cancel_button);
        action_area.add (button_change);
        action_area.show_all ();

        pw_editor.validation_changed.connect (() => {
            if (pw_editor.is_valid && is_authenticated) {
                button_change.sensitive = true;
            } else {
                button_change.sensitive = false;
            }
        });

        button_change.clicked.connect (() => {
            if (pw_editor.is_valid) {
                request_password_change (Act.UserPasswordMode.REGULAR, pw_editor.get_password ());
            }

            hide ();
            destroy ();
        });

        cancel_button.clicked.connect (() => {
            destroy ();
        });
    }

    private void password_auth () {
        Passwd.passwd_authenticate (get_passwd_handler (true), current_pw_entry.text, (h, e) => {
            if (e != null) {
                debug ("Authentication error: %s".printf (e.message));
                current_pw_error.reveal_child = true;
                is_authenticated = false;
            } else {
                debug ("User is authenticated for password change now");
                is_authenticated = true;

                current_pw_entry.sensitive = false;
                current_pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "process-completed-symbolic");
            }
        });
    }
}
