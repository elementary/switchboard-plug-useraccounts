# User Accounts Settings
[![Translation status](https://l10n.elementaryos.org/widget/settings/useraccounts/svg-badge.svg)](https://l10n.elementaryos.org/engage/settings/)

![screenshot](data/screenshot.png?raw=true)

## Building and Installation

You'll need the following dependencies:

* libaccountsservice-dev
* libadwaita-1-dev
* libgirepository1.0-dev 
* libgnome-desktop-4-dev
* libgranite-7-dev >= 7.4.0
* libgtk4-dev >= 4.10
* libpolkit-gobject-1-dev
* libpwquality-dev
* libswitchboard-3-dev
* meson >= 0.46.1
* policykit-1
* valac

Run `meson build` to configure the build environment and then change to the build directory and run `ninja` to build

    meson build --prefix=/usr 
    cd build
    ninja

To install, use `ninja install`

    ninja install
