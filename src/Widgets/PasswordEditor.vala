/*
* Copyright (c) 2014-2017 elementary LLC. (https://elementary.io)
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
    public class PasswordEditor : Gtk.Grid {
        private ErrorRevealer confirm_entry_revealer;
        private ErrorRevealer pw_error_revealer;
        private Gtk.Entry new_pw_entry;
        private Gtk.Entry confirm_entry;
        private Gtk.LevelBar pw_levelbar;

        private PasswordQuality.Settings pwquality;

        public Gtk.Entry current_pw_entry { get; construct; }
        private bool is_authenticated { get; private set; default = false; }
        public bool is_valid { get; private set; default = false; }

        public signal void validation_changed ();

        public PasswordEditor (Gtk.Entry? current_pw_entry) {
            Object (current_pw_entry: current_pw_entry);
        }

        construct {
            pwquality = new PasswordQuality.Settings ();
            is_authenticated = get_permission ().allowed;

            var pw_label = new Granite.HeaderLabel (_("New Password"));

            new_pw_entry = new Gtk.Entry ();
            new_pw_entry.visibility = false;
            new_pw_entry.hexpand = true;

            pw_levelbar = new Gtk.LevelBar.for_interval (0.0, 100.0);
            pw_levelbar.mode = Gtk.LevelBarMode.CONTINUOUS;
            pw_levelbar.add_offset_value ("low", 50.0);
            pw_levelbar.add_offset_value ("high", 75.0);
            pw_levelbar.add_offset_value ("middle", 75.0);

            pw_error_revealer = new ErrorRevealer ("."); // Pango needs a non-null string to set markup
            pw_error_revealer.label_widget.get_style_context ().add_class (Gtk.STYLE_CLASS_WARNING);

            var confirm_label = new Granite.HeaderLabel (_("Confirm Password"));

            confirm_entry = new Gtk.Entry ();
            confirm_entry.visibility = false;

            confirm_entry_revealer = new ErrorRevealer (".");
            confirm_entry_revealer.label_widget.get_style_context ().add_class (Gtk.STYLE_CLASS_ERROR);

            var show_pw_check = new Gtk.CheckButton.with_label (_("Show passwords"));

            orientation = Gtk.Orientation.VERTICAL;
            row_spacing = 3;
            add (pw_label);
            add (new_pw_entry);
            add (pw_levelbar);
            add (pw_error_revealer);
            add (confirm_label);
            add (confirm_entry);
            add (confirm_entry_revealer);
            add (show_pw_check);

            show_pw_check.bind_property ("active", new_pw_entry, "visibility", GLib.BindingFlags.DEFAULT);
            show_pw_check.bind_property ("active", confirm_entry, "visibility", GLib.BindingFlags.DEFAULT);

            new_pw_entry.changed.connect (compare_passwords);
            confirm_entry.changed.connect (compare_passwords);

            show_all ();
        }

        private void compare_passwords () {
            bool is_obscure = false;

            if (new_pw_entry.text != "") {
                void* error;

                string? current_pw = null;
                if (current_pw_entry != null) {
                    current_pw = current_pw_entry.text;
                }

                var quality = pwquality.check (new_pw_entry.text, current_pw, null, out error);

                pw_levelbar.value = quality;

                if (quality >= 0) {
                    is_obscure = true;
                    pw_error_revealer.reveal_child = false;
                } else {
                    var pw_error = (PasswordQuality.Error) quality;
                    var error_string = pw_error.to_string (error);

                    pw_error_revealer.label_widget.label = "<span font_size=\"small\">%s</span>".printf (error_string);
                    pw_error_revealer.reveal_child = true;

                    /* With admin privileges the new password doesn't need to pass the obscurity test */
                    is_obscure = is_authenticated;
                }
            }

            if (new_pw_entry.text == confirm_entry.text && new_pw_entry.text != "" && is_obscure) {
                is_valid = true;
                new_pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, null);
                confirm_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, null);
            } else {
                is_valid = false;

                if (new_pw_entry.text != confirm_entry.text) {
                    confirm_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "dialog-error-symbolic");
                    confirm_entry_revealer.label = _("Passwords do not match");
                    confirm_entry_revealer.reveal_child = true;
                } else {
                    confirm_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, null);
                    confirm_entry_revealer.reveal_child = false;
                }

                if (new_pw_entry.text == "") {
                    new_pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "dialog-error-symbolic");
                    pw_error_revealer.reveal_child = false;
                    confirm_entry.sensitive = false;
                    confirm_entry.text  = "";
                } else {
                    new_pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, null);
                    confirm_entry.sensitive = true;
                }
            }
            validation_changed ();
        }

        public string? get_password () {
            if (is_valid) {
                return new_pw_entry.text;
            } else {
                return null;
            }
        }
    }
}
