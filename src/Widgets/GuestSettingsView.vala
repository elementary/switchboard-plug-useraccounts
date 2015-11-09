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

namespace SwitchboardPlugUserAccounts.Widgets {
    public class GuestSettingsView : Gtk.Grid {
        private Gtk.Switch  guest_switch;
        private Gtk.Image   guest_lock;

        public signal void guest_switch_changed ();

        private const string no_permission_string = _("You do not have permission to change this");

        public GuestSettingsView () {
            vexpand = false;
            valign = Gtk.Align.CENTER;
            halign = Gtk.Align.CENTER;
            margin_left = 64;
            margin_right = 64;
            border_width = 24;
            row_spacing = 12;
            column_spacing = 12;

            build_ui ();
            update_ui ();

            get_permission ().notify["allowed"].connect (update_ui);
        }

        private void build_ui () {
            Granite.Widgets.Avatar image = new Granite.Widgets.Avatar.with_default_icon (72);
            image.valign = Gtk.Align.START;

            var header_label = new Gtk.Label (_("Guest Session"));
            header_label.halign = Gtk.Align.START;
            header_label.use_markup = true;
            header_label.set_label (@"<span font_weight=\"bold\" size=\"x-large\">%s</span>".printf (header_label.get_label ()));

            guest_switch = new Gtk.Switch ();
            guest_switch.halign = Gtk.Align.START;
            guest_switch.notify["active"].connect (() => {
                if (get_guest_session_state () != guest_switch.active) {
                    InfobarNotifier.get_default ().set_reboot ();
                    set_guest_session_state (guest_switch.active);
                    guest_switch_changed ();
                }
            });

            guest_lock = new Gtk.Image.from_icon_name ("changes-prevent-symbolic", Gtk.IconSize.BUTTON);
            guest_lock.halign = Gtk.Align.START;
            guest_lock.set_opacity (0.5);
            guest_lock.set_tooltip_text (no_permission_string);

            Gtk.Label label = new Gtk.Label ("%s %s".printf (
                _("The Guest Session allows someone to use a temporary default account without a password."),
                _("Once they log out, all of their settings and data will be deleted.")));
            label.set_line_wrap (true);
            ((Gtk.Misc) label).xalign = 0;

            attach (image, 0, 0, 1, 3);
            attach (header_label, 1, 0, 1, 1);
            attach (guest_switch, 1, 1, 1, 1);
            attach (guest_lock, 2, 1, 1, 1);
            attach (label, 1, 2, 1, 1);

            show_all ();
        }

        public void update_ui () {
            if (get_permission ().allowed)
                guest_lock.set_opacity (0);
            else
                guest_lock.set_opacity (0.5);

            if (guest_switch.get_sensitive () != get_permission ().allowed)
                guest_switch.set_sensitive (get_permission ().allowed);
            if (guest_switch.get_active () != get_guest_session_state ())
                guest_switch.set_active (get_guest_session_state ());
        }
    }
}