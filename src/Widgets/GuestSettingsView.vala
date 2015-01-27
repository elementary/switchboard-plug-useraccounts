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
        private Gtk.Switch guest_switch;
        private Gtk.Image guest_lock;
        public signal void guest_switch_changed ();

        private const string no_permission_string = _("You do not have permission to change this");

        public GuestSettingsView () {
            vexpand = false;
            valign = Gtk.Align.CENTER;
            halign = Gtk.Align.CENTER;
            margin_left = 96;
            margin_right = 96;
            border_width = 24;
            row_spacing = 24;
            column_spacing = 12;

            build_ui ();
            update_ui ();

            get_permission ().notify["allowed"].connect (update_ui);
        }

        private void build_ui () {
            Gtk.Grid sub_grid = new Gtk.Grid ();
            sub_grid.hexpand = true;
            sub_grid.halign = Gtk.Align.START;
            sub_grid.column_spacing = 10;
            attach (sub_grid, 0, 0, 2, 1);

            Gtk.Image image = new Gtk.Image ();
            image.valign = Gtk.Align.START;
            image.halign = Gtk.Align.END;
            image.margin_right = 12;
            try {
                Gtk.IconTheme icon_theme = Gtk.IconTheme.get_default ();
                Gdk.Pixbuf image_pixbuf = icon_theme.load_icon ("avatar-default", 72, 0);
                image.set_from_pixbuf (image_pixbuf);
            } catch (Error e) { }
            sub_grid.attach (image, 0, 0, 1, 2);

            var header_label = new Gtk.Label (_("Guest Session"));
            header_label.hexpand = true;
            header_label.use_markup = true;
            header_label.set_label (@"<span font_weight=\"bold\" size=\"x-large\">%s</span>".printf (header_label.get_label ()));
            //header_label.get_style_context ().add_class ("h2");
            header_label.halign = Gtk.Align.START;
            header_label.valign = Gtk.Align.END;
            header_label.justify = Gtk.Justification.FILL;

            sub_grid.attach (header_label, 1, 0, 2, 1);

            guest_switch = new Gtk.Switch ();
            guest_switch.hexpand = true;
            guest_switch.halign = Gtk.Align.START;
            guest_switch.notify["active"].connect (() => {
                if (get_guest_session_state () != guest_switch.active) {
                    InfobarNotifier.get_default ().set_reboot ();
                    set_guest_session_state (guest_switch.active);
                    guest_switch_changed ();
                }
            });
            sub_grid.attach (guest_switch, 1, 1, 1, 1);

            guest_lock = new Gtk.Image.from_icon_name ("changes-prevent-symbolic", Gtk.IconSize.BUTTON);
            guest_lock.set_opacity (0.5);
            guest_lock.set_tooltip_text (no_permission_string);
            sub_grid.attach (guest_lock, 2, 1, 1, 1);

            Gtk.Label label = new Gtk.Label ("%s %s".printf (
                _("The Guest Session allows someone to use a temporary default account without a password."),
                _("Once they log out, all of their settings and data will be deleted.")));
            label.justify = Gtk.Justification.FILL;
            label.valign = Gtk.Align.START;
            label.set_line_wrap (true);
            label.margin_left = 82;
            attach (label, 1, 1, 1, 1);

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
