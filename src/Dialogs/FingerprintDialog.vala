/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2014-2025 elementary, Inc. (https://elementary.io)
 */

public class SwitchboardPlugUserAccounts.FingerprintDialog : Granite.Dialog {
    private bool is_authenticated { get; private set; default = false; }

    public unowned Act.User user { get; construct; }
    private Gtk.Label title_label;
    private Gtk.Label status_label;
    private Gtk.Revealer progress_revealer;
    private Gtk.LevelBar progress_bar;
    private Gtk.Widget cancel_button;
    private Gtk.Widget finish_button;
    private Gtk.Image fingerprint_image;
    private SwitchboardPlugUserAccounts.FPUtils fp_utils;
    private int current_stage_count = 1;

    public FingerprintDialog (Gtk.Window parent, Act.User user) {
        Object (
            transient_for: parent,
            user: user
        );
    }

    construct {
        default_width = 500;
        default_height = 100;
        modal = true;

        var form_box = new Gtk.Box (VERTICAL, 3) {
            margin_top = 12,
            margin_start = 12,
            margin_end = 12,
            vexpand = true
        };
        get_content_area ().append (form_box);

        is_authenticated = get_permission ().allowed;
        fingerprint_image = new Gtk.Image.from_icon_name ("fingerprint-1-symbolic") {
            pixel_size = 64,
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 12,
            halign = Gtk.Align.CENTER
        };
        form_box.append (fingerprint_image);
        title_label = new Gtk.Label ("Enrolling Fingerprint");
        title_label.add_css_class (Granite.STYLE_CLASS_H2_LABEL);
        form_box.append (title_label);

        status_label = new Gtk.Label (_("Touch the fingerprint sensor to begin.")) {
            wrap = true,
            justify = Gtk.Justification.CENTER
        };
        status_label.add_css_class (Granite.STYLE_CLASS_H3_LABEL);
        form_box.append (status_label);

        progress_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };
        form_box.append (progress_revealer);

        cancel_button = add_button (_("Cancel"), Gtk.ResponseType.CANCEL);
        cancel_button.add_css_class (Granite.STYLE_CLASS_DESTRUCTIVE_ACTION);

        try {
            fp_utils = new SwitchboardPlugUserAccounts.FPUtils ();
            finish_button = add_button (_("Finish"), Gtk.ResponseType.OK);
            finish_button.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);
            finish_button.sensitive = false;
        } catch (Error e) {
            warning ("Failed to initialize fingerprint device: %s".printf (e.message));
            status_label.label = _("Fingerprint device not available");
            cancel_button.sensitive = true;
            return;
        }


        response.connect ((response_id) => {
            destroy ();
        });

        FPUtils.device.enroll_status.connect (set_progress);

        this.unmap.connect (() => {
            fp_utils.enroll_stop ();
            fp_utils.release ();
            FPUtils.device.enroll_status.disconnect (set_progress);
        });

        if (fp_utils.claim ()) {
            fp_utils.enroll_start_async.begin ((obj, res) => {
                bool success = fp_utils.enroll_start_async.end (res);
                if (success) {
                    progress_bar = new Gtk.LevelBar () {
                        min_value = 1,
                        max_value = FPUtils.device.num_enroll_stages + 1,
                        value = 1,
                        margin_top = 12,
                        mode = DISCRETE
                    };
                    progress_revealer.child = progress_bar;
                } else {
                    destroy ();
                }
            });
        }
    }

    private void set_progress (string message, bool done) {
        status_label.label = get_friendly_status (message);
        if (done) {
            status_label.label = _("You are all set!");
            cancel_button.sensitive = false;
            finish_button.sensitive = true;
            finish_button.grab_focus ();
        }
    }

    private string get_friendly_status (string status) {
        switch (status) {
            case "enroll-completed":
                progress_bar.value = progress_bar.max_value;
                fingerprint_image.icon_name = "fingerprint-12-symbolic";
                title_label.label = _("Enrollment Complete!");
                return _("Enrollment complete");
            case "enroll-failed":
                fp_utils.enroll_stop ();
                return _("Enrolling failed. Please try again");
            case "enroll-stage-passed":
                progress_revealer.reveal_child = true;
                progress_bar.value = ++current_stage_count;
                var progress = (progress_bar.value / progress_bar.max_value) * 12;
                fingerprint_image.icon_name = "fingerprint-%d-symbolic".printf ((int) progress);
                return _("Stage Passed! Carry on!");
            case "enroll-retry-scan":
                return _("Trying to scan again");
            case "enroll-swipe-too-short":
                return _("The swipe was too short");
            case "enroll-too-fast":
                return _("The touch was too fast");
            case "enroll-finger-not-centered":
                return _("Please center your finger on the sensor");
            case "enroll-remove-and-retry":
                return _("Please remove your finger and try again");
            case "enroll-data-full":
                fp_utils.enroll_stop ();
                return _("Enrollment data is full");
            case "enroll-duplicate":
                fp_utils.enroll_stop ();
                return _("This fingerprint is already enrolled");
            case "enroll-disconnected":
                return _("The fingerprint sensor was disconnected");
            case "enroll-unknown-error":
                fp_utils.enroll_stop ();
                return _("An unknown error occurred");
            default:
                return status;
        }
    }
}
