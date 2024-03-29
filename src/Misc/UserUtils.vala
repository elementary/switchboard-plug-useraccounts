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

namespace SwitchboardPlugUserAccounts {
    public class UserUtils {
        private unowned Act.User user;
        private unowned Widgets.UserSettingsView widget;

        public UserUtils (Act.User user, Widgets.UserSettingsView widget) {
            this.user = user;
            this.widget = widget;
        }

        public void change_full_name (string new_full_name) {
            if (get_current_user () == user || get_permission ().allowed) {
                if (new_full_name != user.get_real_name ()) {
                    debug ("Setting real name for %s to %s".printf (user.get_user_name (), new_full_name));
                    user.set_real_name (new_full_name);
                } else
                    widget.update_real_name ();
            }
        }

        public void change_user_type (int new_user_type) {
            if (get_permission ().allowed) {
                if (user.get_account_type () == Act.UserAccountType.STANDARD && new_user_type == 1) {
                    debug ("Setting account type for %s to Administrator".printf (user.get_user_name ()));
                    user.set_account_type (Act.UserAccountType.ADMINISTRATOR);
                } else if (user.get_account_type () == Act.UserAccountType.ADMINISTRATOR
                            && new_user_type == 0 && !is_last_admin (user)) {
                    debug ("Setting account type for %s to Standard".printf (user.get_user_name ()));
                    user.set_account_type (Act.UserAccountType.STANDARD);
                } else
                    widget.update_account_type ();
            }
        }

        public void change_language (string new_lang) {
            if (get_current_user () == user || get_permission ().allowed) {
                if (new_lang != "" && new_lang != user.get_language ()) {
                    debug ("Setting language for %s to %s".printf (user.get_user_name (), new_lang));
                    user.set_language (new_lang);
                } else {
                    widget.update_language ();
                    widget.update_region (null);
                }
            }
        }

        public void change_autologin (bool new_autologin) {
            if (get_permission ().allowed) {
                if (user.get_automatic_login () && !new_autologin) {
                    debug ("Removing automatic login for %s".printf (user.get_user_name ()));
                    user.set_automatic_login (false);
                } else if (!user.get_automatic_login () && new_autologin) {
                    debug ("Setting automatic login for %s".printf (user.get_user_name ()));
                    foreach (Act.User temp_user in get_usermanager ().list_users ()) {
                        if (temp_user.get_automatic_login () && temp_user != user)
                            temp_user.set_automatic_login (false);
                    }
                    user.set_automatic_login (true);
                }
            }
        }
    }
}
