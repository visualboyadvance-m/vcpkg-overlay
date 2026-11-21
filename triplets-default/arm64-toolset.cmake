# Name the newest MSVC toolset that actually holds an ARM64 compiler.
#
# vcpkg takes every directory under VC/Tools/MSVC as a toolset and works out
# which architectures it can target from the vcvars*.bat files beside
# vcvarsall.bat -- which belong to the Visual Studio instance and not to any
# one toolset (find_toolsets in vcpkg-tool's src/vcpkg/visualstudio.cpp). A
# toolset installed without the ARM64 cross compiler is therefore still offered
# for an ARM64 target, and since vcpkg prefers the newest it is preferred.
#
# vcvarsall pinned to it with -vcvars_ver cannot fall back to a toolset that
# has one, and does not fail either: it leaves the host compiler on PATH and
# the host CRT in LIB. So zlib:arm64-windows configured with
# bin/Hostx64/x64/cl.exe, linked /machine:x64, and died on
# "LNK1104: cannot open file 'MSVCRTD.lib'" -- an error that says nothing about
# the toolset it came from. This builder's preview toolset is such an install:
# 14.53.36930 ships lib/arm64 and no bin/Hostx64/arm64, while the release
# toolset beside it, 14.52.37025, has both.
#
# Found rather than pinned, so the next Visual Studio update does not leave a
# version behind here that no longer exists. Finding nothing leaves
# VCPKG_PLATFORM_TOOLSET_VERSION unset and vcpkg chooses as it did before.
if(NOT DEFINED VCPKG_PLATFORM_TOOLSET_VERSION AND DEFINED ENV{VSINSTALLDIR})
    file(TO_CMAKE_PATH "$ENV{VSINSTALLDIR}" _vbam_vs_root)
    string(REGEX REPLACE "/+$" "" _vbam_vs_root "${_vbam_vs_root}")

    file(GLOB _vbam_toolsets LIST_DIRECTORIES true "${_vbam_vs_root}/VC/Tools/MSVC/*")
    list(SORT _vbam_toolsets COMPARE NATURAL ORDER DESCENDING)

    foreach(_vbam_toolset IN LISTS _vbam_toolsets)
        foreach(_vbam_host Hostx64 HostArm64 Hostx86)
            if(EXISTS "${_vbam_toolset}/bin/${_vbam_host}/arm64/cl.exe")
                get_filename_component(VCPKG_PLATFORM_TOOLSET_VERSION "${_vbam_toolset}" NAME)
                break()
            endif()
        endforeach()

        if(DEFINED VCPKG_PLATFORM_TOOLSET_VERSION)
            break()
        endif()
    endforeach()

    unset(_vbam_vs_root)
    unset(_vbam_toolsets)
    unset(_vbam_toolset)
    unset(_vbam_host)
endif()
