/*
* Copyright 2014-2020 elementary, Inc. (https://elementary.io)
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

namespace SwitchboardPlugUserAccounts.Widgets {
    public class AvatarPopover : Gtk.Popover {
        public signal void create_selection_dialog ();
        public Act.User user { get; construct; }
        public UserUtils utils { get; construct; }

        public AvatarPopover (Gtk.Widget relative_to, Act.User user, UserUtils utils) {
            Object (modal: true,
                    position: Gtk.PositionType.BOTTOM,
                    relative_to: relative_to,
                    user: user,
                    utils: utils);
        }

        construct {
            var remove_button = new Gtk.ModelButton () {
                text = _("Remove")
            };
            remove_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);

            var select_button = new Gtk.ModelButton () {
                text = _("Set from File…")
            };
            select_button.grab_focus ();

            var gravatar_button = new Gtk.ModelButton () {
                text = _("Download from Gravatar…")
            };

            var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
                margin_top = 3,
                margin_bottom = 3
            };

            var button_grid = new Gtk.Grid () {
                margin_bottom = 3,
                margin_top = 3
            };
            button_grid.attach (select_button, 0, 0);
            button_grid.attach (gravatar_button, 0, 1);
            button_grid.attach (separator, 0, 2);
            button_grid.attach (remove_button, 0, 3);
            add (button_grid);

            if (user.get_icon_file ().contains (".face")) {
                remove_button.sensitive = false;
            } else {
                remove_button.sensitive = true;
            }

            remove_button.clicked.connect (() => change_avatar (null));
            select_button.clicked.connect (select_from_file);
            gravatar_button.clicked.connect (download_from_gravatar);
        }

        private void download_from_gravatar () {
            if (get_current_user () != user) {
                var permission = get_permission ();
                if (!permission.allowed) {
                    try {
                        permission.acquire ();
                    } catch (Error e) {
                        critical (e.message);
                        return;
                    }
                }
            }

            var email_address = "danielle@elementary.io";

            //TODO: Create a dialog if user.email is blank or null

            var uri = "https://secure.gravatar.com/avatar/%s?d=404&s=%d".printf (
                Checksum.compute_for_string (ChecksumType.MD5, email_address.strip ().down ()),
                128
            );
            var server_file = File.new_for_uri (uri);
            var path = Path.build_filename (Environment.get_tmp_dir (), server_file.get_basename ());
            var local_file = File.new_for_path (path);

            if (!local_file.query_exists (null)) {
                server_file.copy (local_file, FileCopyFlags.OVERWRITE, null, null);
            }

            user.set_icon_file (path);
        }

        private void select_from_file () {
            var filter = new Gtk.FileFilter ();
            filter.set_filter_name (_("Images"));
            filter.add_mime_type ("image/jpeg");
            filter.add_mime_type ("image/jpg");
            filter.add_mime_type ("image/png");

            var preview_area = new Gtk.Image ();
            preview_area.pixel_size = 256;
            preview_area.margin_end = 12;

            var file_dialog = new Gtk.FileChooserNative (
                _("Select an image"),
                get_parent_window () as Gtk.Window?,
                Gtk.FileChooserAction.OPEN,
                _("Open"),
                _("Cancel")
            );
            file_dialog.filter = filter;
            file_dialog.set_preview_widget (preview_area);
            file_dialog.update_preview.connect (() => {
                string uri = file_dialog.get_preview_uri ();
                if (uri != null && uri.has_prefix ("file://")) {
                    try {
                        var pixbuf = new Gdk.Pixbuf.from_file_at_scale (
                            file_dialog.get_file ().get_path (),
                            preview_area.pixel_size,
                            preview_area.pixel_size,
                            true
                        ).apply_embedded_orientation ();
                        preview_area.set_from_pixbuf (pixbuf);
                    } catch (Error e) {
                        preview_area.hide ();
                    }
                } else {
                    preview_area.hide ();
                }
            });

            if (file_dialog.run () == Gtk.ResponseType.ACCEPT) {
                var path = file_dialog.get_file ().get_path ();
                file_dialog.hide ();
                file_dialog.destroy ();
                var avatar_dialog = new Dialogs.AvatarDialog (path);
                avatar_dialog.request_avatar_change.connect (change_avatar);
            } else {
                file_dialog.destroy ();
            }
        }

        private void change_avatar (Gdk.Pixbuf? new_pixbuf) {
            if (get_current_user () != user) {
                var permission = get_permission ();
                if (!permission.allowed) {
                    try {
                        permission.acquire ();
                    } catch (Error e) {
                        critical (e.message);
                        return;
                    }
                }
            }

            if (new_pixbuf != null) {
                var path = Path.build_filename (Environment.get_tmp_dir (), "user-icon-0");
                int i = 0;
                while (FileUtils.test (path, FileTest.EXISTS)) {
                    path = Path.build_filename (Environment.get_tmp_dir (), "user-icon-%d".printf (i));
                    i++;
                }
                try {
                    debug ("Saving temporary avatar file to %s".printf (path));
                    new_pixbuf.savev (path, "png", {}, {});
                    debug ("Setting avatar icon file for %s from temporary file %s".printf (user.get_user_name (), path));
                    user.set_icon_file (path);
                } catch (Error e) {
                    critical (e.message);
                }
            } else {
                debug ("Setting no avatar icon file for %s".printf (user.get_user_name ()));
                user.set_icon_file ("");
            }
        }
    }
}
