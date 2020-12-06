/*
* Copyright (c) 2014-2018 elementary, Inc. (https://elementary.io)
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
*
* Authored by: Marvin Beckers <beckersmarvin@gmail.com>
*/

public class SwitchboardPlugUserAccounts.DeltaUser : Object {
    public weak Act.User user { get; construct; }

    public string? real_name { public get; private set; }
    public Act.UserAccountType? account_type { public get; private set; }
    public bool automatic_login { public get; private set; }
    public bool locked { public get; private set; }
    public Act.UserPasswordMode? password_mode { public get; private set; }
    public string? language { public get; private set; }

    public DeltaUser (Act.User user) {
        Object (user: user);
    }

    construct {
        //set all properties to null to be sure widgets will be updated on first load
        real_name = null;
        account_type = null;
        automatic_login = false;
        locked = false;
        password_mode = null;
        language = null;
    }

    public void update () {
        real_name = user.get_real_name ();
        account_type = user.get_account_type ();
        automatic_login = user.get_automatic_login ();
        locked = user.get_locked ();
        password_mode = user.get_password_mode ();
        language = user.get_language ();
    }
}
