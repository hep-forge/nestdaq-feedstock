#!/usr/bin/env bash
set -euo pipefail

# 1. nestdaq itself
cmake -S . -B build -G Ninja \
    ${CMAKE_ARGS:-} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DCMAKE_PREFIX_PATH="${PREFIX}" \
    -DCMAKE_INSTALL_LIBDIR=lib
cmake --build build --parallel "${CPU_COUNT:-2}"
cmake --install build

# 2. uhbook: header-only booking tool used by nestdaq-user-impl; shipped so
#    user code built against this package can include it too.
install -d "${PREFIX}/include/uhbook"
install -m 644 uhbook/*.h uhbook/uhbook.cxx "${PREFIX}/include/uhbook/"

# 3. nestdaq-user-impl on top, into the same prefix (as upstream installs
#    it); its Sampler and Sink replace the nestdaq examples of that name.
cmake -S user-impl -B build-user-impl -G Ninja \
    ${CMAKE_ARGS:-} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DCMAKE_PREFIX_PATH="${PREFIX}" \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DUHBOOK_HEADER="${SRC_DIR}/uhbook"
cmake --build build-user-impl --parallel "${CPU_COUNT:-2}"
cmake --install build-user-impl
