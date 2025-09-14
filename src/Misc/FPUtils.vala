/*
* Copyright (c) 2014-2025 elementary LLC. (https://elementary.io)
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
*
* Authored by: Subhadeep Jasu <subhadeep107@proton.me>
*/

namespace SwitchboardPlugUserAccounts {
    public class FPUtils {
        public static FPrintDevice? device = null;
        public static FPrintManager? manager = null;

        public FPUtils () throws Error {
            if (manager == null) {
                manager = Bus.get_proxy_sync (
                    BusType.SYSTEM,
                    "net.reactivated.Fprint",
                    "/net/reactivated/Fprint/Manager",
                    DBusProxyFlags.NONE
                );
            }

            if (device == null) {
                var device_path = manager.get_default_device ();
                device = GLib.Bus.get_proxy_sync (
                    GLib.BusType.SYSTEM,
                    "net.reactivated.Fprint",
                    device_path
                );
            }
        }

        public bool is_enrolled (string username = "") {
            if (device == null) {
                warning ("fprintd not available");
                return false;
            }

            try {
                var fingers = device.list_enrolled_fingers (username);
                return fingers.length > 0;
            } catch (Error e) {
                warning ("Failed to list enrolled fingers: %s".printf (e.message));
                return false;
            }
        }

        public bool claim (string username = "") {
            if (device == null) {
                warning ("fprintd not available");
                return false;
            }

            try {
                device.claim (username);
                return true;
            } catch (Error e) {
                warning ("Failed to claim fprintd device: %s".printf (e.message));
                return false;
            }
        }

        public void release () {
            if (device == null) {
                warning ("fprintd not available");
                return;
            }

            try {
                device.release ();
            } catch (Error e) {
                warning ("Failed to release fprintd device: %s".printf (e.message));
            }
        }

        public void enroll_start (string finger_name) throws Error {
            if (device == null) {
                warning ("fprintd not available");
                return;
            }

            try {
                device.enroll_start (finger_name);
            } catch (Error e) {
                warning ("Failed to start enrollment: %s".printf (e.message));
                throw e;
            }
        }

        public async bool enroll_start_async () {
            bool succeeded = true;
            SourceFunc callback = enroll_start_async.callback;
            ThreadFunc enroll = () => {
                try {
                    enroll_start ("right-index-finger");
                } catch (Error e) {
                    succeeded = false;
                }

                Idle.add ( (owned) callback);
                return null;
            };

            new Thread<bool> ("enroll-fingerprint", enroll);
            yield;
            return succeeded;
        }

        public void enroll_stop () {
            if (device == null) {
                warning ("fprintd not available");
                return;
            }

            try {
                device.enroll_stop ();
            } catch (Error e) {
                warning ("Failed to stop enrollment: %s".printf (e.message));
            }
        }

        public void delete_enrollments () {
            if (device == null) {
                warning ("fprintd not available");
                return;
            }

            try {
                device.delete_enrolled_fingers2 ();
            } catch (Error e) {
                warning ("Failed to delete enrollments: %s".printf (e.message));
            }
        }

        public async void delete_enrollments_async () {
            SourceFunc callback = delete_enrollments_async.callback;
            ThreadFunc enroll = () => {
                delete_enrollments ();
                Idle.add ((owned) callback);
                return null;
            };

            new Thread<bool> ("delete-enrollment", enroll);

            yield;
        }
    }
}
