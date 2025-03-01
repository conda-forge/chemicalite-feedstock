#!/bin/bash

if [[ "$CONDA_BUILD_CROSS_COMPILATION" == "1" ]]; then
  sed -i "/INTERFACE_INCLUDE_DIRECTORIES/c\  INTERFACE_INCLUDE_DIRECTORIES \"$PREFIX/include/rdkit;$PREFIX/include\"" "$PREFIX/lib/cmake/rdkit/rdkit-targets.cmake"
  sed -i 's/ -Werror//' "$SRC_DIR/CMakeLists.txt"
fi

if [[ "$target_platform" == osx-arm64 ]] || [[ "$target_platform" == osx-64 ]]; then
    export CXXFLAGS="-D_LIBCPP_DISABLE_AVAILABILITY -D_HAS_AUTO_PTR_ETC=0 $CXXFLAGS"
fi

POPCNT_OPTIMIZATION="ON"
if [[ "$target_platform" == osx-arm64 ]] || [[ "$target_platform" == linux-ppc64le ]] || [[ "$target_platform" == linux-aarch64 ]]; then
    # PowerPC includes -mcpu=power8 optimizations already
    # ARM does not have popcnt instructions, afaik
    POPCNT_OPTIMIZATION="OFF"
fi

cmake ${CMAKE_ARGS} \
    -D CMAKE_INSTALL_PREFIX=$PREFIX \
    -D CMAKE_INSTALL_LIBDIR=lib \
    -D CMAKE_BUILD_TYPE=Release \
    -D CMAKE_CATCH_DISCOVER_TESTS_DISCOVERY_MODE=PRE_TEST \
    -D CHEMICALITE_ENABLE_OPTIMIZED_POPCNT="${POPCNT_OPTIMIZATION}" \
    $SRC_DIR

make

if [[ "$target_platform" == linux-64 ]]; then
    LD_LIBRARY_PATH=$PWD/src ctest --output-on-failure
fi

make install
