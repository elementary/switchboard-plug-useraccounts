/***
Copyright (C) 2015 Marvin Beckers
              2015 Rico Tzschichholz
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

namespace GuestSessionToggle {

	const string LIGHTDM_CONF = "/etc/lightdm/lightdm.conf";
	const string LIGHTDM_CONF_D = "/usr/share/lightdm/lightdm.conf.d/";
	const string GUEST_SESSION_CONF = LIGHTDM_CONF_D + "60-guest-session.conf";
	
	const string ALLOW_GUEST_TRUE = "allow-guest=true";
	const string ALLOW_GUEST_FALSE = "allow-guest=false";

	const OptionEntry[] options = {
		{ "show", 0, 0, OptionArg.NONE, ref SHOW, "Show whether guest-session is enabled", null },
		{ "on", 0, 0, OptionArg.NONE, ref ON, "Enable guest-session", null },
		{ "off", 0, 0, OptionArg.NONE, ref OFF, "Disable guest-session", null },
		{ null }
	};

	static bool SHOW;
	static bool ON;
	static bool OFF;

	public static int main (string[] args) {
		var context = new OptionContext (null);
		context.add_main_entries (options, null);
			
		try {
			context.parse (ref args);
		} catch (OptionError e) {
			printerr ("%s\n", e.message);
			return Posix.EXIT_FAILURE;
		}

		bool enabled = true;
		try {
			enabled = get_allow_guest ();
		} catch (FileError e) {
			printerr ("%s\n", e.message);
			return Posix.EXIT_FAILURE;
		}

		if (SHOW) {
			if (enabled)
				print ("on\n");
			else
				print ("off\n");

			return Posix.EXIT_SUCCESS;
		}
			
		var uid = Posix.getuid ();

		if (uid > 0) {
			printerr ("Must be run from administrative context\n");
			return Posix.EXIT_FAILURE;
		}
				
		if (ON && !enabled)
			toggle (true);
		else if (OFF && enabled)
			toggle (false);

		return Posix.EXIT_SUCCESS;
	}

	private void toggle (bool enable) {
		if (set_allow_guest (LIGHTDM_CONF, enable))
			return;
		
		Dir config_dir = Dir.open (LIGHTDM_CONF_D);
		unowned string? name;
		string? file;
			
		while ((name = config_dir.read_name ()) != null) {
			file = LIGHTDM_CONF_D + name;
			if (set_allow_guest (file, enable))
				return;
		}

		if (!enable) {
			FileUtils.set_contents (GUEST_SESSION_CONF, "[SeatDefaults]\n" + ALLOW_GUEST_FALSE + "\n");
		}
	}

	private bool set_allow_guest (string file, bool enable) {
		bool success = false;
		string? contents;
		string? new_contents;

		try {
			FileUtils.get_contents (file, out contents);

			if (contents.index_of (ALLOW_GUEST_FALSE) > -1 && enable) {
				new_contents = file.replace (ALLOW_GUEST_FALSE, ALLOW_GUEST_TRUE);
				FileUtils.set_contents (file, new_contents);
				success = true;
			} else if (contents.index_of (ALLOW_GUEST_TRUE) > -1 && !enable) {
				new_contents = file.replace (ALLOW_GUEST_TRUE, ALLOW_GUEST_FALSE);
				FileUtils.set_contents (file, new_contents);
				success = true;
			}
		} catch (FileError e) {
			printerr ("%s\n", e.message);
		}

		return success;
	}

	private bool get_allow_guest () throws FileError {
		string? contents;
		
		FileUtils.get_contents (LIGHTDM_CONF, out contents);
		if (contents.index_of (ALLOW_GUEST_FALSE) > -1)
			return false;

		Dir config_dir = Dir.open (LIGHTDM_CONF_D);
		unowned string? name = null;
		while ((name = config_dir.read_name ()) != null) {
			FileUtils.get_contents (LIGHTDM_CONF_D + name, out contents);
			if (contents.index_of (ALLOW_GUEST_FALSE) > -1)
				return false;
		}
		
		return true;
	}
}
