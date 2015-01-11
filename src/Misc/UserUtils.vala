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

namespace SwitchboardPlugUserAccounts {
    public class UserUtils {
        private unowned Act.User user;
        private unowned Widgets.UserSettings widget;

        public UserUtils (Act.User _user, Widgets.UserSettings _widget) {
            user = _user;
            widget = _widget;
        }

        public void change_avatar (Gdk.Pixbuf? _pixbuf) {
            if (get_current_user () == user || get_permission ().allowed) {
                if (_pixbuf != null) {
                    var path = Path.build_filename (Environment.get_tmp_dir (), "user-icon-0");
                    int i = 0;
                    while (FileUtils.test (path, FileTest.EXISTS)) {
                        path = Path.build_filename (Environment.get_tmp_dir (), "user-icon-%d".printf (i));
                        i++;
                    }
                    try {
                        debug ("Saving temporary avatar file to %s".printf (path));
                        _pixbuf.savev (path, "png", {}, {});
                        debug ("Setting avatar icon file for %s from temporary file %s".printf (user.get_user_name (), path));
                        user.set_icon_file (path);
                    } catch (Error e) {
                        critical (e.message);
                    }
                } else {
                    debug ("Setting no avatar icon file for %s".printf (user.get_user_name ()));
                    user.set_icon_file ("");
                }
            }
        }

        public void change_full_name (string _new_full_name) {
            if (get_current_user () == user || get_permission ().allowed) {
                if (_new_full_name != user.get_real_name ()) {
                    debug ("Setting real name for %s to %s".printf (user.get_user_name (), _new_full_name));
                    user.set_real_name (_new_full_name);
                } else
                    widget.update_ui ();
            }
        }

        public void change_user_type (int _new_user_type) {
            if (get_permission ().allowed) {
                if (user.get_account_type () == Act.UserAccountType.STANDARD && _new_user_type == 1) {
                    debug ("Setting account type for %s to Administrator".printf (user.get_user_name ()));
                    user.set_account_type (Act.UserAccountType.ADMINISTRATOR);
                } else if (user.get_account_type () == Act.UserAccountType.ADMINISTRATOR
                            && _new_user_type == 0 && !is_last_admin (user)) {
                    debug ("Setting account type for %s to Standard".printf (user.get_user_name ()));
                    user.set_account_type (Act.UserAccountType.STANDARD);
                } else
                    widget.update_ui ();
            }
        }

        public void change_language (string _new_lang) {
            if (get_current_user () == user || get_permission ().allowed) {
                string current_lang = "";
                if (user.get_language ().length == 2)
                    current_lang = Gnome.Languages.get_language_from_code (user.get_language (), null);
                else if (user.get_language ().length == 5)
                    current_lang = Gnome.Languages.get_language_from_locale (user.get_language (), null);

                string new_lang_code = "";
                foreach (string s in get_installed_languages ()) {
                    if (s.length == 2 && Gnome.Languages.get_language_from_code (s, null) == _new_lang) {
                        new_lang_code = s;
                        break;
                    } else if (s.length == 5 && Gnome.Languages.get_language_from_locale (s, null) == _new_lang) {
                        new_lang_code = s;
                        break;
                    }
                }

                if (_new_lang != user.get_language ()) {
                    debug ("Setting language for %s to %s".printf (user.get_user_name (), new_lang_code));
                    user.set_language (new_lang_code);
                } else
                    widget.update_ui ();
            }
        }

        public void change_autologin (bool _autologin) {
            if (get_permission ().allowed) {
                if (user.get_automatic_login () && !_autologin) {
                    debug ("Removing automatic login for %s".printf (user.get_user_name ()));
                    user.set_automatic_login (false);
                } else if (!user.get_automatic_login () && _autologin) {
                    debug ("Setting automatic login for %s".printf (user.get_user_name ()));
                    foreach (Act.User temp_user in get_usermanager ().list_users ()) {
                        if (temp_user.get_automatic_login () && temp_user != user)
                            temp_user.set_automatic_login (false);
                    }
                    user.set_automatic_login (true);
                }
            }
        }

        public void change_password (Act.UserPasswordMode _mode, string? _new_password) {
            if (get_permission ().allowed) {
                switch (_mode) {
                    case Act.UserPasswordMode.REGULAR:
                        if (_new_password != null) {
                            debug ("Setting new password for %s".printf (user.get_user_name ()));
                            user.set_password (_new_password, "");
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
                if (_new_password != null) {
                    // we are going to assume that if a normal user calls this method,
                    // he is authenticated against the PasswdHandler
                    Passwd.passwd_change_password (get_passwd_handler (), _new_password, (h, e) => {
                        if (e != null) {
                            warning ("Password change for %s failed".printf (user.get_user_name ()));
                            warning (e.message);
                            get_pe_notifier ().set_error (e.message);
                        } else
                            debug ("Setting new password for %s (user context)".printf (user.get_user_name ()));
                    });
                }
            }
        }

        public void change_lock () {
            if (get_permission ().allowed && get_current_user () != user) {
                if (user.get_locked ()) {
                    debug ("Unlocking user %s".printf (user.get_user_name ()));
                    user.set_password_mode (Act.UserPasswordMode.NONE);
                    user.set_locked (false);
                } else {
                    debug ("Locking user %s".printf (user.get_user_name ()));
                    user.set_automatic_login (false);
                    user.set_locked (true);
                }
            }
        }
    }
}
