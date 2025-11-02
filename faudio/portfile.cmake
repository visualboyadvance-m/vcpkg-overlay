vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO FNA-XNA/faudio
    REF "${VERSION}"
    SHA512 00a3b6d7eb1fa91547f06fc0ec9bd9e7f956d2244568da3ba5144641113a6040c94c0b1d0b32da37ac1a4b51de8322afb8947c5d8817dc1e6de3214f086ee554
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
