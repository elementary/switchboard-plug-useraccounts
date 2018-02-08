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
    public unowned Act.User user { get; construct; }
    public signal void request_password_change (Act.UserPasswordMode mode, string? new_password);

    public ChangePasswordDialog (Gtk.Window parent, Act.User user) {
        Object (
            transient_for: parent,
            user: user
        );
    }

    construct {
        var pw_editor = new Widgets.PasswordEditor ();
        pw_editor.margin_start = pw_editor.margin_end = 12;

        deletable = false;
        modal = true;
        resizable= false;
        width_request = 560;
        window_position = Gtk.WindowPosition.CENTER_ON_PARENT;
        get_content_area ().add (pw_editor);

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
            if (pw_editor.is_valid && pw_editor.is_authenticated) {
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
}
