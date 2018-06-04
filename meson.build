project('useraccounts', 'vala', 'c')

gettext_name = meson.project_name() + '-plug'
gnome = import('gnome')
i18n = import('i18n')
posix_dep = meson.get_compiler('vala').find_library('posix')
switchboard_dep = dependency('switchboard-2.0')

add_project_arguments('-DGETTEXT_PACKAGE="@0@"'.format(gettext_name), language:'c')
add_project_arguments(['--vapidir', join_paths(meson.current_source_dir(), 'vapi')], language: 'vala')

configuration_data = configuration_data()
configuration_data.set('GETTEXT_PACKAGE', gettext_name)

subdir('cli')
subdir('data')
subdir('src')
subdir('po')
