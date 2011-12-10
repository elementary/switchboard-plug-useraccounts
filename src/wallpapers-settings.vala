//  
//  Copyright (C) 2011 Maxwell Barvian
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

namespace Wallpaper {

    public enum PictureMode {
        TILED = 0,
        CENTERED = 1,
        SCALED = 2,
        STRETCHED = 3,
        ZOOMED = 4;
        
        public void get_options (out bool stretch_x, out bool stretch_y, out bool center_x, out bool center_y) {
                        
            switch (this) {
                
                case PictureMode.CENTERED:
                    stretch_x = false;
                    stretch_y = false;
                    center_x = true;
                    center_y = true;
                    break;
                case PictureMode.SCALED:
                    stretch_x = false;
                    stretch_y = true;
                    center_x = true;
                    center_y = false;
                    break;
                case PictureMode.STRETCHED:
                    stretch_x = true;
                    stretch_y = true;
                    center_x = false;
                    center_y = false;
                    break;
                case PictureMode.ZOOMED:
                    stretch_x = true;
                    stretch_y = false;
                    center_x = false;
                    center_y = true;
                    break;
                default:
                    stretch_x = false;
                    stretch_y = false;
                    center_x = false;
                    center_y = false;
                    break;
            }
        }
    }

    // Class to interface with GSettings for pantheon-wallpaper
    public class WallpaperSettings : Granite.Services.Settings {

        public PictureMode picture_mode { get; set; }
    
        public string picture_path { get; set; }
        
        public string background_color { get; set; }
        
        public WallpaperSettings () {
            base ("desktop.Wallpaper");
        }
        
        protected override void verify (string key) {
        
            switch (key) {
            
                case "background-color":
                    Gdk.Color bg;
                    if (!Gdk.Color.parse (background_color, out bg))
                        background_color = "#000000";
                    break;
            }
        }

        // Helper function to make life easier.
        public void set_picture_mode_from_name (string name) {

            if (name == "Tiled") {
                picture_mode = PictureMode.TILED;
            }
            else if (name == "Centered") {
                picture_mode = PictureMode.CENTERED;
            }
            else if (name == "Scaled") {
                picture_mode = PictureMode.SCALED;
            }
            else if (name == "Stretched") {
                picture_mode = PictureMode.STRETCHED;
            }
            else if (name == "Zoomed") {
                picture_mode = PictureMode.ZOOMED;
            }
        }
    
    }
    
}

