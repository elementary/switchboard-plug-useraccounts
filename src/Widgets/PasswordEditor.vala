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
    public class PasswordEditor : Gtk.Box {
        private ErrorRevealer confirm_entry_revealer;
        private ErrorRevealer pw_error_revealer;
        private Gtk.LevelBar pw_levelbar;
        private ValidatedEntry pw_entry;
        private Granite.ValidatedEntry confirm_entry;

        public Gtk.Entry current_pw_entry { get; construct; }
        public bool is_obscure { get; private set; default = false; }
        public bool is_valid { get; private set; default = false; }

        public signal void validation_changed ();

        public PasswordEditor (Gtk.Entry? current_pw_entry = null) {
            Object (current_pw_entry: current_pw_entry);
        }

        construct {
            var pw_label = new Granite.HeaderLabel (_("Choose a Password"));

            pw_entry = new ValidatedEntry ();
            pw_entry.hexpand = true;
            pw_entry.visibility = false;

            pw_levelbar = new Gtk.LevelBar.for_interval (0.0, 100.0);
            pw_levelbar.mode = Gtk.LevelBarMode.CONTINUOUS;
            pw_levelbar.add_offset_value ("low", 30.0);
            pw_levelbar.add_offset_value ("middle", 50.0);
            pw_levelbar.add_offset_value ("high", 80.0);
            pw_levelbar.add_offset_value ("full", 100.0);

            pw_error_revealer = new ErrorRevealer ("."); // Pango needs a non-null string to set markup
            pw_error_revealer.label_widget.add_css_class (Granite.STYLE_CLASS_WARNING);

            confirm_entry = new Granite.ValidatedEntry () {
                sensitive = false,
                visibility = false
            };

            var confirm_label = new Granite.HeaderLabel (_("Confirm Password")) {
                mnemonic_widget = confirm_entry
            };

            confirm_entry_revealer = new ErrorRevealer (".");
            confirm_entry_revealer.label_widget.add_css_class (Granite.STYLE_CLASS_ERROR);

            var show_pw_check = new Gtk.CheckButton.with_label (_("Show passwords"));

            orientation = Gtk.Orientation.VERTICAL;
            spacing = 3;
            append (pw_label);
            append (pw_entry);
            append (pw_levelbar);
            append (pw_error_revealer);
            append (confirm_label);
            append (confirm_entry);
            append (confirm_entry_revealer);
            append (show_pw_check);

            show_pw_check.bind_property ("active", pw_entry, "visibility", GLib.BindingFlags.DEFAULT);
            show_pw_check.bind_property ("active", confirm_entry, "visibility", GLib.BindingFlags.DEFAULT);

            pw_entry.changed.connect (() => {
                pw_entry.is_valid = check_password ();
                validate_form ();
            });

            confirm_entry.changed.connect (() => {
                confirm_entry.is_valid = confirm_password ();
                validate_form ();
            });
        }

        private void validate_form () {
            is_valid = pw_entry.is_valid && confirm_entry.is_valid;
            validation_changed ();
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

                string? current_pw = null;
                if (current_pw_entry != null) {
                    current_pw = current_pw_entry.text;
                }

                var pwquality = new PasswordQuality.Settings ();
                void* error;
                var quality = pwquality.check (pw_entry.text, current_pw, null, out error);

                if (quality >= 0) {
                    pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "process-completed-symbolic");
                    pw_error_revealer.reveal_child = false;

                    pw_levelbar.value = quality;

                    is_obscure = true;
                } else {
                    pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "dialog-warning-symbolic");

                    pw_error_revealer.reveal_child = true;
                    pw_error_revealer.label = ((PasswordQuality.Error) quality).to_string (error);

                    pw_levelbar.value = 0;

                    is_obscure = false;
                }
                return true;
            }

            return false;
        }

        private bool confirm_password () {
            if (confirm_entry.text != "") {
                if (pw_entry.text != confirm_entry.text) {
                    confirm_entry_revealer.label = _("Passwords do not match");
                    confirm_entry_revealer.reveal_child = true;
                } else {
                    confirm_entry_revealer.reveal_child = false;
                    return true;
                }
            } else {
                confirm_entry_revealer.reveal_child = false;
            }

            return false;
        }

        public string? get_password () {
            if (is_valid) {
                return pw_entry.text;
            } else {
                return null;
            }
        }

        private class ValidatedEntry : Gtk.Entry {
            public bool is_valid { get; set; default = false; }

            construct {
                activates_default = true;
            }
        }
    }
}
