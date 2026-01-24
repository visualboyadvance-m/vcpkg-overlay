vcpkg_download_distfile(FIND_DEPENDENCY_FIX
    URLS https://github.com/FNA-XNA/FAudio/commit/29b82ac28b3c83b5044962e88ea080875f73aebd.diff?full_index=1
    FILENAME faudio-find-dependency-fix-29b82ac28b3c83b5044962e88ea080875f73aebd.diff
    SHA512 001ba2f61a388c634fd927497109f333e86dbdecef6908c64827b6b467bb707df0c17a01054ab0a5c0a74cd1a02d61f888b6938932c871a850a418de40fa9e78
)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO FNA-XNA/faudio
    REF "${VERSION}"
    SHA512 004567c6339ce006afbf19c44ee88e4fab8bfcd7b3e50b25058569584cd0caa891aeaf7087089bafabd646e9739ccc036f984f9f0fb271ba154406e1d30eb2e1
    HEAD_REF master
    PATCHES
        "${FIND_DEPENDENCY_FIX}"
)

set(options "")
if(VCPKG_TARGET_IS_WINDOWS AND (NOT (VCPKG_TARGET_ARCHITECTURE STREQUAL "x86" AND VCPKG_TARGET_IS_MINGW)))
    list(APPEND options -DPLATFORM_WIN32=ON)
endif()

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        ${options}
)

vcpkg_cmake_install()
vcpkg_copy_pdbs()
vcpkg_fixup_pkgconfig()

vcpkg_cmake_config_fixup(CONFIG_PATH lib/cmake/FAudio)

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/include"
    "${CURRENT_PACKAGES_DIR}/debug/share"
)

vcpkg_install_copyright(
    COMMENT "FAudio is licensed under the Zlib license."
    FILE_LIST
       "${SOURCE_PATH}/LICENSE"
)
