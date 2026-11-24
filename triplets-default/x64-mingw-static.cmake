# Put the triplet's own toolchain first on PATH, whatever environment vcpkg was
# started from.
#
# The mingw triplets take PATH through untouched (VCPKG_ENV_PASSTHROUGH_UNTRACKED)
# and leave the compiler to CMake, which takes the first one it finds there --
# x64 is not a cross build, so vcpkg's mingw toolchain names none. The builder
# puts clang64 on PATH for its own mingw pass, but a port is also rebuilt from
# whatever pass upgrades one of its dependencies: upgrading pcre2:x64-windows
# rebuilds qtbase for every triplet in one vcpkg call, under the MSVC
# environment of the x64-windows pass. qtbase:x64-mingw-static was configured
# with cl.exe and died on "LNK1104: cannot open file 'kernel32.lib'", the MSVC
# LIB not being passed through.
#
# Prepended rather than replaced, so the rest of PATH -- python, git, the msys
# tools vcpkg fetches -- is still there.
include(${VCPKG_ROOT_DIR}/triplets/community/x64-mingw-static.cmake)

set(ENV{PATH} "C:/msys64/clang64/bin;$ENV{PATH}")
