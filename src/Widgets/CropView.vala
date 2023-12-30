/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2014-2023 elementary, Inc. (https://elementary.io)
 * Authored by: Tom Beckmann
 *              Marvin Beckers <beckersmarvin@gmail.com>
 */

public class SwitchboardPlugUserAccounts.Widgets.CropView : Gtk.DrawingArea {
    public Gdk.Pixbuf pixbuf { get; construct; }
    public int pixel_size { get; construct; }

    /**
     * selected area in absolute coordinates of the image
     */
    private Gdk.Rectangle area;

    /**
     * holds the current scale
     */
    private double current_scale;

    /**
     * holds the current handle positions
     */
    private int[,] pos = {
        { 0, 0 },   // upper left
        { 0, 0 },   // upper midpoint
        { 0, 0 },   // upper right
        { 0, 0 },   // right midpoint
        { 0, 0 },   // lower right
        { 0, 0 },   // lower midpoint
        { 0, 0 },   // lower left
        { 0, 0 }    // left midpoint;
    };

    /**
     * current drag operation, identified by the GdkCursorType.
     * ARROW is the default which means no operation. FLEUR
     * corresponds to a move operation.
     */
    private Gdk.CursorType current_operation = Gdk.CursorType.ARROW;

    /**
     * holds a temporary value for resizing and moving the selected area (x coordinate)
     */
    private int temp_x;

    /**
     * holds a temporary value for resizing and moving the selected area (y coordinate)
     */
    private int temp_y;

    /**
     * holds the current offset value (x coordinate)
     */
    private int offset_x;

    /**
     * holds the current offset value (y coordinate)
     */
    private int offset_y;

    /**
     * Indicates wether a mouse button is pressed or not.
     */
    private bool mouse_button_down = false;

    /**
     * signal that is emitted when the selection area is changed in any way
     */
    public signal void area_changed ();

    /**
     * constant value for the area handles' radius
     */
    private const int RADIUS = 12;

    private Gtk.EventControllerMotion motion_event_controller;
    private Gtk.GestureMultiPress click_gesture;

    public CropView (Gdk.Pixbuf pixbuf, int pixel_size) {
        Object (
            pixbuf: pixbuf,
            pixel_size: pixel_size
        );
    }

    construct {
        // Use a default selection of 75% in the center of the image
        int area_dimension = int.min (pixbuf.get_width (), pixbuf.get_height ()) * 3 / 4;
        int area_position_x = (pixbuf.get_width () - area_dimension) / 2;
        int area_position_y = (pixbuf.get_height () - area_dimension) / 2;

        area = {
            area_position_x,
            area_position_y,
            area_dimension,
            area_dimension
        };

        // Set the size to fit inside the requested size
        width_request = int.min (pixel_size, pixel_size * pixbuf.get_width () / pixbuf.get_height ());
        height_request = int.min (pixel_size, pixel_size * pixbuf.get_height () / pixbuf.get_width ());

        add_events (Gdk.EventMask.POINTER_MOTION_MASK | Gdk.EventMask.BUTTON_MOTION_MASK);

        click_gesture = new Gtk.GestureMultiPress (this);
        click_gesture.pressed.connect (gesture_press_event);
        click_gesture.released.connect (gesture_release_event);

        motion_event_controller = new Gtk.EventControllerMotion (this);
        motion_event_controller.motion.connect (motion_event);
    }

    /**
     * returns the current selected area as pixbuf
     */
    public Gdk.Pixbuf get_selection () {
        return new Gdk.Pixbuf.subpixbuf (_pixbuf, area.x, area.y, area.width, area.height);
    }

    private void gesture_press_event (int n_press, double x, double y) {
        mouse_button_down = true;
        temp_x = (int) x;
        temp_y = (int) y;
    }

    private void gesture_release_event (int n_press, double x, double y) {
        current_operation = Gdk.CursorType.ARROW;
        mouse_button_down = false;
        apply_cursor ();
    }

    private void motion_event (double event_x, double event_y) {
        critical ("we got motion");

        if (!mouse_button_down) {
            bool determined_cursortype = false;

            const Gdk.CursorType[] CURSOR = {
                Gdk.CursorType.TOP_LEFT_CORNER,
                Gdk.CursorType.TOP_SIDE,
                Gdk.CursorType.TOP_RIGHT_CORNER,
                Gdk.CursorType.RIGHT_SIDE,
                Gdk.CursorType.BOTTOM_RIGHT_CORNER,
                Gdk.CursorType.BOTTOM_SIDE,
                Gdk.CursorType.BOTTOM_LEFT_CORNER,
                Gdk.CursorType.LEFT_SIDE
            };

            for (var i = 0; i < 8; i++) {
                if (in_quad (pos[i, 0] - RADIUS, pos[i, 1] - RADIUS, RADIUS * 2, RADIUS * 2, (int) event_x, (int) event_y)) {
                    current_operation = CURSOR[i];
                    determined_cursortype = true;
                    break;
                }
            }

            if (!determined_cursortype) {
                if (in_quad ((int) Math.floor (area.x * current_scale),
                             (int) Math.floor (area.y * current_scale),
                             (int) Math.floor (area.width * current_scale),
                             (int) Math.floor (area.height * current_scale),
                             (int) (event_x - offset_x), (int) (event_y - offset_y)))
                    current_operation = Gdk.CursorType.FLEUR;
                else
                    current_operation = Gdk.CursorType.ARROW;
            }

            apply_cursor ();
            return;
        } else {
            switch (current_operation) {
                case Gdk.CursorType.FLEUR:
                    int motion_x = (int) (area.x + ((int) event_x - temp_x) / current_scale);
                    int motion_y = (int) (area.y + ((int) event_y - temp_y) / current_scale);

                    switch (x_in_pixbuf (motion_x)) {
                        case 0: area.x = motion_x; area_changed (); break;
                        case 1: area.x = 0; break;
                        case 2: area.x = _pixbuf.get_width () - area.width; break;
                    }

                    switch (y_in_pixbuf (motion_y)) {
                        case 0: area.y = motion_y; area_changed (); break;
                        case 1: area.y = 0; break;
                        case 2: area.y = _pixbuf.get_height () - area.height; break;
                    }

                    break;

                case Gdk.CursorType.TOP_RIGHT_CORNER:
                case Gdk.CursorType.TOP_LEFT_CORNER:
                    int motion_width = 0;
                    int motion_height = 0;
                    if (current_operation == Gdk.CursorType.TOP_RIGHT_CORNER) {
                        motion_width = (int) (area.width + ((int) event_x - temp_x) / current_scale);
                        motion_height = (int) (area.height - ((int) event_y - temp_y) / current_scale);
                    }
                    else {
                        motion_width = (int) (area.width - ((int) event_x - temp_x) / current_scale);
                        motion_height = (int) (area.height - ((int) event_y - temp_y) / current_scale);
                    }

                    if (motion_width >= motion_height)
                        motion_height = motion_width;
                    else if (motion_width < motion_height)
                        motion_width = motion_height;

                    switch (width_in_pixbuf (motion_width, area.x)) {
                        case 0:
                            if (height_in_pixbuf (motion_height, area.y) == 0) {
                                area.width = motion_width;
                                area.height = motion_height;
                                area_changed ();
                            }
                            break;
                        case 1:
                            area.width = 0;
                            break;
                        case 2:
                            area.width = _pixbuf.get_width () - area.x;
                            break;
                    }

                    switch (height_in_pixbuf (motion_height, area.y)) {
                        case 0:
                            if (width_in_pixbuf (motion_width, area.x) == 0) {
                                area.height = motion_height;
                                area.width = motion_width;
                                area_changed ();
                            }
                            break;
                        case 1:
                            area.height = 0;
                            break;
                        case 2:
                            area.height = _pixbuf.get_height () - area.y;
                            break;
                    }

                    break;

                case Gdk.CursorType.BOTTOM_RIGHT_CORNER:
                case Gdk.CursorType.BOTTOM_LEFT_CORNER:
                    int motion_width = 0;
                    int motion_height = 0;
                    if (current_operation == Gdk.CursorType.BOTTOM_RIGHT_CORNER) {
                        motion_width = (int) (area.width + ((int) event_x - temp_x) / current_scale);
                        motion_height = (int) (area.height + ((int) event_y - temp_y) / current_scale);
                    }
                    else {
                        motion_width = (int) (area.width - ((int) event_x - temp_x) / current_scale);
                        motion_height = (int) (area.height + ((int) event_y - temp_y) / current_scale);
                    }

                    if (motion_width >= motion_height)
                        motion_height = motion_width;
                    else if (motion_width < motion_height)
                        motion_width = motion_height;

                    switch (width_in_pixbuf (motion_width, area.x)) {
                        case 0:
                            if (height_in_pixbuf (motion_height, area.y) == 0) {
                                area.width = motion_width;
                                area.height = motion_height;
                                area_changed ();
                            }
                            break;
                        case 1:
                            area.width = 0;
                            break;
                        case 2:
                            area.width = _pixbuf.get_width () - area.x;
                            break;
                    }

                    switch (height_in_pixbuf (motion_height, area.y)) {
                        case 0:
                            if (width_in_pixbuf (motion_width, area.x) == 0) {
                                area.height = motion_height;
                                area.width = motion_width;
                                area_changed ();
                            }
                            break;
                        case 1:
                            area.height = 0;
                            break;
                        case 2:
                            area.height = _pixbuf.get_height () - area.y;
                            break;
                    }

                    break;

                case Gdk.CursorType.TOP_SIDE:
                case Gdk.CursorType.BOTTOM_SIDE:
                    int motion_height = 0;
                    if (current_operation == Gdk.CursorType.BOTTOM_SIDE)
                        motion_height = (int) (area.height + ((int) event_y - temp_y) / current_scale);
                    else
                        motion_height = (int) (area.height - ((int) event_y - temp_y) / current_scale);


                    switch (height_in_pixbuf (motion_height, area.y)) {
                        case 0:
                            area.width = motion_height;
                            area.height = motion_height;
                            area_changed ();
                            break;
                        case 1:
                            area.width = 0;
                            area.height = 0;
                            break;
                        case 2:
                            area.width = _pixbuf.get_width () - area.x;
                            area.height = _pixbuf.get_height () - area.y;
                            break;
                    }

                    break;

                case Gdk.CursorType.RIGHT_SIDE:
                case Gdk.CursorType.LEFT_SIDE:
                    int motion_width = 0;
                    if (current_operation == Gdk.CursorType.RIGHT_SIDE)
                        motion_width = (int) (area.width + ((int) event_x - temp_x) / current_scale);
                    else
                        motion_width = (int) (area.width - ((int) event_x - temp_x) / current_scale);

                    switch (width_in_pixbuf (motion_width, area.x)) {
                        case 0:
                            area.width = motion_width;
                            area.height = motion_width;
                            area_changed ();
                            break;
                        case 1:
                            area.width = 0;
                            area.height = 0;
                            break;
                        case 2:
                            area.width = _pixbuf.get_width () - area.x;
                            area.height = _pixbuf.get_height () - area.y;
                            break;
                    }

                    break;
                default:
                    break;
            }

            if (area.width != area.height) {
                var smallest = area.width > area.height ? area.height : area.width;
                area.width = smallest;
                area.height = smallest;
            }

            temp_x = (int) event_x;
            temp_y = (int) event_y;

            queue_draw ();
        }
    }

    public override bool draw (Cairo.Context cr) {
        Gtk.Allocation alloc;

        get_allocation (out alloc);

        var pixbuf_width = _pixbuf.get_width ();
        var pixbuf_height = _pixbuf.get_height ();
        double scale = 1.0;

        if (pixbuf_width > alloc.width) {
            scale = alloc.width / (double) pixbuf_width;
            pixbuf_height = (int) Math.floor (scale * pixbuf_height);
            pixbuf_width = alloc.width;
        }

        if (pixbuf_height > alloc.height) {
            scale = alloc.height / (double) pixbuf_height;
            pixbuf_width = (int) Math.floor (scale * pixbuf_width);
            pixbuf_height = alloc.height;
        }

        var pixbuf = _pixbuf.scale_simple (pixbuf_width, pixbuf_height, Gdk.InterpType.BILINEAR);

        offset_x = alloc.width / 2 - pixbuf_width / 2;
        offset_y = alloc.height / 2 - pixbuf_height / 2;

        Gdk.cairo_set_source_pixbuf (cr, pixbuf, offset_x, offset_y);
        cr.paint ();

        scale = pixbuf_width / (double) _pixbuf.get_width ();

        var x = offset_x + (int) Math.floor (area.x * scale);
        var y = offset_y + (int) Math.floor (area.y * scale);
        var w = (int) Math.floor (area.width * scale);
        var h = (int) Math.floor (area.height * scale);

        pos = {
            { x, y },               // upper left
            { x + w / 2, y },       // upper midpoint
            { x + w, y },           // upper right
            { x + w, y + h / 2 },   // right midpoint
            { x + w, y + h },       // lower right
            { x + w / 2, y + h },   // lower midpoint
            { x, y + h },           // lower left
            { x, y + h / 2 }        // left midpoint
        };

        cr.rectangle (x, y, w, h);
        cr.set_source_rgba (0.1, 0.1, 0.1, 0.2);
        cr.fill ();

        cr.rectangle (x, y, w, h);
        cr.set_source_rgb (1.0, 1.0, 1.0);
        cr.set_line_width (1.0);
        cr.stroke ();

        current_scale = scale;

        return true;
    }

    private bool in_quad (int qx, int qy, int qw, int qh, int x, int y) {
        return ((x > qx) && (x < (qx + qw)) && (y > qy) && (y < qy + qh));
    }

    private void apply_cursor () {
        get_window ().cursor = new Gdk.Cursor.for_display (Gdk.Display.get_default (), current_operation);
    }

    private int x_in_pixbuf (int ax) {
        if (ax < 0)
            return 1;
        else if (ax + area.width > _pixbuf.get_width ())
            return 2;
        return 0;
    }

    private int y_in_pixbuf (int ay) {
        if (ay < 0)
            return 1;
        else if (ay + area.height > _pixbuf.get_height ())
            return 2;
        return 0;
    }

    private int width_in_pixbuf (int aw, int ax) {
        if (aw < 0)
            return 1;
        else if (aw > _pixbuf.get_width () - ax)
            return 2;
        return 0;
    }

    private int height_in_pixbuf (int ah, int ay) {
        if (ah < 0)
            return 1;
        else if (ah > _pixbuf.get_height () - ay)
            return 2;
        return 0;
    }
}
