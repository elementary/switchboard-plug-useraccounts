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
    public class UserSettingsView : Gtk.Box {
        public weak Act.User user { get; construct; }

        private UserUtils utils;
        private DeltaUser delta_user;
        private FPUtils fp_utils;

        private Gtk.ListStore language_store;
        private Gtk.ListStore region_store;

        private Adw.Avatar avatar;
        private Granite.HeaderLabel autologin_label;
        private Granite.HeaderLabel lang_label;
        private Granite.HeaderLabel user_type_label;
        private Gtk.Entry full_name_entry;
        private Gtk.Button fingerprint_button;
        private Gtk.Button remove_fp_button;
        private Gtk.Button password_button;
        private Gtk.Button enable_user_button;
        private Gtk.ComboBoxText user_type_dropdown;
        private Gtk.ComboBox language_dropdown;
        private Gtk.ComboBox region_box;
        private Gtk.Button language_button;
        private Gtk.Switch autologin_switch;
        private Gtk.InfoBar infobar;

        //lock widgets
        private Gtk.Image full_name_lock;

        private Gee.HashMap<string, string>? default_regions;

        public signal void remove_user ();

        private const string NO_PERMISSION_STRING = _("You do not have permission to change this");
        private const string CURRENT_USER_STRING = _("You cannot change this for the currently active user");
        private const string LAST_ADMIN_STRING = _("You cannot remove the last administrator's privileges");

        public UserSettingsView (Act.User user) {
            Object (user: user);
        }

        class construct {
            set_css_name ("settingspage");
        }

        construct {
            utils = new UserUtils (user, this);
            delta_user = new DeltaUser (user);
            try {
                fp_utils = new FPUtils ();
            } catch (Error e) {
                warning ("Fingerprint reader not available: %s", e.message);
            }

            default_regions = get_default_regions ();

            avatar = new Adw.Avatar (48, user.real_name, true);

            var avatar_popover = new AvatarPopover (user, utils);
            avatar_popover.add_css_class (Granite.STYLE_CLASS_MENU);

            var avatar_button = new Gtk.MenuButton () {
                child = avatar,
                halign = END,
                has_frame = false,
                popover = avatar_popover
            };

            full_name_entry = new Gtk.Entry () {
                valign = Gtk.Align.CENTER
            };
            full_name_entry.add_css_class (Granite.STYLE_CLASS_H3_LABEL);
            full_name_entry.activate.connect (() => {
                utils.change_full_name (full_name_entry.get_text ().strip ());
            });


            full_name_lock = new Gtk.Image.from_icon_name ("changes-prevent-symbolic") {
                margin_start = 6,
                tooltip_text = NO_PERMISSION_STRING
            };
            full_name_lock.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);

            var header_area = new Gtk.Grid () {
                halign = CENTER
            };
            header_area.attach (avatar_button, 0, 0);
            header_area.attach (full_name_entry, 1, 0);
            header_area.attach (full_name_lock, 2, 0);
            header_area.add_css_class ("header-area");

            var end_widget = new Gtk.WindowControls (END) {
                valign = START
            };

            var headerbar = new Gtk.CenterBox () {
                center_widget = header_area,
                end_widget = end_widget
            };

            var window_handle = new Gtk.WindowHandle () {
                child = headerbar
            };

            user_type_dropdown = new Gtk.ComboBoxText () {
                hexpand = true
            };
            user_type_dropdown.append_text (_("Standard"));
            user_type_dropdown.append_text (_("Administrator"));
            user_type_dropdown.changed.connect (() => {
                utils.change_user_type (user_type_dropdown.active);
            });

            user_type_label = new Granite.HeaderLabel (_("Account type")) {
                mnemonic_widget = user_type_dropdown
            };

            var user_type_box = new Gtk.Box (VERTICAL, 6);
            user_type_box.append (user_type_label);
            user_type_box.append (user_type_dropdown);

            lang_label = new Granite.HeaderLabel (_("Language"));

            var language_box = new Gtk.Box (VERTICAL, 6);
            language_box.append (lang_label);

            if (user != get_current_user ()) {
                var renderer = new Gtk.CellRendererText ();

                language_dropdown = new Gtk.ComboBox () {
                    sensitive = false
                };
                language_dropdown.pack_start (renderer, true);
                language_dropdown.add_attribute (renderer, "text", 1);

                renderer = new Gtk.CellRendererText ();

                region_box = new Gtk.ComboBox () {
                    sensitive = false
                };
                region_box.pack_start (renderer, true);
                region_box.add_attribute (renderer, "text", 1);

                var region_revealer = new Gtk.Revealer () {
                    child = region_box,
                    overflow = VISIBLE,
                    transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
                    reveal_child = true
                };

                language_box.append (language_dropdown);
                language_box.append (region_revealer);

                language_dropdown.changed.connect (() => {
                    Gtk.TreeIter? iter;
                    Value cell;

                    language_dropdown.get_active_iter (out iter);
                    language_store.get_value (iter, 0, out cell);

                    if (get_regions ((string)cell).size == 0) {
                        region_revealer.reveal_child = false;
                        if (user.get_language () != (string)cell) {
                            utils.change_language ((string)cell);
                        }
                    } else {
                        region_revealer.reveal_child = true;
                        update_region ((string)cell);
                    }
                });

                region_box.changed.connect (() => {
                    string new_language;
                    Gtk.TreeIter? iter;
                    Value cell;

                    language_dropdown.get_active_iter (out iter);
                    language_store.get_value (iter, 0, out cell);
                    new_language = (string)cell;

                    region_box.get_active_iter (out iter);
                    region_store.get_value (iter, 0, out cell);
                    new_language += "_%s".printf ((string)cell);

                    if (new_language != "" && new_language != user.get_language ()) {
                        utils.change_language (new_language);
                    }
                });
            } else {
                language_button = new Gtk.LinkButton.with_label ("settings://language", "Language") {
                    halign = Gtk.Align.START,
                    tooltip_text = _("Click to switch to Language & Region Settings")
                };

                language_box.append (language_button);
            }

            autologin_switch = new Gtk.Switch () {
                halign = END,
                hexpand = true,
                valign = CENTER
            };
            autologin_switch.notify["active"].connect (() => utils.change_autologin (autologin_switch.active));

            autologin_label = new Granite.HeaderLabel (_("Log In automatically")) {
                mnemonic_widget = autologin_switch,
                valign = CENTER
            };

            var autologin_box = new Gtk.Box (HORIZONTAL, 12);
            autologin_box.append (autologin_label);
            autologin_box.append (autologin_switch);

            Gtk.Box fp_box;
            if (fp_utils != null) {
                fp_box = new Gtk.Box (HORIZONTAL, 0) {
                    halign = END,
                    margin_end = 6
                };
                fp_box.add_css_class (Granite.STYLE_CLASS_LINKED);
                fingerprint_button = new Gtk.Button.with_label (_("Set Up Fingerprint…")) {
                    sensitive = false
                };
                remove_fp_button = new Gtk.Button.from_icon_name ("edit-delete-symbolic") {
                    tooltip_text = _("Remove Fingerprint"),
                    sensitive = false
                };
                remove_fp_button.remove_css_class ("image-button");

                fp_box.append (fingerprint_button);
                fp_box.append (remove_fp_button);
                fingerprint_button.clicked.connect (() => {
                    var permission = get_permission ();
                    if (user == get_current_user () && permission.allowed) {
                        try {
                            permission.release ();
                        } catch (Error e) {
                            critical ("Error releasing privileges: %s", e.message);
                        }
                    }

                    var fingerprint_dialog = new FingerprintDialog ((Gtk.Window) this.get_root (), user);
                    fingerprint_dialog.present ();
                });

                remove_fp_button.clicked.connect (() => {
                    var permission = get_permission ();
                    if (user == get_current_user () && permission.allowed) {
                        try {
                            permission.release ();
                        } catch (Error e) {
                            critical ("Error releasing privileges: %s", e.message);
                        }
                    }

                    if (fp_utils.claim ()) {
                        fp_utils.delete_enrollments_async.begin (() => {
                            remove_fp_button.sensitive = false;
                            fp_utils.release ();
                        });
                    }
                });
            }

            password_button = new Gtk.Button.with_label (_("Change Password…"));
            password_button.clicked.connect (() => {
                var permission = get_permission ();
                if (user == get_current_user () && permission.allowed) {
                    try {
                        permission.release ();
                    } catch (Error e) {
                        critical ("Error releasing privileges: %s", e.message);
                    }
                }

                var change_password_dialog = new ChangePasswordDialog ((Gtk.Window) this.get_root (), user);
                change_password_dialog.present ();
                change_password_dialog.request_password_change.connect (change_password);
            });

            enable_user_button = new Gtk.Button () {
                sensitive = false
            };
            enable_user_button.clicked.connect (change_lock);

            var remove_user_button = new Gtk.Button.with_label (_("Remove Account")) {
                sensitive = false
            };
            remove_user_button.add_css_class (Granite.STYLE_CLASS_DESTRUCTIVE_ACTION);
            remove_user_button.clicked.connect (() => remove_user ());

            var remove_lock = new Gtk.Image.from_icon_name ("changes-prevent-symbolic") {
                margin_start = 6
            };
            remove_lock.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);

            var lock_button = new Gtk.LockButton (get_permission ());

            var infobar_label = new Gtk.Label (_("Some settings require administrator rights to be changed")) {
                wrap = true
            };

            infobar = new Gtk.InfoBar () {
                message_type = INFO
            };
            infobar.add_css_class (Granite.STYLE_CLASS_FRAME);
            infobar.add_action_widget (lock_button, 0);
            infobar.add_child (infobar_label);

            var content_box = new Gtk.Box (VERTICAL, 24);
            content_box.append (infobar);
            content_box.append (user_type_box);
            content_box.append (language_box);
            content_box.append (autologin_box);

            var content_area = new Adw.Clamp () {
                child = content_box,
                maximum_size = 600,
                tightening_threshold = 600,
                vexpand = true
            };
            content_area.add_css_class ("content-area");

            var action_area = new Gtk.Box (HORIZONTAL, 0) {
                margin_top = 12,
                margin_end = 12,
                margin_bottom = 12,
                margin_start = 12
            };
            action_area.append (remove_user_button);
            action_area.append (enable_user_button);
            action_area.append (remove_lock);
            action_area.append (new Gtk.Grid () { hexpand = true });
            if (fp_box != null) {
                action_area.append (fp_box);
            }
            action_area.append (password_button);
            action_area.add_css_class ("buttonbox");

            var size_group = new Gtk.SizeGroup (HORIZONTAL);
            size_group.add_widget (header_area);
            size_group.add_widget (content_area);

            var scrolled = new Gtk.ScrolledWindow () {
                child = content_area,
                hscrollbar_policy = NEVER
            };

            var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            box.append (window_handle);
            box.append (scrolled);
            box.append (action_area);

            append (box);

            update_ui ();
            update_permission ();

            if (get_current_user () == user) {
                user_type_label.secondary_text = CURRENT_USER_STRING;
                remove_lock.tooltip_text = CURRENT_USER_STRING;
            } else if (is_last_admin (user)) {
                user_type_label.secondary_text = LAST_ADMIN_STRING;
                remove_lock.tooltip_text = LAST_ADMIN_STRING;
            } else {
                enable_user_button.sensitive = true;

                remove_user_button.sensitive = true;
                action_area.remove (remove_lock);
            }

            get_permission ().notify["allowed"].connect (update_permission);

            user.changed.connect (update_ui);
            user.changed.connect (update_permission);
        }

        private void update_permission () {
            var allowed = get_permission ().allowed;
            var current_user = get_current_user () == user;
            var user_locked = user.get_locked ();
            var last_admin = is_last_admin (user);

            infobar.revealed = !allowed;

            if (!allowed) {
                user_type_dropdown.sensitive = false;
                password_button.sensitive = false;
                autologin_switch.sensitive = false;
                if (fp_utils != null) {
                    remove_fp_button.sensitive = false;
                    fingerprint_button.sensitive = false;
                }

                autologin_label.secondary_text = NO_PERMISSION_STRING;
                user_type_label.secondary_text = NO_PERMISSION_STRING;
            }

            lang_label.secondary_text = null;

            if (fp_utils != null) {
                remove_fp_button.sensitive = current_user && allowed && fp_utils.is_enrolled ();
                fingerprint_button.sensitive = current_user && allowed;
            }

            if (current_user || allowed) {
                full_name_entry.sensitive = true;
                full_name_lock.set_opacity (0);

                password_button.sensitive = !user_locked;

                if (allowed) {
                    if (!user_locked) {
                        autologin_switch.sensitive = true;
                        autologin_label.secondary_text = null;
                    } else {
                        autologin_switch.sensitive = false;
                        autologin_label.secondary_text = NO_PERMISSION_STRING;
                    }

                    if (!last_admin && !current_user) {
                        user_type_dropdown.sensitive = true;
                        user_type_label.secondary_text = null;
                    }
                }

                if (!current_user) {
                    language_dropdown.sensitive = true;
                    region_box.sensitive = true;
                }
            } else {
                full_name_entry.sensitive = false;

                if (!current_user) {
                    lang_label.secondary_text = NO_PERMISSION_STRING;
                    language_dropdown.sensitive = false;
                    region_box.sensitive = false;
                }
            }
        }

        private void update_ui () {
            //only update widgets if the user property has changed since last ui update
            if (delta_user.real_name != user.get_real_name ()) {
                update_real_name ();
            }

            // Checking delta_user icon file doesn't seem to always update correctly
            try {
                avatar.custom_image = Gdk.Texture.from_filename (user.get_icon_file ());
            } catch (Error e) {
                critical ("couldn't load avatar");
            }

            if (delta_user.account_type != user.get_account_type ()) {
                update_account_type ();
            }

            var user_automatic_login = user.get_automatic_login ();
            if (delta_user.automatic_login != user_automatic_login) {
                if (user_automatic_login && !autologin_switch.active) {
                    autologin_switch.active = true;
                } else if (!user_automatic_login && autologin_switch.active) {
                    autologin_switch.active = false;
                }
            }

            var user_locked = user.get_locked ();
            if (user_locked) {
                enable_user_button.label = _("Enable Account");
                enable_user_button.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);
            } else {
                enable_user_button.label = _("Disable Account");
                enable_user_button.remove_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);
            }

            if (delta_user.language != user.get_language ()) {
                update_language ();
            }

            delta_user.update ();
        }

        public void update_real_name () {
            full_name_entry.set_text (user.get_real_name ());
        }

        public void update_account_type () {
            if (user.get_account_type () == Act.UserAccountType.ADMINISTRATOR)
                user_type_dropdown.set_active (1);
            else
                user_type_dropdown.set_active (0);
        }

        public void update_language () {
            string user_lang = user.get_language ();
            // If accountsservice doesn't have a specific language for the user, then get the system locale
            if (user_lang == null || user_lang.length == 0) {
                // If we can't get a system locale either, fall back to displaying the user as using en_US
                user_lang = get_system_locale () ?? "en_US.UTF-8";
            }

            string user_lang_code;
            if (!Gnome.Languages.parse_locale (user_lang, out user_lang_code, null, null, null)) {
                // If we somehow still ended up with an invalid locale, display the user as using English
                user_lang_code = "en";
            }

            if (user != get_current_user ()) {
                var languages = get_languages ();
                language_store = new Gtk.ListStore (2, typeof (string), typeof (string));
                Gtk.TreeIter iter;

                language_dropdown.set_model (language_store);

                foreach (string language in languages) {
                    language_store.insert (out iter, 0);
                    language_store.set (iter, 0, language, 1, Gnome.Languages.get_language_from_code (language, null));
                    if (user_lang_code == language)
                        language_dropdown.set_active_iter (iter);
                }

            } else {
                var language = Gnome.Languages.get_language_from_code (user_lang_code, null);
                language_button.set_label (language);
            }
        }

        public void update_region (string? language) {
            Gtk.TreeIter? iter;

            if (language == null) {
                Value cell;

                language_dropdown.get_active_iter (out iter);
                language_store.get_value (iter, 0, out cell);
                language = (string)cell;
            }

            var regions = get_regions (language);
            region_store = new Gtk.ListStore (2, typeof (string), typeof (string));
            bool iter_set = false;

            region_box.set_model (region_store);

            string user_lang = user.get_language ();
            // If accountsservice doesn't have a specific language for the user, then get the system locale
            if (user_lang == null || user_lang.length == 0) {
                // If we can't get a system locale either, fall back to displaying the user as using en_US
                user_lang = get_system_locale () ?? "en_US.UTF-8";
            }

            string user_region_code;
            if (!Gnome.Languages.parse_locale (user_lang, null, out user_region_code, null, null)) {
                // If we somehow still ended up with an invalid locale, display the region as US
                user_region_code = "US";
            }

            foreach (string region in regions) {
                region_store.insert (out iter, 0);
                region_store.set (iter, 0, region, 1, Gnome.Languages.get_country_from_code (region, null));
                if (user_region_code == region) {
                    region_box.set_active_iter (iter);
                    iter_set = true;
                }
            }

            if (!iter_set) {
                Gtk.TreeIter? active_iter = null;

                Gtk.TreeModelForeachFunc check_region_store = (model, path, iter) => {
                    Value cell;
                    region_store.get_value (iter, 0, out cell);

                    if (default_regions != null && default_regions.has_key (language)
                    && default_regions.@get (language) == "%s_%s".printf (language, (string)cell))
                        active_iter = iter;

                    return false;
                };
                region_store.foreach (check_region_store);
                if (active_iter == null)
                    region_store.get_iter_first (out active_iter);

                region_box.set_active_iter (active_iter);
            }
        }

        private void change_lock () {
            var permission = get_permission ();
            if (!permission.allowed) {
                try {
                    permission.acquire ();
                } catch (Error e) {
                    critical (e.message);
                    return;
                }
            }

            var user_locked = user.get_locked ();
            if (user_locked) {
                user.set_password_mode (Act.UserPasswordMode.REGULAR);
            } else {
                user.set_automatic_login (false);
            }

            user.set_locked (!user_locked);
        }

        private void change_password (Act.UserPasswordMode mode, string? new_password) {
            if (get_permission ().allowed) {
                switch (mode) {
                    case Act.UserPasswordMode.REGULAR:
                        if (new_password != null) {
                            debug ("Setting new password for %s".printf (user.get_user_name ()));
                            user.set_password (new_password, "");
                        }
                        break;
                    case Act.UserPasswordMode.NONE:
                        debug ("Setting no password for %s".printf (user.get_user_name ()));
                        user.set_password_mode (Act.UserPasswordMode.NONE);
                        break;
                    case Act.UserPasswordMode.SET_AT_LOGIN:
                        debug ("Setting password mode to SET_AT_LOGIN for %s".printf (user.get_user_name ()));
                        user.set_password_mode (Act.UserPasswordMode.SET_AT_LOGIN);
                        break;
                    default: break;
                }
            } else if (user == get_current_user ()) {
                if (new_password != null) {
                    // we are going to assume that if a normal user calls this method,
                    // he is authenticated against the PasswdHandler
                    Passwd.passwd_change_password (get_passwd_handler (), new_password, (h, e) => {
                        if (e != null) {
                            var dialog = new Granite.MessageDialog (
                                _("Unable to change the password for %s").printf (user.get_real_name ()),
                                e.message,
                                new ThemedIcon ("dialog-password")
                            ) {
                                badge_icon = new ThemedIcon ("dialog-error"),
                                transient_for = (Gtk.Window) get_root ()
                            };
                            dialog.present ();
                            dialog.response.connect (dialog.destroy);
                        } else {
                            debug ("Setting new password for %s (user context)".printf (user.get_user_name ()));
                        }
                    });
                }
            }
        }
    }
}
