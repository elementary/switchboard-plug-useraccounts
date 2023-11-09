/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2014-2023 elementary, Inc. (https://elementary.io)
 */

public class SwitchboardPlugUserAccounts.NewUserDialog : Granite.Dialog {
    private ErrorRevealer username_error_revealer;
    private Gtk.Button create_button;
    private Widgets.PasswordEditor pw_editor;
    private Granite.ValidatedEntry username_entry;

    public NewUserDialog (Gtk.Window parent) {
        Object (transient_for: parent);
    }

    construct {
        var accounttype_combobox = new Gtk.ComboBoxText ();
        accounttype_combobox.append_text (_("Standard User"));
        accounttype_combobox.append_text (_("Administrator"));
        accounttype_combobox.set_active (0);

        var accounttype_label = new Granite.HeaderLabel (_("Account Type")) {
            mnemonic_widget = accounttype_combobox
        };

        var realname_entry = new Gtk.Entry () {
            hexpand = true,
            input_purpose = NAME
        };

        var realname_label = new Granite.HeaderLabel (_("Full Name")) {
            mnemonic_widget = realname_entry
        };

        username_entry = new Granite.ValidatedEntry ();

        var username_label = new Granite.HeaderLabel (_("Username")) {
            mnemonic_widget = username_entry
        };

        username_error_revealer = new ErrorRevealer (".");
        username_error_revealer.label_widget.add_css_class (Granite.STYLE_CLASS_ERROR);

        pw_editor = new Widgets.PasswordEditor ();

        var form_box = new Gtk.Box (VERTICAL, 3) {
            margin_end = 12,
            margin_start = 12,
            valign = START,
            vexpand = true
        };
        form_box.append (accounttype_label);
        form_box.append (accounttype_combobox);
        form_box.append (new ErrorRevealer ("."));
        form_box.append (realname_label);
        form_box.append (realname_entry);
        form_box.append (new ErrorRevealer ("."));
        form_box.append (username_label);
        form_box.append (username_entry);
        form_box.append (username_error_revealer);
        form_box.append (pw_editor);

        modal = true;
        default_width = 350;
        get_content_area ().append (form_box);

        var cancel_button = add_button (_("Cancel"), Gtk.ResponseType.CANCEL);

        create_button = (Gtk.Button) add_button (_("Create User"), Gtk.ResponseType.OK);
        create_button.receives_default = true;
        create_button.sensitive = false;
        create_button.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);

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
                        if (password != null) {
                            created_user.set_password (password, "");
                        }

                        created_user.set_locked (false);
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
        } else if (username_is_valid && !username_is_taken) {
            username_error_revealer.reveal_child = false;
            return true;
        } else {
            if (username_is_taken) {
                username_error_revealer.label = _("Username is already taken");
            } else if (!username_is_valid) {
                username_error_revealer.label = _("Username can only contain lowercase letters and numbers, without spaces");
            }

            username_error_revealer.reveal_child = true;
        }

        return false;
    }

    private void update_create_button () {
        if (username_entry.is_valid && pw_editor.is_valid) {
            create_button.sensitive = true;
            default_widget = create_button;
        } else {
            create_button.sensitive = false;
        }
    }
}
