/*
* Copyright (c) 2014-2019 elementary, Inc. (https://elementary.io)
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

public class SwitchboardPlugUserAccounts.Dialogs.AvatarDialog : Granite.MessageDialog {
    public signal void request_avatar_change (Gdk.Pixbuf pixbuf);

    public string pixbuf_path { get; construct; }

    private Widgets.CropView cropview;

    public AvatarDialog (string pixbuf_path) {
        Object (
            image_icon: new ThemedIcon ("image-crop"),
            primary_text: _("Crop & Position"),
            secondary_text: _("Choose the part of the image to use as an avatar."),
            pixbuf_path: pixbuf_path,
            buttons: Gtk.ButtonsType.CANCEL
        );
    }

    construct {
        var button_change = add_button (_("Change Avatar"), Gtk.ResponseType.OK);
        button_change.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);

        response.connect (on_response);

        try {
            var pixbuf = new Gdk.Pixbuf.from_file (pixbuf_path).apply_embedded_orientation ();

            cropview = new Widgets.CropView (pixbuf, 400);
            cropview.add_css_class (Granite.STYLE_CLASS_CARD);
            cropview.add_css_class (Granite.STYLE_CLASS_CHECKERBOARD);

            custom_bin.append (cropview);
        } catch (Error e) {
            critical (e.message);
            button_change.sensitive = false;
        }
    }

    private void on_response (Gtk.Dialog source, int response_id) {
        if (response_id == Gtk.ResponseType.OK) {
            var pixbuf = cropview.get_selection ();
            if (pixbuf.get_width () > 200) {
                request_avatar_change (pixbuf.scale_simple (200, 200, Gdk.InterpType.BILINEAR));
            } else {
                request_avatar_change (pixbuf);
            }
        }
        destroy ();
    }
}
