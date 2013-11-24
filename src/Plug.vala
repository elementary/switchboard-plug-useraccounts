//
//  Copyright (C) 2012 Ivo Nunes
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

public class Sample.Plug : Switchboard.Plug {

    private Gtk.Grid main_grid;

    public Plug () {
        Object (category: Category.HARDWARE,
                code_name: "hardware-template-sample",
                display_name: _("Sample"),
                description: _("Configure nothing but is a big step"),
                icon: "go-home");
    }
    
    public override Gtk.Widget get_widget () {
        if (main_grid == null) {
            main_grid = new Gtk.Grid ();
            var label = new Gtk.Label ("Hello World!");
            main_grid.attach (label, 0, 0, 1, 1);
        }
        main_grid.show_all ();
        return main_grid;
    }
    
    public override void shown () {
        
    }
    
    public override void hidden () {
        
    }
    
    public override void search_callback (string location) {
    
    }
    
    // 'search' returns results like ("Keyboard → Behavior → Duration", "keyboard<sep>behavior")
    public override async Gee.TreeMap<string, string> search (string search) {
        return new Gee.TreeMap<string, string> (null, null);
    }
}
