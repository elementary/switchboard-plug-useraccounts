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
    install_dir: act_dir
)

i18n.merge_file(
    input: 'useraccounts.appdata.xml.in',
    output: 'io.elementary.switchboard.useraccounts.appdata.xml',
    po_dir: join_paths(meson.source_root(), 'po', 'extra'),
    type: 'xml',
    install: true,
    install_dir: join_paths(get_option('datadir'), 'metainfo'),
)
