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
 * Authored by: Corentin Noël <tintou@mailoo.org>
 * Authored by: Marvin Beckers <beckersmarvin@gmail.com>
 */

namespace SwitchboardPlugUsers {
    public static Plug plug;
	public unowned Act.UserManager usermanager;

    public class Plug : Switchboard.Plug {
		private Widgets.UserView userview;

        public Plug () {
            Object (category: Category.SYSTEM,
                    code_name: Build.PLUGCODENAME,
                    display_name: _("Users Accounts"),
                    description: _("Manage user accounts on your local system."),
                    icon: "system-users");
            plug = this;
			
        }

        public override Gtk.Widget get_widget () {
            if (userview != null)
                return userview;

			userview = new Widgets.UserView ();
			userview.show_all ();

            return userview;
        }

        public override void shown () { }
        public override void hidden () { }
        public override void search_callback (string location) { }

        // 'search' returns results like ("Keyboard → Behavior → Duration", "keyboard<sep>behavior")
        public override async Gee.TreeMap<string, string> search (string search) {
            return new Gee.TreeMap<string, string> (null, null);
        }
    }
}

public Switchboard.Plug get_plug (Module module) {
    debug ("Activating Users plug");
    var plug = new SwitchboardPlugUsers.Plug ();
    return plug;
}
