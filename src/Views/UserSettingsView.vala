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
    public class UserSettingsView : Gtk.Grid {
        public weak Act.User user { get; construct; }

        private UserUtils utils;
        private DeltaUser delta_user;

        private Gtk.ListStore language_store;
        private Gtk.ListStore region_store;

        private Adw.Avatar avatar;
        private Gtk.ToggleButton avatar_button;
        private Gtk.Entry full_name_entry;
        private Gtk.Button password_button;
        private Gtk.Button enable_user_button;
        private Gtk.ComboBoxText user_type_box;
        private Gtk.ComboBox language_box;
        private Gtk.ComboBox region_box;
        private Gtk.Button language_button;
        private Gtk.Switch autologin_switch;

        //lock widgets
        private Gtk.Image full_name_lock;
        private Gtk.Image user_type_lock;
        private Gtk.Image language_lock;
        private Gtk.Image autologin_lock;
        private Gtk.Image password_lock;
        private Gtk.Image enable_lock;

        private Gee.HashMap<string, string>? default_regions;

        public signal void remove_user ();

        private const string NO_PERMISSION_STRING = _("You do not have permission to change this");
        private const string CURRENT_USER_STRING = _("You cannot change this for the currently active user");
        private const string LAST_ADMIN_STRING = _("You cannot remove the last administrator's privileges");

        public UserSettingsView (Act.User user) {
            Object (
                column_spacing: 12,
                halign: Gtk.Align.CENTER,
                margin: 24,
                row_spacing: 6,
                user: user
            );
        }

        construct {
            utils = new UserUtils (user, this);
            delta_user = new DeltaUser (user);

            default_regions = get_default_regions ();

            avatar = new Adw.Avatar (64, user.real_name, true);
            avatar.set_image_load_func (avatar_image_load_func);

            avatar_button = new Gtk.ToggleButton () {
                halign = Gtk.Align.END
            };
            avatar_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
            avatar_button.add (avatar);

            avatar_button.toggled.connect (() => {
                if (avatar_button.active) {
                    AvatarPopover avatar_popover = new AvatarPopover (avatar_button, user, utils);
                    avatar_popover.show_all ();
                    avatar_popover.hide.connect (() => { avatar_button.active = false;});
                }
            });

            full_name_entry = new Gtk.Entry () {
                valign = Gtk.Align.CENTER
            };
            full_name_entry.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);
            full_name_entry.activate.connect (() => {
                utils.change_full_name (full_name_entry.get_text ().strip ());
            });

            var user_type_label = new Gtk.Label (_("Account type:")) {
                halign = Gtk.Align.END
            };

            user_type_box = new Gtk.ComboBoxText ();
            user_type_box.append_text (_("Standard"));
            user_type_box.append_text (_("Administrator"));
            user_type_box.changed.connect (() => {
                utils.change_user_type (user_type_box.active);
            });

            var lang_label = new Gtk.Label (_("Language:")) {
                halign = Gtk.Align.END
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
                    transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
                    reveal_child = true
                };
                region_revealer.add (region_box);

                attach (language_box, 1, 2);
                attach (region_revealer, 1, 3);

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

                attach (language_button, 1, 2);
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

            var remove_user_button = new Gtk.Button.with_label (_("Remove User Account")) {
                sensitive = false
            };
            remove_user_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
            remove_user_button.clicked.connect (() => remove_user ());

            full_name_lock = new Gtk.Image.from_icon_name ("changes-prevent-symbolic", Gtk.IconSize.BUTTON) {
                tooltip_text = NO_PERMISSION_STRING
            };
            full_name_lock.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

            user_type_lock = new Gtk.Image.from_icon_name ("changes-prevent-symbolic", Gtk.IconSize.BUTTON) {
                tooltip_text = NO_PERMISSION_STRING
            };
            user_type_lock.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

            language_lock = new Gtk.Image.from_icon_name ("changes-prevent-symbolic", Gtk.IconSize.BUTTON) {
                tooltip_text = NO_PERMISSION_STRING
            };
            language_lock.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

            autologin_lock = new Gtk.Image.from_icon_name ("changes-prevent-symbolic", Gtk.IconSize.BUTTON) {
                margin_top = 20,
                tooltip_text = NO_PERMISSION_STRING
            };
            autologin_lock.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

            password_lock = new Gtk.Image.from_icon_name ("changes-prevent-symbolic", Gtk.IconSize.BUTTON) {
                tooltip_text = NO_PERMISSION_STRING
            };
            password_lock.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

            enable_lock = new Gtk.Image.from_icon_name ("changes-prevent-symbolic", Gtk.IconSize.BUTTON);
            enable_lock.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

            var remove_lock = new Gtk.Image.from_icon_name ("changes-prevent-symbolic", Gtk.IconSize.BUTTON) {
                tooltip_text = NO_PERMISSION_STRING
            };
            remove_lock.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

            attach (avatar_button, 0, 0);
            attach (full_name_entry, 1, 0);
            attach (user_type_label, 0, 1);
            attach (user_type_box, 1, 1);
            attach (lang_label, 0, 2);
            attach (login_label, 0, 4);
            attach (autologin_switch, 1, 4);
            attach (password_button, 1, 5);
            attach (enable_user_button, 1, 6);
            attach (remove_user_button, 1, 7);
            attach (full_name_lock, 2, 0);
            attach (user_type_lock, 2, 1);
            attach (language_lock, 2, 2, 1, 2);
            attach (autologin_lock, 2, 4);
            attach (password_lock, 2, 5);
            attach (enable_lock, 2, 6);
            attach (remove_lock, 2, 7);

            update_ui ();
            update_permission ();

            if (get_current_user () == user) {
                enable_lock.tooltip_text = CURRENT_USER_STRING;
                user_type_lock.tooltip_text = CURRENT_USER_STRING;
                remove_lock.tooltip_text = CURRENT_USER_STRING;
            } else if (is_last_admin (user)) {
                enable_lock.tooltip_text = LAST_ADMIN_STRING;
                user_type_lock.tooltip_text = LAST_ADMIN_STRING;
                remove_lock.tooltip_text = LAST_ADMIN_STRING;
            } else {
                enable_user_button.sensitive = true;
                enable_lock.set_opacity (0);

                remove_user_button.sensitive = true;
                remove_lock.set_opacity (0);
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
                full_name_lock.set_opacity (0);
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
            avatar.set_image_load_func (avatar_image_load_func);

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
                enable_user_button.get_style_context ().add_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);
            } else {
                enable_user_button.label = _("Disable User Account");
                enable_user_button.get_style_context ().remove_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);
            }

            if (delta_user.language != user.get_language ()) {
                update_language ();
            }

            delta_user.update ();
            show_all ();
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

        private Gdk.Pixbuf? avatar_image_load_func (int size) {
            try {
                return new Gdk.Pixbuf.from_file_at_scale (user.get_icon_file (), size, size, true);
            } catch (Error e) {
                return null;
            }
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
                            dialog.show_all ();
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
