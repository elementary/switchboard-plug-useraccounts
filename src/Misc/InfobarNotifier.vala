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
    public class InfobarNotifier : Object {
        private bool        error = false;
        private string      error_message = "";
        private bool        reboot = false;

        public signal void  error_notified ();
        public signal void  reboot_notified ();

        public InfobarNotifier () { }

        public void set_error (string error_message) {
            error = true;
            this.error_message = error_message;
            error_notified ();
        }

        public void unset_error () {
            error = false;
            error_message = "";
            error_notified ();
        }

        public bool is_error () {
            return error;
        }

        public void set_reboot () {
            reboot = true;
            reboot_notified ();
        }

        public bool is_reboot () {
            return reboot;
        }

        public string get_error_message () {
            return error_message;
        }

        private static GLib.Once<InfobarNotifier> instance;

        public static unowned InfobarNotifier get_default () {
            return instance.once (() => { return new InfobarNotifier (); });
        }
    }
}
