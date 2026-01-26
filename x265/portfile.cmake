vcpkg_from_bitbucket(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO multicoreware/x265_git
    REF "afa0028dda3486bce8441473c6c7b99bec2f0961"
    SHA512 1cc4b4ac538c177486015c0a9af4787019c3312ebfff870afba16c5a8ae72a8efe3b2e92dfb2636d5348a6cb33816b6b521cb91db49ae71e51c4c8c3c01f0ead
    HEAD_REF master
    PATCHES
        disable-install-pdb.patch
        version.patch
        linkage.diff
        pkgconfig.diff
        pthread.diff
        compiler-target.diff
        neon.diff
        fix-cmake-4.patch
        nasm.diff
        winxp.diff
)

vcpkg_check_features(OUT_FEATURE_OPTIONS OPTIONS
    FEATURES
        tool   ENABLE_CLI
)

if(VCPKG_TARGET_ARCHITECTURE STREQUAL "x86" OR VCPKG_TARGET_ARCHITECTURE STREQUAL "x64")
    vcpkg_find_acquire_program(NASM)
    list(APPEND OPTIONS "-DNASM_EXECUTABLE=${NASM}")
    if(VCPKG_LIBRARY_LINKAGE STREQUAL "static" AND NOT VCPKG_TARGET_IS_WINDOWS AND NOT VCPKG_TARGET_IS_OSX)
        # x265 doesn't create sufficient PIC for asm, breaking usage
        # in shared libs, e.g. the libheif gdk pixbuf plugin.
        # Users can override this in custom triplets.
        list(APPEND OPTIONS "-DENABLE_ASSEMBLY=OFF")
    endif()
elseif(VCPKG_TARGET_IS_WINDOWS)
    list(APPEND OPTIONS "-DENABLE_ASSEMBLY=OFF")
endif()

list(APPEND OPTIONS "-DENABLE_ASSEMBLY=OFF")

if(VCPKG_TARGET_ARCHITECTURE STREQUAL "arm64")
    list(APPEND OPTIONS "-DENABLE_ASSEMBLY=OFF")
    list(APPEND OPTIONS "-DENABLE_NEON=OFF")
    list(APPEND OPTIONS "-DENABLE_NEON_DOTPROD=OFF")
    list(APPEND OPTIONS "-DENABLE_NEON_I8MM=OFF")
    list(APPEND OPTIONS "-DENABLE_SVE=OFF")
    list(APPEND OPTIONS "-DENABLE_SVE2=OFF")
    list(APPEND OPTIONS "-DENABLE_SVE2_BITPERM=OFF")
endif()

string(COMPARE EQUAL "${VCPKG_LIBRARY_LINKAGE}" "dynamic" ENABLE_SHARED)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}/source"
    OPTIONS
        ${OPTIONS}
        -DENABLE_SHARED=${ENABLE_SHARED}
        -DENABLE_PIC=ON
        -DENABLE_LIBNUMA=OFF
        "-DVERSION=${VERSION}"
    OPTIONS_DEBUG
        -DENABLE_CLI=OFF
    MAYBE_UNUSED_VARIABLES
        ENABLE_LIBNUMA
)

vcpkg_cmake_install()
vcpkg_copy_pdbs()
vcpkg_fixup_pkgconfig()

if("tool" IN_LIST FEATURES)
    vcpkg_copy_tools(TOOL_NAMES x265 AUTO_CLEAN)
endif()

if(VCPKG_TARGET_IS_WINDOWS AND VCPKG_LIBRARY_LINKAGE STREQUAL "dynamic")
    vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/include/x265.h" "#ifdef X265_API_IMPORTS" "#if 1")
endif()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/COPYING")
