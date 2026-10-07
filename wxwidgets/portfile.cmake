set(wx_patches
    install-layout.patch
    relocatable-wx-config.patch
    nanosvg-ext-depend.patch
    fix-libs-export.patch
    fix-pcre2.patch
    gtk3-link-libraries.patch
#   sdl2.patch
    win-backcompat.patch
    force-exceptions.patch
    wx-macOS.patch
    wxWidgets-riscv64-magic.diff
)

# This patch is only for the Qt port, which is only used for Android below, and
# must not be applied elsewhere: it adds an unconditional <langinfo.h> include
# to src/common/intl.cpp, which doesn't exist under Windows, and drops an
# "override" in include/wx/unix/apptrait.h.
if(VCPKG_TARGET_IS_ANDROID)
    list(APPEND wx_patches wxWidgets-Qt-Android.diff)
endif()

# Pinned to commits, wxWidgets and both of the sources it carries as
# submodules, rather than to the tips of their branches.
#
# github.com/<repo>/archive/refs/heads/<branch> is whatever that branch points
# at when it is asked for. For wxWidgets that meant the SHA512 recorded here
# was true only until the next commit landed upstream, and the port is not
# built until hours after vcpkg-daily.ps1 records it: on 2026-09-28 master
# moved in between and every triplet failed on "download had an unexpected
# hash" before a file was compiled.
#
# lexilla and scintilla had the same problem and a worse symptom, since they
# were fetched with no hash at all. A pin that is a few days behind master
# would have been built against whatever those two branches had reached today,
# which is not the combination the pinned wxWidgets expects and not a
# combination anyone has built. The commits below are the ones wxWidgets
# itself records for those submodules at WX_REF, so an out of date pin is a
# consistent one and still builds.
#
# vcpkg-daily.ps1 rewrites these six by name and updates them together. Their
# being set() rather than written into the calls below is what lets it do that
# without counting lines.
set(WX_REF        74424d09e7684cc9220a0b01782cd7e667e62a69)
set(WX_SHA512     6147a827f8110b25c1fccc668d89f4738c8ddebef826dfb0f5b6c844f1b498fc4d2996e1840342dc12286ad2a00cc334c3896cb9bbd92091610b886fc83978cb)
set(LEXILLA_REF   696ee989b52f718a54869c89576604354f30e153)
set(LEXILLA_SHA512 b741e784c51c21c4db6becda38fb7f11fe57c3d22e4d058f2587ab85b477c6f0a90a08f5d92c81bff10da7702949be99f2eddb6289305e0b08df2081294d92ee)
set(SCINTILLA_REF 0b90f31ced23241054e8088abb50babe9a44ae67)
set(SCINTILLA_SHA512 db1f3007f4bd8860fad0817b6cf87980a4b713777025128cf5caea8d6d17b6fafe23fd22ff6886d7d5a420f241d85b7502b85d7e52b4ddb0774edc4b0a0203e7)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO wxWidgets/wxWidgets
    REF ${WX_REF}
    SHA512 ${WX_SHA512}
    HEAD_REF master
    PATCHES
        ${wx_patches}
)

# Submodule dependencies.
#
# vcpkg_download_distfile rather than file(DOWNLOAD): it checks the hash, says
# something useful when the check fails, and puts the archive in the download
# cache where a rebuild finds it instead of fetching it again.
vcpkg_download_distfile(LEXILLA_ARCHIVE
    URLS     "https://github.com/wxWidgets/lexilla/archive/${LEXILLA_REF}.tar.gz"
    FILENAME "wxwidgets-lexilla-${LEXILLA_REF}.tar.gz"
    SHA512   ${LEXILLA_SHA512}
)
file(ARCHIVE_EXTRACT
    INPUT       "${LEXILLA_ARCHIVE}"
    DESTINATION "${SOURCE_PATH}"
)
file(REMOVE_RECURSE "${SOURCE_PATH}/src/stc/lexilla")
file(RENAME "${SOURCE_PATH}/lexilla-${LEXILLA_REF}" "${SOURCE_PATH}/src/stc/lexilla")

vcpkg_download_distfile(SCINTILLA_ARCHIVE
    URLS     "https://github.com/wxWidgets/scintilla/archive/${SCINTILLA_REF}.tar.gz"
    FILENAME "wxwidgets-scintilla-${SCINTILLA_REF}.tar.gz"
    SHA512   ${SCINTILLA_SHA512}
)
file(ARCHIVE_EXTRACT
    INPUT       "${SCINTILLA_ARCHIVE}"
    DESTINATION "${SOURCE_PATH}"
)
file(REMOVE_RECURSE "${SOURCE_PATH}/src/stc/scintilla")
file(RENAME "${SOURCE_PATH}/scintilla-${SCINTILLA_REF}" "${SOURCE_PATH}/src/stc/scintilla")

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

# Prefer copies over symlinks for the wx-config / wxrc install artifacts.
# On Windows symlinks require admin; on any platform vcpkg expects real files
# in its install tree so downstream relocation works.  wx installs
# bin/wx-config as a relative symlink into ../lib/wx/config, which the move
# into tools/${PORT} further down would leave dangling.
list(APPEND OPTIONS -DwxBUILD_INSTALL_USE_SYMLINK=OFF)

if(VCPKG_TARGET_IS_WINDOWS)
    if(VCPKG_CRT_LINKAGE STREQUAL "dynamic")
        list(APPEND OPTIONS -DwxBUILD_USE_STATIC_RUNTIME=OFF)
    else()
        list(APPEND OPTIONS -DwxBUILD_USE_STATIC_RUNTIME=ON)
    endif()
endif()

if(VCPKG_TARGET_IS_ANDROID)
    list(APPEND OPTIONS -DwxBUILD_TOOLKIT=qt -DCMAKE_OBJCXX_COMPILER_WORKS=ON -DCMAKE_OBJC_COMPILER_WORKS=ON -DwxUSE_SOCKETS=OFF -DwxUSE_URL=OFF -DwxUSE_PROTOCOL_FTP=OFF -DwxUSE_PROTOCOL_HTTP=OFF -DwxUSE_LIBSDL=OFF -DwxUSE_UNICODE_UTF8=ON)
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

set(c_flags "${CMAKE_C_FLAGS} ${VCPKG_C_FLAGS}")
set(cxx_flags "${CMAKE_CXX_FLAGS} ${VCPKG_CXX_FLAGS}")

if(VCPKG_TARGET_IS_MINGW)
    string(APPEND cxx_flags " -fpermissive")
endif()

if(VCPKG_TARGET_IS_WINDOWS)
    # Only MinGW can still target Windows XP: the MSVC toolset able to do it
    # was removed after VS 2017, so use Windows 7 as the baseline there.
    if(VCPKG_TARGET_IS_MINGW AND VCPKG_TARGET_ARCHITECTURE STREQUAL "x86")
        set(win32_winnt 0x0501)
    else()
        set(win32_winnt 0x0601)
    endif()

    # These must be set for both C and C++: wxWidgets checks _WIN32_WINNT in
    # wx/msw/chkconf.h to decide which features can be enabled at all.
    string(APPEND c_flags " -DWINVER=${win32_winnt} -D_WIN32_WINNT=${win32_winnt}")
    string(APPEND cxx_flags " -DWINVER=${win32_winnt} -D_WIN32_WINNT=${win32_winnt}")
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
        -DCMAKE_C_FLAGS=${c_flags}
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

# wxWidgets 3.3.3's wx_get_dependencies (build/cmake/config.cmake) leaks raw
# CMake target names into wx-config's LIBS for imported deps that lack an
# IMPORTED_LOCATION (i.e. vcpkg's NanoSVG), producing entries like
# "-lNanoSVG::nanosvg" that later trip target_link_libraries in downstream
# projects. Strip those; vcpkg-cmake-wrapper.cmake re-adds the real
# NanoSVG::nanosvg{,rast} targets for static builds. Fix targeted for wx 3.3.4
# (see wxwidgets/wxWidgets#23373).
file(GLOB all_configs LIST_DIRECTORIES false
    "${CURRENT_PACKAGES_DIR}/lib/wx/config/*"
    "${CURRENT_PACKAGES_DIR}/debug/lib/wx/config/*"
    "${CURRENT_PACKAGES_DIR}/tools/${PORT}/wx-config"
    "${CURRENT_PACKAGES_DIR}/tools/${PORT}/debug/wx-config")
foreach(config IN LISTS all_configs)
    file(READ "${config}" _cfg)
    string(REGEX REPLACE "-l[A-Za-z0-9_+.-]+::[A-Za-z0-9_+.-]+ *" "" _cfg "${_cfg}")
    file(WRITE "${config}" "${_cfg}")
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
