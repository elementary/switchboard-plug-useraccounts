project(
    'useraccounts',
    'vala', 'c',
    meson_version: '>= 0.46.1',
    version: '2.3.0'
)

gnome = import('gnome')
i18n = import('i18n')

gettext_name = meson.project_name() + '-plug'

prefix = get_option('prefix')
datadir = join_paths(prefix, get_option('datadir'))
libdir = join_paths(prefix, get_option('libdir'))

switchboard_dep = dependency('switchboard-2.0')
switchboard_plugsdir = switchboard_dep.get_pkgconfig_variable('plugsdir', define_variable: ['libdir', libdir])
pkgdatadir = join_paths(switchboard_plugsdir, 'system', 'pantheon-useraccounts')

polkit_dep = dependency('polkit-gobject-1')
polkit_actiondir = polkit_dep.get_pkgconfig_variable('actiondir', define_variable: ['prefix', prefix])

posix_dep = meson.get_compiler('vala').find_library('posix')

add_project_arguments('-DGETTEXT_PACKAGE="@0@"'.format(gettext_name), language:'c')
add_project_arguments('-DGNOME_DESKTOP_USE_UNSTABLE_API', language: 'c')
add_project_arguments(['--vapidir', join_paths(meson.current_source_dir(), 'vapi')], language: 'vala')

configuration_data = configuration_data()
configuration_data.set('GETTEXT_PACKAGE', gettext_name)
configuration_data.set('PKGDATADIR', pkgdatadir)

subdir('cli')
subdir('data')
subdir('src')
subdir('po')
