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

        private Gtk.ListStore language_store;
        private Gtk.ListStore region_store;

        private Adw.Avatar avatar;
        private Gtk.Entry full_name_entry;
        private Gtk.Button password_button;
        private Gtk.Button enable_user_button;
        private Gtk.ComboBoxText user_type_box;
        private Gtk.ComboBox language_box;
        private Gtk.ComboBox region_box;
        private Gtk.Button language_button;
        private Gtk.Switch autologin_switch;

        //lock widgets
        private Gtk.Image user_type_lock;
        private Gtk.Image language_lock;
        private Gtk.Image autologin_lock;
        private Gtk.Image password_lock;

        private Gee.HashMap<string, string>? default_regions;

        public signal void remove_user ();

        private const string NO_PERMISSION_STRING = _("You do not have permission to change this");
        private const string CURRENT_USER_STRING = _("You cannot change this for the currently active user");
        private const string LAST_ADMIN_STRING = _("You cannot remove the last administrator's privileges");

        public UserSettingsView (Act.User user) {
            Object (user: user);
        }

        class construct {
            set_css_name ("simplesettingspage");
        }

        construct {
            utils = new UserUtils (user, this);
            delta_user = new DeltaUser (user);

            default_regions = get_default_regions ();

            avatar = new Adw.Avatar (48, user.real_name, true) {
                margin_top = 6,
                margin_end = 6,
                margin_bottom = 6
            };

            var avatar_popover = new AvatarPopover (user, utils);
            avatar_popover.add_css_class (Granite.STYLE_CLASS_MENU);

            var avatar_button = new Gtk.MenuButton () {
                halign = END,
                valign = END,
                icon_name = "edit-symbolic",
                popover = avatar_popover
            };
            avatar_button.get_first_child ().add_css_class (Granite.STYLE_CLASS_CIRCULAR);

            var avatar_overlay = new Gtk.Overlay () {
                child = avatar
            };
            avatar_overlay.add_overlay (avatar_button);

            full_name_entry = new Gtk.Entry () {
                hexpand = true,
                valign = CENTER
            };
            full_name_entry.add_css_class (Granite.STYLE_CLASS_H2_LABEL);
            full_name_entry.activate.connect (() => {
                utils.change_full_name (full_name_entry.get_text ().strip ());
            });

            user_type_box = new Gtk.ComboBoxText () {
                hexpand = true
            };
            user_type_box.append_text (_("Standard"));
            user_type_box.append_text (_("Administrator"));
            user_type_box.changed.connect (() => {
                utils.change_user_type (user_type_box.active);
            });

            var user_type_label = new Granite.HeaderLabel (_("Account Type")) {
                mnemonic_widget = user_type_box
            };

            var lang_label = new Granite.HeaderLabel (_("Language"));

            var grid = new Gtk.Grid () {
                column_spacing = 6,
                row_spacing = 6,
                vexpand = true
            };

            if (user != get_current_user ()) {
                var renderer = new Gtk.CellRendererText ();

                language_box = new Gtk.ComboBox () {
                    sensitive = false
                };
                language_box.pack_start (renderer, true);
                language_box.add_attribute (renderer, "text", 1);

                renderer = new Gtk.CellRendererText ();

                region_box = new Gtk.ComboBox () {
                    sensitive = false
                };
                region_box.pack_start (renderer, true);
                region_box.add_attribute (renderer, "text", 1);

                var region_revealer = new Gtk.Revealer () {
                    child = region_box,
                    transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
                    reveal_child = true
                };

                grid.attach (language_box, 0, 3, 2);
                grid.attach (region_revealer, 0, 4, 2);

                language_box.changed.connect (() => {
                    Gtk.TreeIter? iter;
                    Value cell;

                    language_box.get_active_iter (out iter);
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

                    language_box.get_active_iter (out iter);
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
                    tooltip_text = _("Click to switch to Language & Locale Settings")
                };

                grid.attach (language_button, 0, 3, 2);
            }

            var login_label = new Gtk.Label (_("Log In automatically:")) {
                halign = Gtk.Align.END,
                margin_top = 20
            };

            autologin_switch = new Gtk.Switch () {
                halign = Gtk.Align.START,
                margin_top = 24
            };
            autologin_switch.notify["active"].connect (() => utils.change_autologin (autologin_switch.active));

            password_button = new Gtk.Button.with_label (_("Change Password…")) {
                halign = END
            };
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

            var remove_user_button = new Gtk.Button.with_label (_("Remove User Account")) {
                sensitive = false
            };
            remove_user_button.add_css_class (Granite.STYLE_CLASS_DESTRUCTIVE_ACTION);
            remove_user_button.clicked.connect (() => remove_user ());

            user_type_lock = new Gtk.Image.from_icon_name ("changes-prevent-symbolic") {
                tooltip_text = NO_PERMISSION_STRING
            };
            user_type_lock.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);

            language_lock = new Gtk.Image.from_icon_name ("changes-prevent-symbolic") {
                tooltip_text = NO_PERMISSION_STRING
            };
            language_lock.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);

            autologin_lock = new Gtk.Image.from_icon_name ("changes-prevent-symbolic") {
                margin_top = 20,
                tooltip_text = NO_PERMISSION_STRING
            };
            autologin_lock.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);

            password_lock = new Gtk.Image.from_icon_name ("changes-prevent-symbolic") {
                margin_end = 6,
                tooltip_text = NO_PERMISSION_STRING
            };
            password_lock.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);

            var remove_lock = new Gtk.Image.from_icon_name ("changes-prevent-symbolic") {
                margin_start = 6,
                tooltip_text = NO_PERMISSION_STRING
            };
            remove_lock.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);

            var header_grid = new Gtk.Grid () {
                column_spacing = 12
            };
            header_grid.add_css_class ("header-area");
            header_grid.attach (avatar_overlay, 0, 0);
            header_grid.attach (full_name_entry, 1, 0);

            var autologin_box = new Gtk.Box (HORIZONTAL, 6);
            autologin_box.append (login_label);
            autologin_box.append (autologin_switch);
            autologin_box.append (autologin_lock);

            grid.attach (user_type_label, 0, 0);
            grid.attach (user_type_lock, 1, 0);
            grid.attach (user_type_box, 0, 1, 2);
            grid.attach (lang_label, 0, 2);
            grid.attach (language_lock, 1, 2);
            grid.attach (autologin_box, 0, 5, 2);
            grid.add_css_class ("content-area");

            var action_area = new Gtk.Box (HORIZONTAL, 0);
            action_area.append (remove_user_button);
            action_area.append (enable_user_button);
            action_area.append (remove_lock);
            action_area.append (new Gtk.Grid () { hexpand = true });
            action_area.append (password_lock);
            action_area.append (password_button);
            action_area.add_css_class ("buttonbox");

            margin_top = 6;
            margin_end = 12;
            margin_bottom = 12;
            margin_start = 12;
            orientation = VERTICAL;
            append (header_grid);
            append (grid);
            append (action_area);

            update_ui ();
            update_permission ();

            if (get_current_user () == user) {
                user_type_lock.tooltip_text = CURRENT_USER_STRING;
                remove_lock.tooltip_text = CURRENT_USER_STRING;
            } else if (is_last_admin (user)) {
                user_type_lock.tooltip_text = LAST_ADMIN_STRING;
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

            if (!allowed) {
                user_type_box.sensitive = false;
                password_button.sensitive = false;
                autologin_switch.sensitive = false;

                user_type_lock.set_opacity (1);
                autologin_lock.set_opacity (1);
                password_lock.set_opacity (1);

                user_type_lock.tooltip_text = NO_PERMISSION_STRING;
            }

            if (current_user || allowed) {
                full_name_entry.sensitive = true;
                full_name_entry.secondary_icon_name = "";
                language_lock.set_opacity (0);

                if (!user_locked) {
                    password_button.sensitive = true;
                    password_lock.set_opacity (0);
                } else {
                    password_button.sensitive = false;
                    password_lock.set_opacity (1);
                }

                if (allowed) {
                    if (!user_locked) {
                        autologin_switch.sensitive = true;
                        autologin_lock.set_opacity (0);
                    } else {
                        autologin_switch.sensitive = false;
                        autologin_lock.set_opacity (1);
                    }

                    if (!last_admin && !current_user) {
                        user_type_box.sensitive = true;
                        user_type_lock.set_opacity (0);
                    }
                }

                if (!current_user) {
                    language_box.sensitive = true;
                    region_box.sensitive = true;
                }
            } else {
                full_name_entry.sensitive = false;
                full_name_entry.secondary_icon_name = "changes-prevent-symbolic";
                full_name_entry.secondary_icon_tooltip_text = NO_PERMISSION_STRING;

                if (!current_user) {
                    language_box.sensitive = false;
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
                enable_user_button.label = _("Enable User Account");
                enable_user_button.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);
            } else {
                enable_user_button.label = _("Disable User Account");
                enable_user_button.get_style_context ().remove_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);
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
                user_type_box.set_active (1);
            else
                user_type_box.set_active (0);
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

                language_box.set_model (language_store);

                foreach (string language in languages) {
                    language_store.insert (out iter, 0);
                    language_store.set (iter, 0, language, 1, Gnome.Languages.get_language_from_code (language, null));
                    if (user_lang_code == language)
                        language_box.set_active_iter (iter);
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

                language_box.get_active_iter (out iter);
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
