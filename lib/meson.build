run_passwd = shared_library(
    'run-passwd',
    'run-passwd.c',
    'run-passwd.h',
    dependencies: [
        dependency('glib-2.0')
    ]
)

run_passwd_dep = declare_dependency(
    link_with : run_passwd,
    include_directories : include_directories('.')
)
