#!/bin/bash
# CDDL HEADER START
#
# This file and its contents are supplied under the terms of the
# Common Development and Distribution License ("CDDL"), version 1.0.
# You may only use this file in accordance with the terms of version
# 1.0 of the CDDL.
#
# A full copy of the text of the CDDL should have accompanied this
# source.  A copy of the CDDL is also available via the Internet at
# http://www.illumos.org/license/CDDL.
#
# CDDL HEADER END

# Copyright 2022 Saso Kiselkov. All rights reserved.

while getopts "a:h" opt; do
	case $opt in
	a)
		LIBACFUTILS_REDIST="$OPTARG"
		;;
	h)
		cat << EOF
Usage: $0 [-nh] -a <libacfutils_redist> [-x]
    -h : shows the current help screen
    -a <libacfutils_redist> : the path to the libacfutils redist (usually $LIBACFUTILS_REDIST)
EOF
		exit
		;;
	*)
		"Unknown argument $opt. Try $0 -h for help." >&2
		exit 1
		;;
	esac
done

if [ -z "$LIBACFUTILS_REDIST" ]; then
	echo "Missing -a argument. Try $0 -h for help" >&2
	exit 1
fi

set -e


CMAKE_OPTS="-DCMAKE_BUILD_TYPE=Release"

rm -rf CMakeCache.txt CMakeFiles Makefile cmake_install.cmake

case "$(uname)" in
Darwin)
  cmake . -DLIBACFUTILS_REDIST="$LIBACFUTILS_REDIST" \
      $CMAKE_OPTS
  cmake --build .
  ;;
Linux)
  cmake . -DLIBACFUTILS_REDIST="$LIBACFUTILS_REDIST" \
      $CMAKE_OPTS
  cmake --build .
  rm -rf CMakeCache.txt CMakeFiles Makefile cmake_install.cmake
  cmake . -DLIBACFUTILS_REDIST="$LIBACFUTILS_REDIST" \
      -DCMAKE_TOOLCHAIN_FILE=XCompile.cmake -DHOST=x86_64-w64-mingw32 \
      $CMAKE_OPTS
  cmake --build .
  ;;
*)
	echo "Unsupported build platform" >&2
	exit 1
	;;
esac
