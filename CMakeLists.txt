# This a sample CMakeLists.txt for compiling plug for Switchboard
# http://elementaryos.org/docs/developer-guide/cmake 

cmake_minimum_required (VERSION 2.6)
cmake_policy (VERSION 2.6)

set (PLUGNAME "Appearance")
set (PLUGCATEGORY "hardware")
set (PLUGTITLE "Appearance")
set (PLUGICON "go-home")

project (${PLUGNAME})

set (DATADIR "${CMAKE_INSTALL_PREFIX}/lib/plugs")
set (PKGDATADIR "${DATADIR}/pantheon/${PLUGNAME}")
set (GETTEXT_PACKAGE "${PLUGNAME}")

list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

# Configure file
configure_file (plug.plug ${CMAKE_BINARY_DIR}/${PLUGNAME}.plug)
install (FILES ${CMAKE_BINARY_DIR}/${PLUGNAME}.plug DESTINATION ${PKGDATADIR})
configure_file (${CMAKE_SOURCE_DIR}/config.vala.cmake ${CMAKE_BINARY_DIR}/src/config.vala)
add_definitions (-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")

# Files
file (GLOB resources "${CMAKE_CURRENT_SOURCE_DIR}/data/*")

# Traslation stuff
add_subdirectory (po)
# Info-plug
install (FILES ${resources} DESTINATION ${PKGDATADIR})

add_subdirectory(src)
