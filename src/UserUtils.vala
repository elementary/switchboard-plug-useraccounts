/***
Copyright (C) 2014-2015 Marvin Beckers
This program is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License version 3, as published
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
						_pixbuf.savev (path, "png", {}, {});
						user.set_icon_file (path);
					} catch (Error e) {
						critical (e.message);
					}
				} else {
					user.set_icon_file ("");
				}
			}
		}

		public void change_full_name (string _new_full_name) {
			if (_new_full_name != user.get_real_name ()) {
				if (get_current_user () == user || get_permission ().allowed)
					user.set_real_name (_new_full_name);
				else
					widget.update_ui ();
			}
		}

		public void change_user_type (int _user_type) {
			if (get_permission ().allowed) {
				if (user.get_account_type () == Act.UserAccountType.STANDARD && _user_type == 1)
					user.set_account_type (Act.UserAccountType.ADMINISTRATOR);
				else if (user.get_account_type () == Act.UserAccountType.ADMINISTRATOR && _user_type == 0 && !is_last_admin (user))
					user.set_account_type (Act.UserAccountType.STANDARD);
				else
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

				if (_new_lang != user.get_language ())
					user.set_language (new_lang_code);
				else
					widget.update_ui ();
			}
		}

		public void change_autologin (bool _autologin) {
			if (get_permission ().allowed) {
				if (user.get_automatic_login () && !_autologin) {
					user.set_automatic_login (false);
				} else if (!user.get_automatic_login () && _autologin) {
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
						if (_new_password != null)
							user.set_password (_new_password, "");
						break;
					case Act.UserPasswordMode.NONE:
						user.set_password_mode (Act.UserPasswordMode.NONE);
						break;
					case Act.UserPasswordMode.SET_AT_LOGIN:
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
							warning ("password change failed");
							warning (e.message);
							get_pe_notifier ().set_error (e.message);
						}
					});
				}
			}
		}

		public void change_lock () {
			if (get_permission ().allowed && get_current_user () != user) {
				if (user.get_locked ()) {
					user.set_password_mode (Act.UserPasswordMode.NONE);
					user.set_locked (false);
				} else {
					user.set_automatic_login (false);
					user.set_locked (true);
				}
			}
		}
	}
}
