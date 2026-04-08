set(VCPKG_LIBRARY_LINKAGE dynamic)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO KhronosGroup/MoltenVK
    REF "v${VERSION}"
    SHA512 ce2b78a8dffb18e2f95ce6f346b462b8965d051f666e6af9a2c5b6bd4060526b2fecf40a25092008258f439eccf1b21bc43653476d62f2e100f8ac2b0b44b0fa
    HEAD_REF main
)

# Needed to make port install vulkan.pc
vcpkg_find_acquire_program(PKGCONFIG)
set(ENV{PKG_CONFIG} "${PKGCONFIG}")

vcpkg_cmake_configure(
  SOURCE_PATH "${SOURCE_PATH}"
  OPTIONS
    -DFETCHCONTENT_FULLY_DISCONNECTED=OFF
    -DCMAKE_OSX_DEPLOYMENT_TARGET=11.0
    ${FEATURE_OPTIONS}
)
vcpkg_cmake_install()
vcpkg_fixup_pkgconfig()

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")

set(VCPKG_POLICY_EMPTY_INCLUDE_FOLDER enabled)

configure_file("${CMAKE_CURRENT_LIST_DIR}/usage" "${CURRENT_PACKAGES_DIR}/share/${PORT}/usage" @ONLY)
