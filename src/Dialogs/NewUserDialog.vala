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
    private ErrorRevealer confirm_entry_revealer;
    private ErrorRevealer pw_error_revealer;
    private ErrorRevealer username_error_revealer;
    private Gtk.Button create_button;
    private ValidatedEntry confirm_entry;
    private ValidatedEntry username_entry;
    private ValidatedEntry pw_entry;
    private Gtk.LevelBar pw_levelbar;

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

        var pw_label = new Granite.HeaderLabel (_("Choose a Password"));

        pw_error_revealer = new ErrorRevealer (".");
        pw_error_revealer.label_widget.get_style_context ().add_class (Gtk.STYLE_CLASS_WARNING);

        pw_entry = new ValidatedEntry ();
        pw_entry.visibility = false;

        pw_levelbar = new Gtk.LevelBar ();
        pw_levelbar = new Gtk.LevelBar.for_interval (0.0, 100.0);
        pw_levelbar.set_mode (Gtk.LevelBarMode.CONTINUOUS);
        pw_levelbar.add_offset_value ("low", 50.0);
        pw_levelbar.add_offset_value ("high", 75.0);
        pw_levelbar.add_offset_value ("middle", 75.0);

        var confirm_label = new Granite.HeaderLabel (_("Confirm Password"));

        confirm_entry = new ValidatedEntry ();
        confirm_entry.sensitive = false;
        confirm_entry.visibility = false;

        confirm_entry_revealer = new ErrorRevealer (".");
        confirm_entry_revealer.label_widget.get_style_context ().add_class (Gtk.STYLE_CLASS_ERROR);

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
        form_grid.add (pw_label);
        form_grid.add (pw_entry);
        form_grid.add (pw_levelbar);
        form_grid.add (pw_error_revealer);
        form_grid.add (confirm_label);
        form_grid.add (confirm_entry);
        form_grid.add (confirm_entry_revealer);
        form_grid.show_all ();

        deletable = false;
        modal = true;
        resizable= false;
        width_request = 560;
        window_position = Gtk.WindowPosition.CENTER_ON_PARENT;
        get_content_area ().add (form_grid);

        var cancel_button = new Gtk.Button.with_label (_("Cancel"));

        create_button = new Gtk.Button.with_label (_("Create User"));
        create_button.sensitive = false;
        create_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        var action_area = (Gtk.Container) get_action_area ();
        action_area.margin = 6;
        action_area.margin_top = 8;
        action_area.add (cancel_button);
        action_area.add (create_button);
        action_area.show_all ();

        realname_entry.changed.connect (() => {
            var username = gen_username (realname_entry.text);
            username_entry.text = username;
        });

        username_entry.changed.connect (() => {
            username_entry.is_valid = check_username ();
            update_create_button ();
        });

        pw_entry.changed.connect (() => {
            pw_entry.is_valid = check_password ();
            confirm_entry.is_valid = confirm_password ();
            update_create_button ();
        });

        confirm_entry.changed.connect (() => {
            confirm_entry.is_valid = confirm_password ();
            update_create_button ();
        });

        ((Gtk.Button) cancel_button).clicked.connect (() => {
            destroy ();
        });

        create_button.clicked.connect (() => {
            string fullname = realname_entry.text;
            string username = username_entry.text;
            string password = pw_entry.text;
            Act.UserAccountType accounttype = Act.UserAccountType.STANDARD;

            if (accounttype_combobox.get_active () == 1) {
                accounttype = Act.UserAccountType.ADMINISTRATOR;
            }

            create_new_user (fullname, username, accounttype, Act.UserPasswordMode.REGULAR, password);

            destroy ();
        });
    }

    private bool check_password () {
        if (pw_entry.text == "") {
            confirm_entry.text = "";
            confirm_entry.sensitive = false;

            pw_levelbar.value = 0;

            pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, null);
            pw_error_revealer.reveal_child = false;
        } else {
            confirm_entry.sensitive = true;

            var pwquality = new PasswordQuality.Settings ();
            void* error;
            var quality = pwquality.check (pw_entry.text, null, null, out error);

            if (quality >= 0) {
                pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "process-completed-symbolic");
                pw_error_revealer.reveal_child = false;

                pw_levelbar.value = quality;
            } else {
                pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "dialog-warning-symbolic");

                pw_error_revealer.reveal_child = true;
                pw_error_revealer.label = ((PasswordQuality.Error) quality).to_string (error);

                pw_levelbar.value = 0;
            }
            return true;
        }

        return false;
    }

    private bool confirm_password () {
        if (confirm_entry.text != "") {
            if (pw_entry.text != confirm_entry.text) {
                confirm_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "dialog-error-symbolic");
                confirm_entry_revealer.label = _("Passwords do not match");
                confirm_entry_revealer.reveal_child = true;
            } else {
                confirm_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "process-completed-symbolic");
                confirm_entry_revealer.reveal_child = false;
                return true;
            }
        } else {
            confirm_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, null);
            confirm_entry_revealer.reveal_child = false;
        }

        return false;
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
            username_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "dialog-error-symbolic");
        }

        return false;
    }

    private void update_create_button () {
        if (username_entry.is_valid && pw_entry.is_valid && confirm_entry.is_valid) {
            create_button.sensitive = true;
        } else {
            create_button.sensitive = false;
        }
    }

    private class ValidatedEntry : Gtk.Entry {
        public bool is_valid { get; set; default = false; }
    }

    private class ErrorRevealer : Gtk.Revealer {
        public Gtk.Label label_widget;

        public string label {
            set {
                label_widget.label = "<span font_size=\"small\">%s</span>".printf (value);
            }
        }

        public ErrorRevealer (string label) {
            label_widget = new Gtk.Label ("<span font_size=\"small\">%s</span>".printf (label));
            label_widget.halign = Gtk.Align.END;
            label_widget.justify = Gtk.Justification.RIGHT;
            label_widget.max_width_chars = 55;
            label_widget.use_markup = true;
            label_widget.wrap = true;
            label_widget.xalign = 1;

            transition_type = Gtk.RevealerTransitionType.CROSSFADE;
            add (label_widget);
        }
    }
}
