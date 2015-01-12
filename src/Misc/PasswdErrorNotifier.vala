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
    public class PasswdErrorNotifier : Object {
        private bool error = false;
        private string error_message = "";

        public signal void notified ();

        public PasswdErrorNotifier () { }

        public void set_error (string error_message) {
            error = true;
            this.error_message = error_message;
            notified ();
        }

        public void unset_error () {
            error = false;
            error_message = "";
            notified ();
        }

        public bool is_error () {
            return error;
        }

        public string get_error_message () {
            return error_message;
        }

        private static GLib.Once<PasswdErrorNotifier> instance;

        public static unowned PasswdErrorNotifier get_default () {
            return instance.once (() => { return new PasswdErrorNotifier (); });
        }
    }
}
