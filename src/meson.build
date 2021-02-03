pkgdatadir_declaration = configure_file(
    configuration: configuration_data,
    input: 'config.vala.in',
    output: '@BASENAME@'
)

plug_files = files(
    'Plug.vala',
    'Dialogs/AvatarDialog.vala',
    'Dialogs/ChangePasswordDialog.vala',
    'Dialogs/NewUserDialog.vala',
    'Misc/DeltaUser.vala',
    'Misc/InfobarNotifier.vala',
    'Misc/UserUtils.vala',
    'Misc/Utils.vala',
    'Views/GuestSettingsView.vala',
    'Views/MainView.vala',
    'Views/UserSettingsView.vala',
    'Widgets/Popovers/AvatarPopover.vala',
    'Widgets/CropView.vala',
    'Widgets/ErrorRevealer.vala',
    'Widgets/ListFooter.vala',
    'Widgets/PasswordEditor.vala',
    'Widgets/UserItem.vala',
    'Widgets/UserListBox.vala'
)

run_passwd_files = files(
    'run-passwd.c',
    'run-passwd.h'
)

shared_module(
    meson.project_name(),
    pkgdatadir_declaration,
    plug_files,
    run_passwd_files,
    dependencies: [
        dependency('accountsservice'),
        dependency('gee-0.8'),
        dependency('gio-2.0'),
        dependency('glib-2.0'),
        dependency('gnome-desktop-3.0'),
        dependency('gobject-2.0'),
        dependency('granite', version: '>=6.0.0'),
        dependency('gtk+-3.0'),
        dependency('libhandy-1', version: '>= 0.90.0'),
        dependency('pwquality'),
        meson.get_compiler('vala').find_library('run-passwd', dirs: join_paths(meson.current_source_dir())),
        polkit_dep,
        posix_dep,
        switchboard_dep,
    ],
    install: true,
    install_dir : join_paths(switchboard_plugsdir, 'system')
)
