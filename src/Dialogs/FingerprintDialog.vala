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
        is_authenticated = get_permission ().allowed;


        fingerprint_image = new Gtk.Image.from_icon_name ("fingerprint-1-symbolic") {
            pixel_size = 64,
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 12,
            halign = Gtk.Align.CENTER
        };
        title_label = new Gtk.Label (_("Enrolling fingerprint")) {
            mnemonic_widget = this
        };
        title_label.add_css_class (Granite.STYLE_CLASS_H2_LABEL);

        status_label = new Gtk.Label (_("Touch the fingerprint sensor to begin.")) {
            wrap = true,
            justify = Gtk.Justification.CENTER
        };
        status_label.add_css_class (Granite.STYLE_CLASS_H3_LABEL);

        progress_bar = new Gtk.LevelBar () {
            min_value = 1,
            max_value = 1,
            value = 1,
            margin_top = 12,
            mode = DISCRETE
        };

        progress_revealer = new Gtk.Revealer () {
            child = progress_bar,
            transition_type = SLIDE_DOWN
        };

        cancel_button = add_button (_("Cancel"), Gtk.ResponseType.CANCEL);

        var form_box = new Gtk.Box (VERTICAL, 3) {
            margin_top = 12,
            margin_start = 12,
            margin_end = 12,
            vexpand = true
        };
        form_box.append (fingerprint_image);
        form_box.append (title_label);
        form_box.append (status_label);
        form_box.append (progress_revealer);

        get_content_area ().append (form_box);

        try {
            fp_utils = new SwitchboardPlugUserAccounts.FPUtils ();
            finish_button = add_button (_("Finish"), Gtk.ResponseType.OK);
            finish_button.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);
            finish_button.sensitive = false;
            set_default_widget (finish_button);
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
                    progress_bar.max_value = FPUtils.device.num_enroll_stages + 1;
                } else {
                    destroy ();
                }
            });
        }
    }

    private void set_progress (string message, bool done) {
        switch (message) {
            case "enroll-completed":
                progress_bar.value = progress_bar.max_value;
                fingerprint_image.icon_name = "fingerprint-12-symbolic";
                title_label.label = _("Enrollment complete");
                status_label.label = _("This fingerprint can now be used for authentication");
                break;
            case "enroll-failed":
                fp_utils.enroll_stop ();
                status_label.label = _("Enrolling failed. Please try again");
                break;
            case "enroll-stage-passed":
                progress_revealer.reveal_child = true;
                progress_bar.value = ++current_stage_count;
                var progress = (progress_bar.value / progress_bar.max_value) * 12;
                fingerprint_image.icon_name = "fingerprint-%d-symbolic".printf ((int) progress);
                status_label.label = _("Stage Passed! Lift your finger and touch the sensor again");
                break;
            case "enroll-retry-scan":
                status_label.label = _("Trying to scan again");
                break;
            case "enroll-swipe-too-short":
                status_label.label = _("The swipe was too short");
                break;
            case "enroll-too-fast":
                status_label.label = _("The touch was too fast");
                break;
            case "enroll-finger-not-centered":
                status_label.label = _("Center your finger on the sensor");
                break;
            case "enroll-remove-and-retry":
                status_label.label = _("Remove your finger and try again");
                break;
            case "enroll-data-full":
                fp_utils.enroll_stop ();
                title_label.label = _("Fingerprint Data Full!");
                status_label.label = _("Delete some fingerprints and try again");
                break;
            case "enroll-duplicate":
                fp_utils.enroll_stop ();
                status_label.label = _("This fingerprint is already enrolled");
                break;
            case "enroll-disconnected":
                status_label.label = _("The fingerprint sensor was disconnected");
                break;
            case "enroll-unknown-error":
                fp_utils.enroll_stop ();
                title_label.label = _("Something went wrong");
                status_label.label = _("Cancel and try again");
                break;
        }

        update_property (Gtk.AccessibleProperty.DESCRIPTION, status_label.label, -1);

        if (done) {
            cancel_button.sensitive = false;
            finish_button.sensitive = true;
        }
    }
}
