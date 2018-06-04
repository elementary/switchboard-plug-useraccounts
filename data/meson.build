gettext_declaration = configure_file(
    configuration: configuration_data,
    input: 'org.pantheon.switchboard.user-accounts.policy.in',
    output: '@BASENAME@'
)

install_data(
    gettext_declaration,
    install_dir: join_paths(get_option('datadir'), 'polkit-1', 'actions')
)
