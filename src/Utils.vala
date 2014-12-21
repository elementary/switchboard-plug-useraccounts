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

namespace SwitchboardPlugUsers {
	public class Utils : Object {
		public Utils () { }

		public static string[]? get_installed_languages () {

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

					return output.split("\n");

			} catch (Error e) {
				return null;
			}
		}

		public static string translate_language (string lang) {
			Intl.textdomain ("iso_639");
			var lang_name = dgettext ("iso_639", lang);
			lang_name = dgettext ("iso_639_3", lang);
			return lang_name;
		}
	}
}
