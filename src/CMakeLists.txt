find_package (PkgConfig)
pkg_check_modules (DEPS REQUIRED gthread-2.0 gtk+-3.0 pantheon granite)

add_definitions (${DEPS_CFLAGS})
link_libraries (${DEPS_LIBRARIES})
link_directories (${DEPS_LIBRARY_DIRS})

find_package (Vala REQUIRED)
include (ValaVersion)
ensure_vala_version ("0.12.0" MINIMUM)

include (ValaPrecompile)
vala_precompile (VALA_C
    wallpapers-plug.vala
    wallpapers-settings.vala
    ${CMAKE_CURRENT_BINARY_DIR}/config.vala
PACKAGES
    gtk+-3.0
    pantheon
    granite
OPTIONS
    --thread
)


add_executable (${PLUGNAME} ${VALA_C})

# Installation
install (TARGETS ${PLUGNAME} DESTINATION ${PKGDATADIR})
