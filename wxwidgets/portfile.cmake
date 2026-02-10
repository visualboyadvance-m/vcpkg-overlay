vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO wxWidgets/wxWidgets
    REF master
    SHA512 299528b9f1df41c2c6295b827c8327e9d6917df34477891b89d1d75339ff1d9232f1287f2907c5ac2b259c94004209d8f1748af6874f8b05d40c52865a87128c
    PATCHES
        install-layout.patch
        relocatable-wx-config.patch
        nanosvg-ext-depend.patch
        fix-libs-export.patch
        fix-pcre2.patch
        gtk3-link-libraries.patch
        sdl2.patch
        winxp-compat.patch
        force-exceptions.patch
        darkmode_fix.patch
        wx-macOS.patch
)

# Submodule dependencies
vcpkg_from_github(
    OUT_SOURCE_PATH lexilla_SOURCE_PATH
    REPO wxWidgets/lexilla
    REF "0dbce0b418b8b3d2ef30304d0bf53ff58c07ed84"
    SHA512 299528b9f1df41c2c6295b827c8327e9d6917df34477891b89d1d75339ff1d9232f1287f2907c5ac2b259c94004209d8f1748af6874f8b05d40c52865a87128c
    HEAD_REF wx
)
file(COPY "${lexilla_SOURCE_PATH}/" DESTINATION "${SOURCE_PATH}/src/stc/lexilla")
vcpkg_from_github(
    OUT_SOURCE_PATH scintilla_SOURCE_PATH
    REPO wxWidgets/scintilla
    REF "0b90f31ced23241054e8088abb50babe9a44ae67"
    SHA512 299528b9f1df41c2c6295b827c8327e9d6917df34477891b89d1d75339ff1d9232f1287f2907c5ac2b259c94004209d8f1748af6874f8b05d40c52865a87128c
    HEAD_REF wx
)
file(COPY "${scintilla_SOURCE_PATH}/" DESTINATION "${SOURCE_PATH}/src/stc/scintilla")

vcpkg_check_features(
    OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        fonts   wxUSE_PRIVATE_FONTS
        media   wxUSE_MEDIACTRL
        secretstore wxUSE_SECRETSTORE
        sound   wxUSE_SOUND
        webview wxUSE_WEBVIEW
)

set(OPTIONS_RELEASE "")
if(NOT "debug-support" IN_LIST FEATURES)
    list(APPEND OPTIONS_RELEASE "-DwxBUILD_DEBUG_LEVEL=0")
endif()

set(OPTIONS "")
if(VCPKG_TARGET_IS_WINDOWS AND (VCPKG_TARGET_ARCHITECTURE STREQUAL "arm64" OR VCPKG_TARGET_ARCHITECTURE STREQUAL "arm"))
    list(APPEND OPTIONS
        -DwxUSE_STACKWALKER=OFF
    )
endif()

if(VCPKG_TARGET_IS_WINDOWS OR VCPKG_TARGET_IS_OSX)
    list(APPEND OPTIONS -DwxUSE_WEBREQUEST_CURL=OFF)
else()
    list(APPEND OPTIONS -DwxUSE_WEBREQUEST_CURL=ON)
endif()

if(VCPKG_TARGET_IS_WINDOWS)
    if(VCPKG_CRT_LINKAGE STREQUAL "dynamic")
        list(APPEND OPTIONS -DwxBUILD_USE_STATIC_RUNTIME=OFF)
    else()
        list(APPEND OPTIONS -DwxBUILD_USE_STATIC_RUNTIME=ON)
    endif()
endif()

if("webview" IN_LIST FEATURES)
    if(VCPKG_TARGET_ARCHITECTURE STREQUAL "x86" AND VCPKG_TARGET_IS_MINGW)
        list(APPEND OPTIONS -DwxUSE_WEBVIEW=ON -DwxUSE_WEBVIEW_EDGE=OFF -DwxUSE_WEBVIEW_IE=ON)
    else()
        list(APPEND OPTIONS -DwxUSE_WEBVIEW_EDGE=ON)
        if(VCPKG_LIBRARY_LINKAGE STREQUAL "static")
            list(APPEND OPTIONS -DwxUSE_WEBVIEW_EDGE_STATIC=ON)
        endif()
    endif()
endif()

vcpkg_find_acquire_program(PKGCONFIG)

# This may be set to ON by users in a custom triplet.
# The use of 'WXWIDGETS_USE_STD_CONTAINERS' (ON or OFF) is not API compatible
# which is why it must be set in a custom triplet rather than a port feature.
# For backwards compatibility, we also replace 'wxUSE_STL' (which no longer
# exists) with 'wxUSE_STD_STRING_CONV_IN_WXSTRING' which still exists and was
# set by `wxUSE_STL` previously.
set(WXWIDGETS_USE_STL ON)
set(WXWIDGETS_USE_STD_CONTAINERS ON)

if(NOT DEFINED WXWIDGETS_USE_STL)
    set(WXWIDGETS_USE_STL OFF)
endif()

if(NOT DEFINED WXWIDGETS_USE_STD_CONTAINERS)
    set(WXWIDGETS_USE_STD_CONTAINERS OFF)
endif()

set(cxx_flags "${CMAKE_CXX_FLAGS} ${VCPKG_CXX_FLAGS}")
if(VCPKG_TARGET_IS_MINGW)
    if(VCPKG_TARGET_ARCHITECTURE STREQUAL "x86")
        set(cxx_flags "${cxx_Flags} -fpermissive -DWINVER=0x0501 -D_WIN32_WINNT=0x0501")
    elseif(VCPKG_TARGET_ARCHITECTURE STREQUAL "x64")
        set(cxx_flags "${cxx_Flags} -fpermissive -DWINVER=0x0601 -D_WIN32_WINNT=0x0601")
    endif()
endif()

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        ${FEATURE_OPTIONS}
        -DwxUSE_REGEX=sys
        -DwxUSE_ZLIB=sys
        -DwxUSE_EXPAT=sys
        -DwxUSE_LIBJPEG=sys
        -DwxUSE_LIBPNG=sys
        -DwxUSE_LIBTIFF=sys
        -DwxUSE_NANOSVG=sys
        -DwxUSE_LIBWEBP=sys
        -DwxUSE_GLCANVAS=ON
        -DwxUSE_EXCEPTIONS=ON
        -DwxUSE_LIBGNOMEVFS=OFF
        -DwxUSE_LIBNOTIFY=OFF
        -DwxUSE_STD_STRING_CONV_IN_WXSTRING=${WXWIDGETS_USE_STL}
        -DwxUSE_STD_CONTAINERS=${WXWIDGETS_USE_STD_CONTAINERS}
        -DwxUSE_UIACTIONSIMULATOR=OFF
        -DCMAKE_DISABLE_FIND_PACKAGE_GSPELL=ON
        -DCMAKE_DISABLE_FIND_PACKAGE_MSPACK=ON
        -DwxBUILD_INSTALL_RUNTIME_DIR:PATH=bin
        ${OPTIONS}
        "-DPKG_CONFIG_EXECUTABLE=${PKGCONFIG}"
        # The minimum cmake version requirement for Cotire is 2.8.12.
        # however, we need to declare that the minimum cmake version requirement is at least 3.1 to use CMAKE_PREFIX_PATH as the path to find .pc.
        -DPKG_CONFIG_USE_CMAKE_PREFIX_PATH=ON
        -DCMAKE_CXX_FLAGS=${cxx_flags}
    OPTIONS_RELEASE
        ${OPTIONS_RELEASE}
    MAYBE_UNUSED_VARIABLES
        CMAKE_DISABLE_FIND_PACKAGE_GSPELL
        CMAKE_DISABLE_FIND_PACKAGE_MSPACK
)

vcpkg_cmake_install()
vcpkg_cmake_config_fixup(CONFIG_PATH lib/cmake/wxWidgets-3.3)

# The CMake export is not ready for use: It lacks a config file.
file(REMOVE_RECURSE
    ${CURRENT_PACKAGES_DIR}/lib/cmake
    ${CURRENT_PACKAGES_DIR}/debug/lib/cmake
)

set(tools wxrc)
if(NOT VCPKG_TARGET_IS_WINDOWS)
    list(APPEND tools wxrc-3.3)
    file(MAKE_DIRECTORY "${CURRENT_PACKAGES_DIR}/tools/${PORT}")
    file(RENAME "${CURRENT_PACKAGES_DIR}/bin/wx-config" "${CURRENT_PACKAGES_DIR}/tools/${PORT}/wx-config")
    if(NOT VCPKG_BUILD_TYPE)
        file(MAKE_DIRECTORY "${CURRENT_PACKAGES_DIR}/tools/${PORT}/debug")
        file(RENAME "${CURRENT_PACKAGES_DIR}/debug/bin/wx-config" "${CURRENT_PACKAGES_DIR}/tools/${PORT}/debug/wx-config")
    endif()
endif()
vcpkg_copy_tools(TOOL_NAMES ${tools} AUTO_CLEAN)

# do the copy pdbs now after the dlls got moved to the expected /bin folder above
vcpkg_copy_pdbs()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/include/msvc")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/lib/mswu")
if(VCPKG_BUILD_TYPE STREQUAL "release")
    file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/lib/mswud")
endif()

file(GLOB_RECURSE INCLUDES "${CURRENT_PACKAGES_DIR}/include/*.h")
if(EXISTS "${CURRENT_PACKAGES_DIR}/lib/mswu/wx/setup.h")
    list(APPEND INCLUDES "${CURRENT_PACKAGES_DIR}/lib/mswu/wx/setup.h")
endif()
if(EXISTS "${CURRENT_PACKAGES_DIR}/debug/lib/mswud/wx/setup.h")
    list(APPEND INCLUDES "${CURRENT_PACKAGES_DIR}/debug/lib/mswud/wx/setup.h")
endif()
foreach(INC IN LISTS INCLUDES)
    file(READ "${INC}" _contents)
    if(VCPKG_LIBRARY_LINKAGE STREQUAL "static")
        string(REPLACE "defined(WXUSINGDLL)" "0" _contents "${_contents}")
    else()
        string(REPLACE "defined(WXUSINGDLL)" "1" _contents "${_contents}")
    endif()
    # Remove install prefix from setup.h to ensure package is relocatable
    string(REGEX REPLACE "\n#define wxINSTALL_PREFIX [^\n]*" "\n#define wxINSTALL_PREFIX \"\"" _contents "${_contents}")
    file(WRITE "${INC}" "${_contents}")
endforeach()

if(NOT EXISTS "${CURRENT_PACKAGES_DIR}/include/wx/setup.h")
    file(GLOB_RECURSE WX_SETUP_H_FILES_DBG "${CURRENT_PACKAGES_DIR}/debug/lib/*.h")
    file(GLOB_RECURSE WX_SETUP_H_FILES_REL "${CURRENT_PACKAGES_DIR}/lib/*.h")

    if(NOT DEFINED VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL "release")
        vcpkg_replace_string("${WX_SETUP_H_FILES_REL}" "${CURRENT_PACKAGES_DIR}" "" IGNORE_UNCHANGED)

        string(REPLACE "${CURRENT_PACKAGES_DIR}/lib/" "" WX_SETUP_H_FILES_REL "${WX_SETUP_H_FILES_REL}")
        string(REPLACE "/setup.h" "" WX_SETUP_H_REL_RELATIVE "${WX_SETUP_H_FILES_REL}")
    endif()
    if(NOT DEFINED VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL "debug")
        vcpkg_replace_string("${WX_SETUP_H_FILES_DBG}" "${CURRENT_PACKAGES_DIR}" "" IGNORE_UNCHANGED)

        string(REPLACE "${CURRENT_PACKAGES_DIR}/debug/lib/" "" WX_SETUP_H_FILES_DBG "${WX_SETUP_H_FILES_DBG}")
        string(REPLACE "/setup.h" "" WX_SETUP_H_DBG_RELATIVE "${WX_SETUP_H_FILES_DBG}")
    endif()

    configure_file("${CMAKE_CURRENT_LIST_DIR}/setup.h.in" "${CURRENT_PACKAGES_DIR}/include/wx/setup.h" @ONLY)
endif()

file(GLOB configs LIST_DIRECTORIES false "${CURRENT_PACKAGES_DIR}/lib/wx/config/*" "${CURRENT_PACKAGES_DIR}/tools/${PORT}/wx-config")
foreach(config IN LISTS configs)
    vcpkg_replace_string("${config}" "${CURRENT_INSTALLED_DIR}" [[${prefix}]])
endforeach()
file(GLOB configs LIST_DIRECTORIES false "${CURRENT_PACKAGES_DIR}/debug/lib/wx/config/*" "${CURRENT_PACKAGES_DIR}/tools/${PORT}/debug/wx-config")
foreach(config IN LISTS configs)
    vcpkg_replace_string("${config}" "${CURRENT_INSTALLED_DIR}/debug" [[${prefix}]])
endforeach()

# For CMake multi-config in connection with wrapper
if(EXISTS "${CURRENT_PACKAGES_DIR}/debug/lib/mswud/wx/setup.h")
    file(INSTALL "${CURRENT_PACKAGES_DIR}/debug/lib/mswud/wx/setup.h"
        DESTINATION "${CURRENT_PACKAGES_DIR}/lib/mswud/wx"
    )
endif()

if(NOT "debug-support" IN_LIST FEATURES)
    if(VCPKG_TARGET_IS_WINDOWS)
        vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/include/wx/debug.h" "#define wxDEBUG_LEVEL 1" "#define wxDEBUG_LEVEL 0")
    else()
        vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/include/wx-3.3/wx/debug.h" "#define wxDEBUG_LEVEL 1" "#define wxDEBUG_LEVEL 0")
    endif()
endif()

if("example" IN_LIST FEATURES)
    file(INSTALL
        "${CMAKE_CURRENT_LIST_DIR}/example/CMakeLists.txt"
        "${SOURCE_PATH}/samples/popup/popup.cpp"
        "${SOURCE_PATH}/samples/sample.xpm"
        DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}/example"
    )
    vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/share/${PORT}/example/popup.cpp" "../sample.xpm" "sample.xpm")
endif()

configure_file("${CMAKE_CURRENT_LIST_DIR}/vcpkg-cmake-wrapper.cmake" "${CURRENT_PACKAGES_DIR}/share/${PORT}/vcpkg-cmake-wrapper.cmake" @ONLY)

file(REMOVE "${CURRENT_PACKAGES_DIR}/wxwidgets.props")
file(REMOVE "${CURRENT_PACKAGES_DIR}/debug/wxwidgets.props")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/build")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/build")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")

file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/docs/licence.txt")
