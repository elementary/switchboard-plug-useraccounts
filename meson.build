project('useraccounts', 'vala', 'c', meson_version: '>= 0.46.1')

gettext_name = meson.project_name() + '-plug'
gnome = import('gnome')
i18n = import('i18n')
pkg_data_dir =  join_paths(get_option('datadir'), 'polkit-1', 'actions')
posix_dep = meson.get_compiler('vala').find_library('posix')
switchboard_dep = dependency('switchboard-2.0')

add_project_arguments('-DGETTEXT_PACKAGE="@0@"'.format(gettext_name), language:'c')
add_project_arguments('-DGNOME_DESKTOP_USE_UNSTABLE_API', language: 'c')
add_project_arguments(['--vapidir', join_paths(meson.current_source_dir(), 'vapi')], language: 'vala')

configuration_data = configuration_data()
configuration_data.set('GETTEXT_PACKAGE', gettext_name)
configuration_data.set('PKGDATADIR', pkg_data_dir)

subdir('cli')
subdir('data')
subdir('src')
subdir('po')
