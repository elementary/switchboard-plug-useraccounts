//  
//  Copyright (C) 2011 Avi Romanoff <aviromanoff@gmail.com>
// 
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
// 
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
// 
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
// 


const string WALLPAPER_DIR = "/usr/share/backgrounds";

// Helper class for the file IO functions we'll need
// Not needed at all, but helpful for organization
public class IOHelper : GLib.Object {

    // Check if the filename has a picture file extension.
    public static bool is_valid_file_type (string fname) {

        // Cache a lowe-cased copy of the file name
        string fname_down = fname.down();
        // Short-circuit if it's not a picture file extension
        return (fname_down.has_suffix(".png") || 
                fname_down.has_suffix(".jpeg") || 
                fname_down.has_suffix(".jpg") || 
                fname_down.has_suffix(".gif"));
    }

    // Quickly count up all of the valid wallpapers in the wallpaper folder.
    public static int count_wallpapers (GLib.File wallpaper_folder) {

        GLib.FileInfo file_info = null;
        int count = 0;
        try {
            // Get an enumerator for all of the plain old files in the wallpaper folder.
            var enumerator = wallpaper_folder.enumerate_children(FILE_ATTRIBUTE_STANDARD_NAME + 
                                                            "," + FILE_ATTRIBUTE_STANDARD_TYPE, 0);
            // While there's still files left to count
            while ((file_info = enumerator.next_file ()) != null) {
                // If it's a picture file
                if (file_info.get_file_type() == GLib.FileType.REGULAR && is_valid_file_type(file_info.get_name())) {
                    count++;
                }
            }
        } catch(GLib.Error err) {
            // Just for debugging sake
            stdout.printf("Could not pre-scan wallpaper folder. Progress percentage may be off: %s\n", err.message);
        }
        return count;
    }

}

// Main Class, acts pretty much like a Gtk.Window because it's a Gtk.Plug with some magic behind the scenes
public class WallpapersPlug : Pantheon.Switchboard.Plug {

    // Object to work with the wallpaper GSettings
    Wallpaper.WallpaperSettings wallpaper_settings = new Wallpaper.WallpaperSettings ();
    Gtk.ListStore store = new Gtk.ListStore (2, typeof (Gdk.Pixbuf), typeof (string));
    Gtk.IconView view = new Gtk.IconView();
    Gtk.TreeIter selected_plug;
    Gtk.TreeModelFilter filter;
    // Copy of the search box string
    string search_string = "";

    public WallpapersPlug () {

        setup_ui();
        load_wallpapers();
    }

    // Filters the IconView based on the search entry (search logic)
    private bool visible_func (Gtk.TreeModel model, Gtk.TreeIter iter) {

        bool visible;
        string data;
        // Get the wallpaper filename out of the store.
        model.get(iter, 1, out data);
        // If the search string is contained in the filename (both lowercase).
        if (data != null && search_string.down() in data.down()) {
            visible = true;
        } else {
            visible = false;
        }
        return visible;
    }

    // Wires up and configures initial UI
    private void setup_ui () {

        // Set-up the IconView and put in a ScrolledWindow so it can scroll
        var sw = new Gtk.ScrolledWindow(null, null);
        filter = new Gtk.TreeModelFilter(store, null);
        filter.set_visible_func(visible_func);
        view.model = filter;
        view.selection_changed.connect(selection_changed_cb);
        view.set_pixbuf_column (0);
        view.set_text_column (1);
        // Don't make whitespace clickable
        view.selection_mode = Gtk.SelectionMode.BROWSE;
        // Set up nice padding and spacing settings
        view.item_padding = 5;
        view.row_spacing = 0;
        view.item_width = 120;
        view.column_spacing = 10;
        sw.add(view);
        // A ListStore to hold the picture modes
        var combostore = new Gtk.ListStore (1, typeof (string));
        // Prepare the combo box for using and displaying the list store
        var cell = new Gtk.CellRendererText();
        var combo = new Gtk.ComboBox.with_model(combostore);
        combo.pack_start(cell, true);
        combo.set_attributes(cell, "text", 0);
        combo.changed.connect(picture_mode_changed);    
        // Load the picture modes into the list store.
        string[] picture_modes = {"Tiled", "Centered", "Scaled", "Stretched", "Zoomed"};
        foreach (string mode in picture_modes) {
            Gtk.TreeIter root;
            combostore.append(out root);
            combostore.set(root, 0, mode, -1);
        }
        combo.set_active(wallpaper_settings.picture_mode);
        var vbox = new Gtk.VBox(false, 0);
        vbox.pack_start(combo, false, false);
        vbox.pack_end(sw, true, true);
        this.add(vbox);

        // Connect to the searchbox on Switchboard
        switchboard_controller.search_box_text_changed.connect(search_wallpapers);
    }

    // Called when the picture mode is changed
    private void picture_mode_changed (Gtk.ComboBox combo) {

        Gtk.TreeIter iter;
        if (combo.get_active_iter(out iter)) {
            string val;
            combo.model.get(iter, 0, out val);
            wallpaper_settings.set_picture_mode_from_name(val);
        }
    }

    // Called when the Switchboard searchbox changes
    private void search_wallpapers () {

        search_string = switchboard_controller.search_box_get_text();
        filter.refilter();
    }

    // Called when the user selects a wallpaper
    private void selection_changed_cb (Gtk.IconView view) {

        var selected = view.get_selected_items ();
        if (selected.length() == 1) {
            GLib.Value filename;
            // Get the filename of the selected wallpaper.
            var item = selected.nth_data(0);
            this.store.get_iter(out this.selected_plug, item);
            this.store.get_value(this.selected_plug, 1, out filename);
            wallpaper_settings.picture_path = WALLPAPER_DIR + "/" + filename.get_string();    
        }
    }

    // Adds wallpapers to IconView asynchronously
    private async void load_wallpapers () {
        
        // Make the progress bar visible, since we're gonna be using it.
        switchboard_controller.progress_bar_set_visible(true);
        switchboard_controller.progress_bar_set_text("Importing wallpapers from " + WALLPAPER_DIR);

        var directory = File.new_for_path (WALLPAPER_DIR);
        // The number of wallpapers we've added so far
        double done = 0.0;
        // Count the # of wallpapers
        int count = IOHelper.count_wallpapers(directory);
        // Enumerator object that will let us read through the wallpapers asynchronously
        var e = yield directory.enumerate_children_async (FILE_ATTRIBUTE_STANDARD_NAME, 0, Priority.DEFAULT);
        
        while (true) {
            // Grab a batch of 10 wallpapers
            var files = yield e.next_files_async (10, Priority.DEFAULT);
            // Stop the loop if we've run out of wallpapers
            if (files == null) {
                break;
            }
            // Loop through and add each wallpaper in the batch
            foreach (var info in files) {
                // We're going to add another wallpaper
                done++;
                // Skip the file if it's not a picture
                if (!IOHelper.is_valid_file_type(info.get_name())) {
                    continue;
                }
                string filename = info.get_name ();
                // Create a thumbnail of the image and load it into the IconView
                var image = new Gdk.Pixbuf.from_file_at_scale(WALLPAPER_DIR + "/" + filename, 115, 80, false);
                // Add the wallpaper name and thumbnail to the IconView
                Gtk.TreeIter root;
                this.store.append(out root);
                this.store.set(root, 0, image, -1);
                this.store.set(root, 1, filename, -1);
                // Update the progress bar
                switchboard_controller.progress_bar_set_fraction(done/count);
                // Have GTK update the UI even while we're busy
                // working on file IO.
                while(Gtk.events_pending ()) {
                    Gtk.main_iteration();
                }
            }
        }
        // Hide the progress bar since we're done with it.
        switchboard_controller.progress_bar_set_visible(false);
    }

}

public static int main (string[] args) {

    Gtk.init (ref args);
    // Instantiate the plug, which handles
    // connecting to Switchboard.
    var plug = new WallpapersPlug ();
    // Connect to Switchboard and identify
    // as "Wallpapers". (For debugging)
    plug.register ("Wallpapers");
    plug.show_all ();
    // Start the GTK+ main loop.
    Gtk.main ();
    return 0;
}
