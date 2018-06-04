gettext_declaration = configure_file(
    configuration: configuration_data,
    input: 'org.pantheon.switchboard.user-accounts.policy.in',
    output: '@BASENAME@'
)

install_data(
    gettext_declaration,
    install_dir: pkg_data_dir
)
