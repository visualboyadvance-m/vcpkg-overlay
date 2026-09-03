set(VCPKG_LIBRARY_LINKAGE dynamic)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO KhronosGroup/MoltenVK
    REF "v${VERSION}"
    SHA512 8e1ad106c17fd857866b4e18996b3f98b5bf31637e2b2b5766e3e058956214ac7a8cbfa961cca17b9ea7745b2ce9b99038a9839675fca224b5fe11ae8405ba6c
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
