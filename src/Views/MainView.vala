/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2014-2023 elementary, Inc. (https://elementary.io)
 */

public class SwitchboardPlugUserAccounts.Widgets.MainView : Gtk.Paned {
    private UserListBox userlist;
    private Granite.Toast toast;
    private Gtk.Stack content;
    private Gtk.ScrolledWindow scrolled_window;
    private GuestSettingsView guest;

    public MainView () {
        Object (
            orientation: Gtk.Orientation.HORIZONTAL,
            position: 240
        );
    }

    construct {
        userlist = new UserListBox ();

        scrolled_window = new Gtk.ScrolledWindow () {
            child = userlist,
            hexpand = true,
            vexpand = true,
            hscrollbar_policy = NEVER
        };

        var add_button_label = new Gtk.Label (_("Create User Account…"));

        var add_button_box = new Gtk.Box (HORIZONTAL, 0);
        add_button_box.add (new Gtk.Image.from_icon_name ("list-add-symbolic", BUTTON));
        add_button_box.add (add_button_label);

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

        pack1 (sidebar, false, false);
        pack2 (overlay, true, false);

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
                toast.reveal_child = false;
            }
        });

        toast.default_action.connect (() => {
            undo_removal ();
            userlist.update_ui ();
        });

        userlist.row_selected.connect (userlist_selected);
    }

    private void update () {
        get_usermanager ().user_added.connect (add_user_settings);

        get_usermanager ().user_removed.connect ((user) => {
            remove_user_settings (user);

            if (get_removal_list ().last () == null) {
                toast.reveal_child = false;
            }
        });

        foreach (Act.User user in get_usermanager ().list_users ()) {
            add_user_settings (user);
        }

        guest.guest_switch_changed.connect (() => {
            userlist.update_guest ();
        });

        //auto select current user row in userlist widget
        userlist.select_row (userlist.get_row_at_index (0));
        show_all ();
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

        var selected_user = ((UserItem) userlist.get_selected_row ()).user;
        mark_removal (selected_user);

        userlist.update_ui ();
        userlist.select_row (userlist.get_row_at_index (0));

        toast.title = _("Removed “%s”").printf (selected_user.get_user_name ());
        toast.send_notification ();
    }

    private void add_user_settings (Act.User user) {
        debug ("Adding UserSettingsView Widget for User '%s'".printf (user.get_user_name ()));
        var page = new UserSettingsView (user);
        page.remove_user.connect (remove_user);
        content.add_named (page, user.get_user_name ());
    }

    private void remove_user_settings (Act.User user) {
        debug ("Removing UserSettingsView Widget for User '%s'".printf (user.get_user_name ()));
        content.remove (content.get_child_by_name (user.get_user_name ()));
    }

    private void userlist_selected (Gtk.ListBoxRow? user_item) {
        Act.User? user = null;
        if (user_item != null && user_item.name != "guest_session") {
            user = ((UserItem)user_item).user;
            var username = user.get_user_name ();
            content.set_visible_child_name (username);
        } else if (user_item != null && user_item.name == "guest_session") {
            content.set_visible_child_name ("guest_session");
        }
    }
}
