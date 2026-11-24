# Put the triplet's own toolchain first on PATH, whatever environment vcpkg was
# started from. See x64-mingw-static.cmake beside this for why.
#
# x86 is a cross build on this host, so vcpkg's mingw toolchain does name the
# compiler, i686-w64-mingw32-gcc -- but finds it on PATH, and when it is not
# there CMake falls back to looking for any compiler, which under the MSVC
# environment of another pass is cl.exe.
include(${VCPKG_ROOT_DIR}/triplets/community/x86-mingw-static.cmake)

set(ENV{PATH} "C:/msys64/mingw32/bin;$ENV{PATH}")
