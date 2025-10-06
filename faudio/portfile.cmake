vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO FNA-XNA/faudio
    REF "${VERSION}"
    SHA512 08f4f8ca74c2c8d885b88388d420691358ca357b1f3f03bb1aa778cb0b9115e4ed7446fedaaa83c5b95e8a306ad596acb090fe6dfa11055b7588a342f8bf185c
    HEAD_REF master
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
