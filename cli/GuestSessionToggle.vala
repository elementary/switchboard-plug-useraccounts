/***
Copyright (C) 2015 Marvin Beckers
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
	public class ToggleApp : Application {
		public ToggleApp () { }

		public new int run (string[]? argv = null) {
			int uid = (int) Posix.getuid ();
			bool status = true;
			try {
				status = get_status ();
			} catch (Error e) {
				return 1;
			}

			if (argv.length == 2 && argv[1] == "--show") {
				if (status)
					stdout.printf ("on\n");
				else
					stdout.printf ("off\n");

				return 0;
			}
			
			if (uid == 0) {
				if (argv.length == 2) {
					if (argv[1] == "--on" && !status) {
						//toggle now to ON
						try {
							toggle (true);
						} catch (Error e) {
							stdout.printf ("%s\n".printf (e.message));
						}
					} else if (argv[1] == "--off" && status) {
						//toggle now to OFF
						try {
							toggle (false);
						} catch (Error e) {
							stdout.printf ("%s\n".printf (e.message));
						}
					} else
						stdout.printf ("Unknown option\n");
				} else {
					stdout.printf ("No option specified. Use --on, --off or --show\n");
				}
				return 0;
			} else {
				stdout.printf ("Must be run from administrative context\n");
				return 1;
			}
		}

		private void toggle (bool status) throws Error {
			string? file = null;
			string? out_file = null;
			FileUtils.get_contents ("/etc/lightdm/lightdm.conf", out file);
				if (file.index_of ("allow-guest=false") > -1 && status) {
					out_file = file.replace ("allow-guest=false", "allow-guest=true");
					FileUtils.set_contents ("/etc/lightdm/lightdm.conf", out_file);
					return;
				} else if (file.index_of ("allow-guest=true") > -1 && !status) {
					out_file = file.replace ("allow-guest=true", "allow-guest=false");
					FileUtils.set_contents ("/etc/lightdm/lightdm.conf", out_file);
					return;
				}

			string directory = "/usr/share/lightdm/lightdm.conf.d/";
			Dir config_dir = Dir.open (directory);
			string? name = null;
			string? path =  null;
				
			while ((name = config_dir.read_name ()) != null) {
				path = Path.build_filename (directory, name);
				file = null;
				FileUtils.get_contents (path, out file);

				if (file.index_of ("allow-guest=false") > -1 && status) {
					out_file = file.replace ("allow-guest=false", "allow-guest=true");
					FileUtils.set_contents (path, out_file);
					return;
				} else if (file.index_of ("allow-guest=true") > -1 && !status) {
					out_file = file.replace ("allow-guest=true", "allow-guest=false");
					FileUtils.set_contents (path, out_file);
					return;
				}
			}

			if (!status) {
				var new_file = File.new_for_path ("/usr/share/lightdm/lightdm.conf.d/60-guest-session.conf");
				var stream = new_file.create (FileCreateFlags.NONE);
				stream.close ();
				var new_content = "[SeatDefaults]\nallow-guest=false\n";
				FileUtils.set_contents ("/usr/share/lightdm/lightdm.conf.d/60-guest-session.conf", new_content);
			}
		}

		private bool get_status () throws Error {
				string? file = null;
				FileUtils.get_contents ("/etc/lightdm/lightdm.conf", out file);
				if (file.index_of ("allow-guest=false") > -1)
						return false;

				string directory = "/usr/share/lightdm/lightdm.conf.d/";
				Dir config_dir = Dir.open (directory);
				string? name = null;
				string? path =  null;
				
				while ((name = config_dir.read_name ()) != null) {
					path = Path.build_filename (directory, name);
					file = null;
					FileUtils.get_contents (path, out file);

					if (file.index_of ("allow-guest=false") > -1)
						return false;
				}
				return true;
		}

		public static int main (string[] args) {
			var application = new ToggleApp ();
			return application.run (args);
		}
	}
}
