/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2014-2023 elementary, Inc. (https://elementary.io)
 */

public class SwitchboardPlugUserAccounts.Widgets.MainView : Gtk.Box {
    private Gtk.ListBox listbox;
    private Granite.Toast toast;
    private Gtk.Stack content;
    private GuestSettingsView guest;
    private Granite.HeaderLabel my_account_label;
    private Granite.HeaderLabel other_accounts_label;
    private Gtk.ListBoxRow guest_session_row;
    private Gtk.Label guest_description_label;

    construct {
        listbox = new Gtk.ListBox () {
            selection_mode = SINGLE
        };
        listbox.set_header_func (update_headers);

        my_account_label = new Granite.HeaderLabel (_("My Account"));

        other_accounts_label = new Granite.HeaderLabel (_("Other Accounts"));

        var scrolled_window = new Gtk.ScrolledWindow () {
            child = listbox,
            hexpand = true,
            vexpand = true,
            hscrollbar_policy = NEVER
        };

        var add_button_label = new Gtk.Label (_("Create User Account…"));

        var add_button_box = new Gtk.Box (HORIZONTAL, 0);
        add_button_box.append (new Gtk.Image.from_icon_name ("list-add-symbolic"));
        add_button_box.append (add_button_label);

        var button_add = new Gtk.Button () {
            child = add_button_box,
            has_frame = false,
            margin_top = 3,
            margin_bottom = 3
        };

        add_button_label.mnemonic_widget = button_add;

        var actionbar = new Gtk.ActionBar ();
        actionbar.add_css_class (Granite.STYLE_CLASS_FLAT);
        actionbar.pack_start (button_add);

        var sidebar = new Gtk.Box (VERTICAL, 0);
        sidebar.append (scrolled_window);
        sidebar.append (actionbar);

        guest = new GuestSettingsView ();

        content = new Gtk.Stack ();
        content.add_named (guest, "guest_session");

        toast = new Granite.Toast ("");
        toast.set_default_action (_("Undo"));

        var overlay = new Gtk.Overlay () {
            child = content
        };
        overlay.add_overlay (toast);

        var paned = new Gtk.Paned (HORIZONTAL) {
            start_child = sidebar,
            end_child = overlay,
            position = 240
        };

        // pack1 (sidebar, false, false);
        // pack2 (overlay, true, false);

        append (paned);

        //only build the guest session list entry / row when lightDM is the display manager
        if (get_display_manager () == "lightdm") {
            var avatar = new Adw.Avatar (32, null, false);

            // We want to use the user's accent, not a random color
            unowned var avatar_context = avatar.get_first_child ();
            avatar_context.remove_css_class ("color1");
            avatar_context.remove_css_class ("color2");
            avatar_context.remove_css_class ("color3");
            avatar_context.remove_css_class ("color4");
            avatar_context.remove_css_class ("color5");
            avatar_context.remove_css_class ("color6");
            avatar_context.remove_css_class ("color7");
            avatar_context.remove_css_class ("color8");
            avatar_context.remove_css_class ("color9");
            avatar_context.remove_css_class ("color10");
            avatar_context.remove_css_class ("color11");
            avatar_context.remove_css_class ("color12");
            avatar_context.remove_css_class ("color13");
            avatar_context.remove_css_class ("color14");

            var full_name_label = new Gtk.Label (_("Guest Session")) {
                halign = START
            };
            full_name_label.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);

            guest_description_label = new Gtk.Label (null) {
                halign = START
            };
            guest_description_label.get_style_context ().add_class (Granite.STYLE_CLASS_SMALL_LABEL);

            var row_grid = new Gtk.Grid () {
                column_spacing = 12,
                margin_top = 6,
                margin_end = 6,
                margin_bottom = 6,
                margin_start = 12
            };
            row_grid.attach (avatar, 0, 0, 1, 2);
            row_grid.attach (full_name_label, 1, 0);
            row_grid.attach (guest_description_label, 1, 1);

            guest_session_row = new Gtk.ListBoxRow () {
                child = row_grid,
                name = "guest_session"
            };

            update_guest ();
        } else {
            debug ("Unsupported display manager found. Guest session settings will be hidden");
        }

        if (get_usermanager ().is_loaded) {
            update ();
        } else {
            get_usermanager ().notify["is-loaded"].connect (update);
        }

        button_add.clicked.connect (() => {
            var permission = get_permission ();
            if (!permission.allowed) {
                try {
                    permission.acquire ();
                } catch (Error e) {
                    if (!e.matches (GLib.IOError.quark (), GLib.IOError.CANCELLED)) {
                        var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
                            _("Unable to acquire permission"),
                            _("A new account cannot be created without the required system permission."),
                            "dialog-password",
                            Gtk.ButtonsType.CLOSE
                        ) {
                            badge_icon = new ThemedIcon ("dialog-error"),
                            modal = true,
                            transient_for = (Gtk.Window) get_root ()
                        };
                        message_dialog.show_error_details (e.message);
                        message_dialog.response.connect (message_dialog.destroy);
                        message_dialog.present ();
                    }

                    return;
                }
            }

            var new_user = new SwitchboardPlugUserAccounts.NewUserDialog ((Gtk.Window) this.get_root ());
            new_user.present ();
        });

        get_permission ().notify["allowed"].connect (() => {
            if (!get_permission ().allowed) {
                toast.withdraw ();
            }
        });

        toast.default_action.connect (() => {
            undo_removal ();
            update_listbox ();
        });

        listbox.row_selected.connect (listbox_selected);
    }

    private void update () {
        get_usermanager ().user_added.connect (add_user_settings);

        get_usermanager ().user_removed.connect ((user) => {
            remove_user_settings (user);

            if (get_removal_list ().last () == null) {
                toast.withdraw ();
            }
        });

        foreach (Act.User user in get_usermanager ().list_users ()) {
            add_user_settings (user);
        }

        if (get_display_manager () == "lightdm") {
            guest.guest_switch_changed.connect (update_guest);
        }

        //auto select current user row in listbox widget
        listbox.select_row (listbox.get_row_at_index (0));
    }

    private void remove_user () {
        var permission = get_permission ();
        if (!permission.allowed) {
            try {
                permission.acquire ();
            } catch (Error e) {
                if (!e.matches (GLib.IOError.quark (), GLib.IOError.CANCELLED)) {
                    var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
                        _("Unable to acquire permission"),
                        _("An account cannot be removed without the required system permission."),
                        "dialog-password",
                        Gtk.ButtonsType.CLOSE
                    ) {
                        badge_icon = new ThemedIcon ("dialog-error"),
                        transient_for = (Gtk.Window) get_root ()
                    };
                    message_dialog.show_error_details (e.message);
                    message_dialog.response.connect (message_dialog.destroy);
                    message_dialog.present ();
                }

                return;
            }
        }

        var selected_user = ((UserItem) listbox.get_selected_row ()).user;
        mark_removal (selected_user);

        listbox.remove (listbox.get_selected_row ());
        listbox.select_row (listbox.get_row_at_index (0));

        toast.title = _("Removed “%s”").printf (selected_user.get_user_name ());
        toast.send_notification ();
    }

    private void add_user_settings (Act.User user) {
        debug ("Adding UserSettingsView Widget for User '%s'".printf (user.get_user_name ()));
        var page = new UserSettingsView (user);
        page.remove_user.connect (remove_user);
        content.add_named (page, user.get_user_name ());

        update_listbox ();
    }

    private void remove_user_settings (Act.User user) {
        debug ("Removing UserSettingsView Widget for User '%s'".printf (user.get_user_name ()));
        content.remove (content.get_child_by_name (user.get_user_name ()));
    }

    private void listbox_selected (Gtk.ListBoxRow? user_item) {
        Act.User? user = null;
        if (user_item != null && user_item.name != "guest_session") {
            user = ((UserItem)user_item).user;
            var username = user.get_user_name ();
            content.set_visible_child_name (username);
        } else if (user_item != null && user_item.name == "guest_session") {
            content.set_visible_child_name ("guest_session");
        }
    }

    private void update_listbox () {
        while (listbox.get_row_at_index (0) != null) {
            listbox.remove (listbox.get_row_at_index (0));
        }

        listbox.insert (new UserItem (get_current_user ()), 0);
        int pos = 1;
        foreach (unowned Act.User temp_user in get_usermanager ().list_users ()) {
            if (get_current_user () != temp_user && !check_removal (temp_user)) {
                listbox.insert (new UserItem (temp_user), pos);
                pos++;
            }
        }

        if (get_display_manager () == "lightdm") {
            listbox.insert (guest_session_row, pos);
        }
    }

    private void update_headers (Gtk.ListBoxRow row, Gtk.ListBoxRow? before) {
        if (row == listbox.get_row_at_index (0)) {
            row.set_header (my_account_label);
        } else if (row == listbox.get_row_at_index (1)) {
            row.set_header (other_accounts_label);
        }
    }

    private void update_guest () {
        if (get_guest_session_state ("show")) {
            guest_description_label.label = _("Enabled");
        } else {
            guest_description_label.label = _("Disabled");
        }
    }
}
