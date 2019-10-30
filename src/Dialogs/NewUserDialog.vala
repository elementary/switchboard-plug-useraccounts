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

public class SwitchboardPlugUserAccounts.NewUserDialog : Gtk.Dialog {
    private ErrorRevealer username_error_revealer;
    private Gtk.Button create_button;
    private Widgets.PasswordEditor pw_editor;
    private ValidatedEntry username_entry;

    public NewUserDialog (Gtk.Window parent) {
        Object (transient_for: parent);
    }

    construct {
        var accounttype_label = new Granite.HeaderLabel (_("Account Type"));

        var accounttype_combobox = new Gtk.ComboBoxText ();
        accounttype_combobox.append_text (_("Standard User"));
        accounttype_combobox.append_text (_("Administrator"));
        accounttype_combobox.set_active (0);

        var realname_label = new Granite.HeaderLabel (_("Full Name"));

        var realname_entry = new Gtk.Entry ();
        realname_entry.hexpand = true;

        var username_label = new Granite.HeaderLabel (_("Username"));

        username_entry = new ValidatedEntry ();

        username_error_revealer = new ErrorRevealer (".");
        username_error_revealer.label_widget.get_style_context ().add_class (Gtk.STYLE_CLASS_ERROR);

        pw_editor = new Widgets.PasswordEditor ();

        var form_grid = new Gtk.Grid ();
        form_grid.margin_start = form_grid.margin_end = 12;
        form_grid.orientation = Gtk.Orientation.VERTICAL;
        form_grid.row_spacing = 3;
        form_grid.valign = Gtk.Align.CENTER;
        form_grid.vexpand = true;
        form_grid.add (accounttype_label);
        form_grid.add (accounttype_combobox);
        form_grid.add (new ErrorRevealer ("."));
        form_grid.add (realname_label);
        form_grid.add (realname_entry);
        form_grid.add (new ErrorRevealer ("."));
        form_grid.add (username_label);
        form_grid.add (username_entry);
        form_grid.add (username_error_revealer);
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

        create_button = (Gtk.Button) add_button (_("Create User"), Gtk.ResponseType.OK);
        create_button.margin = 6;
        create_button.margin_top = 14;
        create_button.can_default = true;
        create_button.sensitive = false;
        create_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        realname_entry.changed.connect (() => {
            var username = gen_username (realname_entry.text);
            username_entry.text = username;
        });

        username_entry.changed.connect (() => {
            username_entry.is_valid = check_username ();
            update_create_button ();
        });

        pw_editor.validation_changed.connect (() => {
            update_create_button ();
        });

        response.connect ((response_id) => {
            if (response_id == Gtk.ResponseType.OK) {
                string fullname = realname_entry.text;
                string username = username_entry.text;
                string password = pw_editor.get_password ();
                Act.UserAccountType accounttype = Act.UserAccountType.STANDARD;

                if (accounttype_combobox.get_active () == 1) {
                    accounttype = Act.UserAccountType.ADMINISTRATOR;
                }

                if (get_permission ().allowed) {
                    try {
                        var created_user = get_usermanager ().create_user (username, fullname, accounttype);

                        get_usermanager ().user_added.connect ((user) => {
                            if (user == created_user) {
                                created_user.set_locked (false);

                                if (password != null) {
                                    created_user.set_password (password, "");
                                }
                            }
                        });
                    } catch (Error e) {
                        critical ("Creation of user '%s' failed", username);
                    }
                }
            }

            destroy ();
        });
    }

    private bool check_username () {
        string username_entry_text = username_entry.text;
        bool username_is_valid = is_valid_username (username_entry_text);
        bool username_is_taken = is_taken_username (username_entry_text);

        if (username_entry_text == "") {
            username_error_revealer.reveal_child = false;
            username_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, null);
        } else if (username_is_valid && !username_is_taken) {
            username_error_revealer.reveal_child = false;
            username_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "process-completed-symbolic");
            return true;
        } else {
            if (username_is_taken) {
                username_error_revealer.label = _("Username is already taken");
            } else if (!username_is_valid) {
                username_error_revealer.label = _("Username can only contain lowercase letters and numbers, without spaces");
            }

            username_error_revealer.reveal_child = true;
            username_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "process-error-symbolic");
        }

        return false;
    }

    private void update_create_button () {
        if (username_entry.is_valid && pw_editor.is_valid) {
            create_button.sensitive = true;
            create_button.has_default = true;
        } else {
            create_button.sensitive = false;
        }
    }

    private class ValidatedEntry : Gtk.Entry {
        public bool is_valid { get; set; default = false; }
    }
}
