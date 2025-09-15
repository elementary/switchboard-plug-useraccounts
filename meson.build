project(
    'useraccounts',
    'vala', 'c',
    meson_version: '>= 0.58.0',
    version: '8.0.1'
)

gnome = import('gnome')
i18n = import('i18n')

gettext_name = 'io.elementary.settings.' + meson.project_name()

prefix = get_option('prefix')
datadir = join_paths(prefix, get_option('datadir'))
libdir = join_paths(prefix, get_option('libdir'))
localedir = join_paths(prefix, get_option('localedir'))

switchboard_dep = dependency('switchboard-3')
switchboard_plugsdir = switchboard_dep.get_variable('plugsdir', pkgconfig_define: ['libdir', libdir])
pkgdatadir = switchboard_plugsdir / 'system' / 'useraccounts'

polkit_dep = dependency('polkit-gobject-1')
polkit_actiondir = polkit_dep.get_variable('actiondir', pkgconfig_define: ['prefix', prefix])

posix_dep = meson.get_compiler('vala').find_library('posix')

add_project_arguments(
    '-DGETTEXT_PACKAGE="@0@"'.format(gettext_name),
    '-DG_LOG_DOMAIN="@0@"'.format(meson.project_name()),
    '-DGNOME_DESKTOP_USE_UNSTABLE_API',
    language:'c'
)

add_project_arguments(['--vapidir', join_paths(meson.current_source_dir(), 'vapi')], language: 'vala')

configuration_data = configuration_data()
configuration_data.set('GETTEXT_PACKAGE', gettext_name)
configuration_data.set('LOCALEDIR', localedir)
configuration_data.set('PKGDATADIR', pkgdatadir)

plug_resources = gnome.compile_resources (
    'plug_resources',
    'data' / 'icons.gresource.xml',
    source_dir: 'data'
)

subdir('cli')
subdir('data')
subdir('src')
subdir('po')
