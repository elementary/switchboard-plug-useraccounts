run_passwd = shared_library(
    'run-passwd',
    'run-passwd.c',
    'run-passwd.h',
    dependencies: [
        dependency('glib-2.0')
    ]
)

run_passwd_dep = declare_dependency(
    include_directories : include_directories('.'),
    link_with : run_passwd,
    dependencies: [
        dependency('glib-2.0')
    ]
)
