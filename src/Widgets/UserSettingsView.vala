/***
  Copyright (C) 2014-2015 Switchboard User Accounts Plug Developer
  This program is free software: you can redistribute it and/or modify it
  under the terms of the GNU Lesser General Public License version 3, as published
  by the Free Software Foundation.

  This program is distributed in the hope that it will be useful, but
  WITHOUT ANY WARRANTY; without even the implied warranties of
  MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
  PURPOSE. See the GNU General Public License for more details.

  You should have received a copy of the GNU General Public License along
  with this program. If not, see http://www.gnu.org/licenses/.
***/

namespace SwitchboardPlugUserAccounts.Widgets {
    public class UserSettingsView : Gtk.Grid {
        private unowned Act.User   user;
        private UserUtils           utils;
        private DeltaUser           delta_user;

        private Gtk.ListStore       language_store;
        private Gtk.ListStore       region_store;

        private Gtk.Image           avatar;
        private Gdk.Pixbuf?         avatar_pixbuf;
        private Gtk.Button          avatar_button;
        private Gtk.Entry           full_name_entry;
        private Gtk.Button          password_button;
        private Gtk.Button          enable_user_button;
        private Gtk.ComboBoxText    user_type_box;
        private Gtk.ComboBox        language_box;
        private Gtk.Revealer        region_revealer;
        private Gtk.ComboBox        region_box;
        private Gtk.Button          language_button;
        private Gtk.Switch          autologin_switch;

        //lock widgets
        private Gtk.Image           full_name_lock;
        private Gtk.Image           user_type_lock;
        private Gtk.Image           language_lock;
        private Gtk.Image           autologin_lock;
        private Gtk.Image           password_lock;
        private Gtk.Image           enable_lock;

        private const string no_permission_string   = _("You do not have permission to change this");
        private const string current_user_string    = _("You cannot change this for the currently active user");
        private const string last_admin_string      = _("You cannot remove the last administrator's privileges");

        public UserSettingsView (Act.User user) {
            this.user = user;
            utils = new UserUtils (this.user, this);
            delta_user = new DeltaUser (this.user);
            build_ui ();
            this.user.changed.connect (update_ui);
        }
        
        public void build_ui () {
            margin = 20;
            set_row_spacing (10);
            set_column_spacing (20);
            set_valign (Gtk.Align.START);
            set_halign (Gtk.Align.CENTER);

            avatar_button = new Gtk.Button ();
            avatar_button.set_relief (Gtk.ReliefStyle.NONE);
            avatar_button.clicked.connect (() => {
                InfobarNotifier.get_default ().unset_error ();
                AvatarPopover avatar_popover = new AvatarPopover (avatar_button, user, utils);
                avatar_popover.show_all ();
            });
            attach (avatar_button, 0, 0, 1, 1);

            full_name_entry = new Gtk.Entry ();
            full_name_entry.set_size_request (175, 0);
            full_name_entry.get_style_context ().add_class ("h3");
            full_name_entry.activate.connect (() => {
                InfobarNotifier.get_default ().unset_error ();
                utils.change_full_name (full_name_entry.get_text ());
            });
            attach (full_name_entry, 1, 0, 1, 1);

            var user_type_label = new Gtk.Label (_("Account type:"));
            user_type_label.halign = Gtk.Align.END;
            attach (user_type_label,0, 1, 1, 1);

            user_type_box = new Gtk.ComboBoxText ();
            user_type_box.append_text (_("Standard"));
            user_type_box.append_text (_("Administrator"));
            user_type_box.changed.connect (() => {
                InfobarNotifier.get_default ().unset_error ();
                utils.change_user_type (user_type_box.get_active ());
            });
            attach (user_type_box, 1, 1, 1, 1);

            var lang_label = new Gtk.Label (_("Language:"));
            lang_label.halign = Gtk.Align.END;
            attach (lang_label, 0, 2, 1, 1);

            if (user != get_current_user ()) {
                language_box = new Gtk.ComboBox ();
                language_box.set_sensitive (false);
                language_box.changed.connect (() => {
                    InfobarNotifier.get_default ().unset_error ();

                    Gtk.TreeIter? iter;
                    Value cell;

                    language_box.get_active_iter (out iter);
                    language_store.get_value (iter, 0, out cell);

                    if (get_regions ((string)cell).size == 0) {
                        region_revealer.set_reveal_child (false);
                        if (user.get_language () != (string)cell)
                            utils.change_language ((string)cell);
                    } else {
                        region_revealer.set_reveal_child (true);
                        region_box.set_no_show_all (false);
                        update_region ((string)cell);
                    }
                });
                attach (language_box, 1, 2, 1, 1);

                var renderer = new Gtk.CellRendererText ();
                language_box.pack_start (renderer, true);
                language_box.add_attribute (renderer, "text", 1);

                region_box = new Gtk.ComboBox ();
                region_box.set_sensitive (false);
                region_box.changed.connect (() => {
                    InfobarNotifier.get_default ().unset_error ();

                    string new_language;
                    Gtk.TreeIter? iter;
                    Value cell;

                    language_box.get_active_iter (out iter);
                    language_store.get_value (iter, 0, out cell);
                    new_language = (string)cell;

                    region_box.get_active_iter (out iter);
                    region_store.get_value (iter, 0, out cell);
                    new_language += "_%s".printf ((string)cell);

                    if (new_language != "" && new_language != user.get_language ())
                        utils.change_language (new_language);
                });

                region_revealer = new Gtk.Revealer ();
                region_revealer.set_transition_type (Gtk.RevealerTransitionType.SLIDE_DOWN);
                region_revealer.set_transition_duration (350);
                region_revealer.set_reveal_child (true);
                region_revealer.add (region_box);
                attach (region_revealer, 1, 3, 1, 1);

                renderer = new Gtk.CellRendererText ();
                region_box.pack_start (renderer, true);
                region_box.add_attribute (renderer, "text", 1);

            } else {
                language_button = new Gtk.Button ();
                language_button.set_size_request (0, 27);
                language_button.set_relief (Gtk.ReliefStyle.NONE);
                language_button.halign = Gtk.Align.START;
                language_button.set_tooltip_text (_("Click to switch to Language & Locale Settings"));
                language_button.clicked.connect (() => {
                    InfobarNotifier.get_default ().unset_error ();
                    //TODO locale plug might change its codename because that's not okay currently
                    var command = new Granite.Services.SimpleCommand (
                            Environment.get_home_dir (),
                            "/usr/bin/switchboard -o system-pantheon-locale");
                    command.run ();
                    return;
                });
                attach (language_button, 1, 2, 1, 1);
            }

            var login_label = new Gtk.Label (_("Log In automatically:"));
            login_label.halign = Gtk.Align.END;
            login_label.margin_top = 20;
            attach (login_label, 0, 4, 1, 1);

            autologin_switch = new Gtk.Switch ();
            autologin_switch.hexpand = true;
            autologin_switch.halign = Gtk.Align.START;
            autologin_switch.margin_top = 20;
            autologin_switch.notify["active"].connect (() => utils.change_autologin (autologin_switch.get_active ()));
            attach (autologin_switch, 1, 4, 1, 1);

            var change_password_label = new Gtk.Label (_("Password:"));
            change_password_label.halign = Gtk.Align.END;
            attach (change_password_label, 0, 5, 1, 1);

            password_button = new Gtk.Button ();
            password_button.set_relief (Gtk.ReliefStyle.NONE);
            password_button.halign = Gtk.Align.START;
            password_button.clicked.connect (() => {
                InfobarNotifier.get_default ().unset_error ();
                Widgets.PasswordPopover pw_popover = new Widgets.PasswordPopover (password_button, user);
                pw_popover.show_all ();
                pw_popover.request_password_change.connect (utils.change_password);
            });
            attach (password_button, 1, 5, 1, 1);

            enable_user_button = new Gtk.Button ();
            enable_user_button.clicked.connect (utils.change_lock);
            enable_user_button.set_sensitive (false);
            enable_user_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
            enable_user_button.set_size_request (0, 27);
            attach (enable_user_button, 1, 6, 1, 1);

            full_name_lock = new Gtk.Image.from_icon_name ("changes-prevent-symbolic", Gtk.IconSize.BUTTON);
            full_name_lock.set_tooltip_text (no_permission_string);
            attach (full_name_lock, 2, 0, 1, 1);

            user_type_lock = new Gtk.Image.from_icon_name ("changes-prevent-symbolic", Gtk.IconSize.BUTTON);
            user_type_lock.set_tooltip_text (no_permission_string);
            attach (user_type_lock, 2, 1, 1, 1);

            language_lock = new Gtk.Image.from_icon_name ("changes-prevent-symbolic", Gtk.IconSize.BUTTON);
            language_lock.set_tooltip_text (no_permission_string);
            attach (language_lock, 2, 2, 1, 2);

            autologin_lock = new Gtk.Image.from_icon_name ("changes-prevent-symbolic", Gtk.IconSize.BUTTON);
            autologin_lock.set_tooltip_text (no_permission_string);
            autologin_lock.margin_top = 20;
            attach (autologin_lock, 2, 4, 1, 1);

            password_lock = new Gtk.Image.from_icon_name ("changes-prevent-symbolic", Gtk.IconSize.BUTTON);
            password_lock.set_tooltip_text (no_permission_string);
            attach (password_lock, 2, 5, 1, 1);

            enable_lock = new Gtk.Image.from_icon_name ("changes-prevent-symbolic", Gtk.IconSize.BUTTON);
            enable_lock.set_tooltip_text (no_permission_string);
            attach (enable_lock, 2, 6, 1, 1);

            update_ui ();
            get_permission ().notify["allowed"].connect (update_ui);
        }

        public void update_ui () {
            if (!get_permission ().allowed) {
                user_type_box.set_sensitive (false);
                password_button.set_sensitive (false);
                autologin_switch.set_sensitive (false);
                enable_user_button.set_sensitive (false);

                user_type_lock.set_opacity (0.5);
                autologin_lock.set_opacity (0.5);
                password_lock.set_opacity (0.5);
                enable_lock.set_opacity (0.5);

                user_type_lock.set_tooltip_text (no_permission_string);
                enable_lock.set_tooltip_text (no_permission_string);
            } else if (get_current_user () == user) {
                user_type_lock.set_tooltip_text (current_user_string);
                enable_lock.set_tooltip_text (current_user_string);
            } else if (is_last_admin (user)) {
                user_type_lock.set_tooltip_text (last_admin_string);
                enable_lock.set_tooltip_text (last_admin_string);
            }

            if (get_current_user () == user || get_permission ().allowed) {
                avatar_button.set_sensitive (true);
                full_name_entry.set_sensitive (true);
                full_name_lock.set_opacity (0);
                language_lock.set_opacity (0);

                if (!user.get_locked ()) {
                    password_button.set_sensitive (true);
                    password_lock.set_opacity (0);
                }

                if (get_permission ().allowed) {
                    if (!user.get_locked ()) {
                        autologin_switch.set_sensitive (true);
                        autologin_lock.set_opacity (0);
                    }
                    if (!is_last_admin (user) && get_current_user () != user) {
                        user_type_box.set_sensitive (true);
                        user_type_lock.set_opacity (0);
                    }
                }
 
                if (get_current_user () != user) {
                    language_box.set_sensitive (true);
                    region_box.set_sensitive (true);
                }
            } else {
                avatar_button.set_sensitive (false);
                full_name_entry.set_sensitive (false);
                full_name_lock.set_opacity (0.5);
                language_lock.set_opacity (0.5);

                if (get_current_user () != user) {
                    language_box.set_sensitive (false);
                    region_box.set_sensitive (false);
                }
            }

            if (get_permission ().allowed && get_current_user () != user && !is_last_admin (user)) {
                enable_user_button.set_sensitive (true);
                enable_lock.set_opacity (0);
                if (!user.get_locked ())
                    enable_user_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
            }

            //only update widgets if the user property has changed since last ui update
            if (delta_user.real_name != user.get_real_name ())
                update_real_name ();
            if (delta_user.icon_file != user.get_icon_file ())
                update_avatar ();
            if (delta_user.account_type != user.get_account_type ())
                update_account_type ();
            if (delta_user.password_mode != user.get_password_mode ())
                update_password ();
            if (delta_user.automatic_login != user.get_automatic_login ())
                update_autologin ();
            if (delta_user.locked != user.get_locked ())
                update_lock_state ();
            if (delta_user.language != user.get_language ())
                update_language ();

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

        public void update_autologin () {
            if (user.get_automatic_login () && !autologin_switch.get_active ())
                autologin_switch.set_active (true);
            else if (!user.get_automatic_login () && autologin_switch.get_active ())
                autologin_switch.set_active (false);
        }

        public void update_lock_state () {
            if (user.get_locked ()) {
                enable_user_button.set_label (_("Enable User Account"));
                enable_user_button.get_style_context ().remove_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
            } else if (!user.get_locked ())
                enable_user_button.set_label (_("Disable User Account"));
        }

        public void update_password () {
            if (user.get_password_mode () == Act.UserPasswordMode.NONE || user.get_locked ())
                password_button.set_label (_("None set"));
            else
                password_button.set_label ("**********");
        }

        public void update_avatar () {
            try {
                avatar_pixbuf = new Gdk.Pixbuf.from_file_at_scale (user.get_icon_file (), 72, 72, true);
                if (avatar == null)
                    avatar = new Gtk.Image.from_pixbuf (avatar_pixbuf);
                else
                    avatar.set_from_pixbuf (avatar_pixbuf);
            } catch (Error e) {
                Gtk.IconTheme icon_theme = Gtk.IconTheme.get_default ();
                try {
                    avatar_pixbuf = icon_theme.load_icon ("avatar-default", 72, 0);
                    avatar = new Gtk.Image.from_pixbuf (avatar_pixbuf);
                } catch (Error e) { }
            }
            avatar_button.set_image (avatar);
        }

        public void update_language () {
            if (user != get_current_user ()) {
                var languages = get_languages ();
                language_store = new Gtk.ListStore (2, typeof (string), typeof (string));
                Gtk.TreeIter iter;
 
                language_box.set_model (language_store);

                foreach (string language in languages) {
                    language_store.insert (out iter, 0);
                    language_store.set (iter, 0, language, 1, Gnome.Languages.get_language_from_code (language, null));
                    if (user.get_language ().slice (0, 2) == language)
                        language_box.set_active_iter (iter);
                }

            } else {
                var language = Gnome.Languages.get_language_from_code (user.get_language ().slice (0, 2), null);
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

            foreach (string region in regions) {
                region_store.insert (out iter, 0);
                region_store.set (iter, 0, region, 1, Gnome.Languages.get_country_from_code (region, null));
                if (user.get_language ().length == 5 && user.get_language ().slice (3, 5) == region) {
                    region_box.set_active_iter (iter);
                    iter_set = true;
                }
            }

            if (!iter_set) {
                Gtk.TreeIter? active_iter;
                region_store.get_iter_first (out active_iter);
                region_box.set_active_iter (active_iter);
            }
        }
    }
}
