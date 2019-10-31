/*
* Copyright 2014-2019 elementary, Inc. (https://elementary.io)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*/

public class SwitchboardPlugUserAccounts.InfobarNotifier : Object {
    public string error_message { get; set; default = ""; }
    public bool reboot_required { get; set; default = false; }

    private static GLib.Once<InfobarNotifier> instance;

    private InfobarNotifier () { }

    public static unowned InfobarNotifier get_default () {
        return instance.once (() => { return new InfobarNotifier (); });
    }
}
