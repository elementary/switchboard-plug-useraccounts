gettext_declaration = configure_file(
    configuration: configuration_data,
    input: 'org.pantheon.switchboard.user-accounts.policy.in.in',
    output: '@BASENAME@'
)

i18n.merge_file(
    input: gettext_declaration,
    output: 'org.pantheon.switchboard.user-accounts.policy',
    po_dir: join_paths(meson.source_root(), 'po', 'extra'),
    install: true,
    install_dir: pkg_data_dir
)
