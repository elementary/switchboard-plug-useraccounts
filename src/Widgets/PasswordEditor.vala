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
        private Gtk.Entry           current_pw_entry;
        private Gtk.Entry           new_pw_entry;
        private Gtk.Entry           confirm_pw_entry;
        private Gtk.CheckButton     show_pw_check;
        private Gtk.LevelBar        pw_level;
        private Gtk.Revealer        error_revealer;
        private Gtk.Label           error_pw_label;
        private Gtk.Revealer        error_new_revealer;
        private Gtk.Label           error_new_label;

        private PasswordQuality.Settings pwquality;

        public bool is_authenticated { public get; private set; }
        private signal void auth_changed ();

        public bool is_valid { public get; private set; }
        public signal void validation_changed ();

        private int entry_width = 200;

        public PasswordEditor () {
            pwquality = new PasswordQuality.Settings ();
            is_authenticated = false;
            is_valid = false;
            build_ui ();
        }

        public PasswordEditor.from_width (int entry_width) {
            this.entry_width = entry_width;
            pwquality = new PasswordQuality.Settings ();
            build_ui ();
        }

        private void build_ui () {
            /*
             * users who don't have superuser privileges will need to auth against passwd.
             * therefore they will need these UI elements created and displayed to set is_authenticated.
             */
            if (!get_permission ().allowed) {
                current_pw_entry = new Gtk.Entry ();
                current_pw_entry.set_placeholder_text (_("Current Password"));
                current_pw_entry.set_visibility (false);
                current_pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, null);
                current_pw_entry.set_icon_tooltip_text (Gtk.EntryIconPosition.SECONDARY, _("Press to authenticate"));
                current_pw_entry.changed.connect (() => {
                    if (current_pw_entry.get_text ().length > 0)
                        current_pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "go-jump-symbolic");
                    error_revealer.set_reveal_child (false);
                });
                current_pw_entry.activate.connect (password_auth);
                current_pw_entry.icon_release.connect (password_auth);
                attach (current_pw_entry, 0, 0, 1, 1);

                //use TAB to "activate" the GtkEntry for the current password
                this.key_press_event.connect ((e) => {
                    if (e.keyval == Gdk.Key.Tab && current_pw_entry.get_sensitive () == true)
                        password_auth ();
                    return false;
                });

                error_pw_label = new Gtk.Label ("<span font_size=\"small\">%s</span>".
                    printf (_("Authentication failed")));
                error_pw_label.set_halign (Gtk.Align.END);
                error_pw_label.get_style_context ().add_class ("error");
                error_pw_label.use_markup = true;
                error_pw_label.margin_top = 10;

                error_revealer = new Gtk.Revealer ();
                error_revealer.set_transition_type (Gtk.RevealerTransitionType.SLIDE_DOWN);
                error_revealer.set_transition_duration (200);
                error_revealer.set_reveal_child (false);
                error_revealer.add (error_pw_label);
                attach (error_revealer, 0, 1, 1, 1);

                error_new_label = new Gtk.Label ("");
                error_new_label.set_halign (Gtk.Align.END);
                error_new_label.get_style_context ().add_class ("error");
                error_new_label.justify = Gtk.Justification.RIGHT;
                error_new_label.use_markup = true;
                error_new_label.wrap = true;
                error_new_label.margin_top = 10;
                error_new_label.max_width_chars = 30;

                error_new_revealer = new Gtk.Revealer ();
                error_new_revealer.set_transition_type (Gtk.RevealerTransitionType.SLIDE_DOWN);
                error_new_revealer.set_transition_duration (200);
                error_new_revealer.set_reveal_child (false);
                error_new_revealer.add (error_new_label);
                attach (error_new_revealer, 0, 3, 1, 1);

            } else if (get_permission ().allowed)
                is_authenticated = true;

            new_pw_entry = new Gtk.Entry ();
            new_pw_entry.width_request = entry_width;
            new_pw_entry.set_placeholder_text (_("New Password"));
            new_pw_entry.set_visibility (false);
            if (!get_permission ().allowed)
                new_pw_entry.margin_top = 10;
            new_pw_entry.set_icon_tooltip_text (Gtk.EntryIconPosition.SECONDARY, _("Password cannot be empty"));
            new_pw_entry.changed.connect (compare_passwords);
            attach (new_pw_entry, 0, 2, 1, 1);

            pw_level = new Gtk.LevelBar.for_interval (0.0, 100.0);
            pw_level.set_mode (Gtk.LevelBarMode.CONTINUOUS);
            pw_level.set_hexpand (false);
            pw_level.margin_top = 10;
            pw_level.add_offset_value ("low", 50.0);
            pw_level.add_offset_value ("high", 75.0);
            pw_level.add_offset_value ("middle", 75.0);
            attach (pw_level, 0, 4, 1, 1);

            confirm_pw_entry = new Gtk.Entry ();
            confirm_pw_entry.set_placeholder_text (_("Confirm New Password"));
            confirm_pw_entry.set_visibility (false);
            confirm_pw_entry.margin_top = 10;
            confirm_pw_entry.set_icon_tooltip_text (Gtk.EntryIconPosition.SECONDARY, _("Passwords do not match"));
            confirm_pw_entry.changed.connect (compare_passwords);
            attach (confirm_pw_entry, 0, 5, 1, 1);

            show_pw_check = new Gtk.CheckButton.with_label (_("Show passwords"));
            show_pw_check.margin_top = 10;
            show_pw_check.clicked.connect (() => {
                if (show_pw_check.get_active ()) {
                    new_pw_entry.set_visibility (true);
                    confirm_pw_entry.set_visibility (true);
                } else {
                    new_pw_entry.set_visibility (false);
                    confirm_pw_entry.set_visibility (false);
                }
            });
            attach (show_pw_check, 0, 6, 1, 1);

            auth_changed.connect (update_ui);
            show_all ();
        }

        private void update_ui () {
            if (is_authenticated) {
                current_pw_entry.set_sensitive (false);
                current_pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "process-completed-symbolic");
                current_pw_entry.set_icon_tooltip_text (Gtk.EntryIconPosition.SECONDARY, _("Password accepted"));

                new_pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "dialog-error-symbolic");
                new_pw_entry.set_sensitive (true);
                new_pw_entry.grab_focus ();

                confirm_pw_entry.set_sensitive (true);
                show_pw_check.set_sensitive (true);
            }
        }

        private void compare_passwords () {
            bool is_obscure = false;

            if (new_pw_entry.get_text () != "") {
                void* error;
                var quality = pwquality.check (new_pw_entry.get_text (), current_pw_entry.get_text (), null, out error);

                pw_level.set_value (quality);

                if (quality >= 0 && quality <= 50) {
                    pw_level.set_tooltip_text (_("Weak password strength"));
                } else if (quality > 50 && quality <= 75) {
                    pw_level.set_tooltip_text (_("Medium password strength"));
                } else if (quality > 75) {
                    pw_level.set_tooltip_text (_("Strong password strength"));
                }

                /*
                 * without superuser privileges your new password needs to pass an obscurity test
                 * which is based on passwd's one to guess passwd's response.
                 */
                if (!get_permission ().allowed) {
                    if (quality >= 0) {
                        is_obscure = true;
                        error_new_revealer.set_reveal_child (false);
                    } else {
                        var pw_error = (PasswordQuality.Error) quality;
                        var error_string = pw_error.to_string (error);

                        error_new_label.label = "<span font_size=\"small\">%s</span>".printf (error_string);
                        error_new_revealer.set_reveal_child (true);
                        is_obscure = false;
                    }
                } else {
                    //a superuser does not need to care about obscurity
                    is_obscure = true;
                }
            }

            if (new_pw_entry.get_text () == confirm_pw_entry.get_text ()
            && new_pw_entry.get_text () != "" && is_obscure) {
                is_valid = true;
                new_pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, null);
                confirm_pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, null);
            } else {
                is_valid = false;

                if (new_pw_entry.get_text () != confirm_pw_entry.get_text ())
                    confirm_pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "dialog-error-symbolic");
                else
                    confirm_pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, null);

                if (new_pw_entry.get_text () == "") {
                    new_pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "dialog-error-symbolic");
                    error_new_revealer.set_reveal_child (false);
                    confirm_pw_entry.set_sensitive (false);
                    confirm_pw_entry.set_text ("");
                } else {
                    new_pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, null);
                    confirm_pw_entry.set_sensitive (true);
                }
            }
            validation_changed ();
        }

        private void password_auth () {
            Passwd.passwd_authenticate (get_passwd_handler (true), current_pw_entry.get_text (), (h, e) => {
                if (e != null) {
                    debug ("Authentication error: %s".printf (e.message));
                    error_revealer.set_reveal_child (true);
                    error_revealer.show_all ();
                    is_authenticated = false;
                    auth_changed ();
                } else {
                    debug ("User is authenticated for password change now");
                    is_authenticated = true;
                    auth_changed ();
                }
            });
        }

        public string? get_password () {
            if (is_valid)
                return new_pw_entry.get_text ();
            else
                return null;
        }

        public void reset () {
            new_pw_entry.set_text ("");
            confirm_pw_entry.set_text ("");
        }
    }
}
