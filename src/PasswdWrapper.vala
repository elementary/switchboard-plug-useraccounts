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
	public enum PasswdState {
		NONE,
		AUTH,
		NEW,
		RETYPE,
		DONE,
		ERR
	}
	public class PasswdWrapper : Object {
		private Pid child_pid;
		private int standard_input;
		private int standard_output;
		private int standard_error;

		private IOChannel stdout;
		private IOChannel stdin;
		//private Passwd.Error error = Passwd.Error.REJECTED;

		public PasswdWrapper () { }

		public bool spawn_passwd () {
			try {
				string[] spawn_args = {"/usr/bin/passwd"};
				string[] spawn_env = Environ.set_variable (Environ.get (), "LC_ALL", "C", true);
				

				Process.spawn_async_with_pipes ("/",
					spawn_args,
					spawn_env,
					SpawnFlags.SEARCH_PATH | SpawnFlags.DO_NOT_REAP_CHILD,
					null,
					out child_pid,
					out standard_input,
					out standard_output,
					out standard_error);
			} catch (SpawnError e) {
				critical ("Error: %s".printf (e.message));
				return false;
			}

			if (Posix.dup2 (standard_error, standard_output) == -1) {
				critical ("action failed!");
				return false;
			}

			stdout = new IOChannel.unix_new (standard_output);
			stdin = new IOChannel.unix_new (standard_input);

			return true;
		}
	}
}
