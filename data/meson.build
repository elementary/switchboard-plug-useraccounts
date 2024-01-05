gettext_declaration = configure_file(
    configuration: configuration_data,
    input: 'useraccounts.policy.in.in',
    output: '@BASENAME@'
)

i18n.merge_file(
    input: gettext_declaration,
    output: gettext_name + '.policy',
    po_dir: meson.source_root() / 'po' / 'extra',
    install: true,
    install_dir: polkit_actiondir
)

i18n.merge_file(
    input: 'useraccounts.metainfo.xml.in',
    output: gettext_name + '.metainfo.xml',
    po_dir: meson.source_root() / 'po' / 'extra',
    type: 'xml',
    install: true,
    install_dir: datadir / 'metainfo',
)
