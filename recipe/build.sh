#!/usr/bin/env bash
set -euo pipefail

cmake -S . -B build -G Ninja \
    ${CMAKE_ARGS:-} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DCMAKE_PREFIX_PATH="${PREFIX}" \
    -DCMAKE_INSTALL_LIBDIR=lib
cmake --build build --parallel "${CPU_COUNT:-2}"
cmake --install build
