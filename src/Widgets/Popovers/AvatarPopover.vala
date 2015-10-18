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
    public class AvatarPopover : Gtk.Popover {
        private weak Act.User    user;
        private weak UserUtils   utils;
        private Gtk.Grid          button_grid;

        private Dialogs.AvatarDialog    avatar_dialog;

        public signal void create_selection_dialog ();

        public AvatarPopover (Gtk.Widget relative, Act.User user, UserUtils utils) {
            this.user = user;
            this.utils = utils;
            set_relative_to (relative);
            set_position (Gtk.PositionType.BOTTOM);
            set_modal (true);

            build_ui ();
        }

        private void build_ui () {
            Gtk.Button remove_button = new Gtk.Button.with_label (_("Remove"));
            remove_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
            remove_button.clicked.connect (() => utils.change_avatar (null));

            Gtk.Button select_button = new Gtk.Button.with_label (_("Set from File…"));
            select_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
            select_button.clicked.connect (select_from_file);
            select_button.grab_focus ();

            button_grid = new Gtk.Grid ();
            button_grid.margin = 6;
            button_grid.column_spacing = 6;
            button_grid.column_homogeneous = true;

            button_grid.add (remove_button);
            button_grid.add (select_button);
            add (button_grid);

            if (user.get_icon_file ().contains (".face"))
                remove_button.set_sensitive (false);
            else {
                remove_button.set_sensitive (true);
            }
        }

        private void select_from_file () {
            var file_dialog = new Gtk.FileChooserDialog (_("Select an image"),
            get_parent_window () as Gtk.Window?, Gtk.FileChooserAction.OPEN, _("Cancel"),
            Gtk.ResponseType.CANCEL, _("Open"), Gtk.ResponseType.ACCEPT);

            Gtk.FileFilter filter = new Gtk.FileFilter ();
            filter.set_filter_name (_("Images"));
            file_dialog.set_filter (filter);
            filter.add_mime_type ("image/jpeg");
            filter.add_mime_type ("image/jpg");
            filter.add_mime_type ("image/png");

            // Add a preview widget
            Gtk.Image preview_area = new Gtk.Image ();
            file_dialog.set_preview_widget (preview_area);
            file_dialog.update_preview.connect (() => {
                string uri = file_dialog.get_preview_uri ();
                // We only display local files:
                if (uri != null && uri.has_prefix ("file://") == true) {
                    try {
                        Gdk.Pixbuf pixbuf = new Gdk.Pixbuf.from_file_at_scale (uri.substring (7), 150, 150, true);
                        preview_area.set_from_pixbuf (pixbuf);
                        preview_area.show ();
                        file_dialog.set_preview_widget_active (true);
                    } catch (Error e) {
                        preview_area.hide ();
                        file_dialog.set_preview_widget_active (false);
                    }
                } else {
                    preview_area.hide ();
                    file_dialog.set_preview_widget_active (false);
                }
            });

            if (file_dialog.run () == Gtk.ResponseType.ACCEPT) {
                var path = file_dialog.get_file ().get_path ();
                file_dialog.hide ();
                file_dialog.destroy ();
                avatar_dialog = new Dialogs.AvatarDialog (path);
                avatar_dialog.request_avatar_change.connect (utils.change_avatar);
            } else
                file_dialog.close ();
        }
    }
}
