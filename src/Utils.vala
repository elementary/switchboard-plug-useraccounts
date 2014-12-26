/*-
 * Copyright (c) 2014 Marvin Beckers <beckersmarvin@gmail.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Marvin Beckers <beckersmarvin@gmail.com>
 * Authored by: Switchboard Locale Plug Developers
 */

namespace SwitchboardPlugUserAccounts {
	private static string[]? installed_languages = null;

	public static string[]? get_installed_languages () {
		if (installed_languages != null)
			return installed_languages;

		string output;
		int status;

		try {
			Process.spawn_sync (null, 
				{"/usr/share/language-tools/language-options" , null}, 
				Environ.get (),
				SpawnFlags.SEARCH_PATH,
				null,
				out output,
				null,
				out status);

				installed_languages = output.split("\n");
				return installed_languages;
		} catch (Error e) {
			return null;
		}
	}

	private static Polkit.Permission? permission = null;
	
	public static Polkit.Permission? get_permission () {
		if (permission != null)
			return permission;
		try {
			permission = new Polkit.Permission.sync ("org.freedesktop.accounts.user-administration", Polkit.UnixProcess.new (Posix.getpid ()));
			return permission;
		} catch (Error e) {
			critical (e.message);
			return null;
		}
	}

	private static Act.UserManager? usermanager = null;
	
	public static unowned Act.UserManager? get_usermanager () {
		if (usermanager != null && usermanager.is_loaded)
			return usermanager;

		usermanager = Act.UserManager.get_default ();
		return usermanager;
	}

	private static Act.User? current_user = null;

	public static unowned Act.User? get_current_user () {
		if (current_user != null)
			return current_user;

		current_user = get_usermanager ().get_user (GLib.Environment.get_user_name ());
		return current_user;
	}

	public static void create_new_user (string fullname, string username, Act.UserAccountType usertype, string? pw) {
		if (get_permission ().allowed) {
			try {
				Act.User created_user = get_usermanager ().create_user (username, fullname, usertype);
				get_usermanager ().user_added.connect ((user) => {
					if (user == created_user) {
						created_user.set_locked (false);
							if (pw == null)
								created_user.set_password_mode (Act.UserPasswordMode.SET_AT_LOGIN);
							else if (pw != "")
								created_user.set_password (pw, "");
					}
				});
			} catch (Error e) {
				critical ("Creation for user '%s' failed".printf (username));
			}
		}
	}
}
