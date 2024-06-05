# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

# Copyright 2023 Saso Kiselkov. All rights reserved.

cmake_minimum_required(VERSION 3.9)

project(libelec C)

option(LIBACFUTILS_REDIST	"The location of the libacfutils redist directory")
if(${LIBACFUTILS_REDIST} STREQUAL "OFF")
	message("Missing LIBACFUTILS_REDIST option. Call cmake -DLIBACFUTILS_REDIST=<path>.
This must point to where the `acfutils' redist directory is extracted.")
	return()
endif()

option(LIBELEC_VIS	"Set to ON to enable building network visualization \
code (requires X-Plane SDK be available)")

# Source file setup
set(SRC ../src/libelec.c)
set(HDR ../src/libelec.h ../src/libelec_types_impl.h)

if(${LIBELEC_VIS})
	set(SRC ${SRC} ../src/libelec_drawing.c ../src/libelec_vis.c)
	set(HDR ${HDR} ../src/libelec_drawing.h ../src/libelec_vis.h)
endif()

set(ALL_SRC ${SRC} ${HDR})
list(SORT ALL_SRC)

# Instantiates project
add_library(libelec STATIC ${ALL_SRC})

# Compiler setup
if(WIN32)
	set(PLAT_SHORT "mingw64")
elseif(APPLE)
	set(PLAT_SHORT "mac64")
else()
	set(PLAT_SHORT "lin64")
endif()

include_directories(libelec PUBLIC
		"${LIBACFUTILS_REDIST}/include"	# Used by redist version
)
# Visualization support requires XPLM
if(${LIBELEC_VIS})
	include_directories(libelec PUBLIC
	    "${LIBACFUTILS}/${PLAT_SHORT}/include"	# Used by redist version
	    "${CMAKE_SOURCE_DIR}/XPSDK/CHeaders/XPLM"
	    "${CMAKE_SOURCE_DIR}/XPSDK/CHeaders/Widgets"
	    )
endif()

# Compiler flags
set_target_properties(libelec PROPERTIES C_STANDARD_REQUIRED "99")
if(UNIX)
	# Enable maximum warnings and errors
	set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -W -Wall -Wextra -Werror \
	    -Wno-missing-field-initializers")
endif()
if(UNIX AND NOT APPLE)
	# Disable annoying warnings on GCC
	set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-format-truncation \
	    -fno-gnu-unique")
endif()
if(APPLE)
	# Build universal binaries on macOS
	set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -arch x86_64 -arch arm64")
endif()

# Defines

if(WIN32)
	# Needed for threading primitives
	add_definitions(-D_WIN32_WINNT=0x0600)
else()
	# Needed for gmtime_r in libacfutils
	add_definitions(-D_GNU_SOURCE)
endif()

# Platform type switches for libacfutils
if(WIN32)
	add_definitions(-DIBM=1 -DLIN=0 -DAPL=0)
elseif(APPLE)
	add_definitions(-DIBM=0 -DLIN=0 -DAPL=1)
else()
	add_definitions(-DIBM=0 -DLIN=1 -DAPL=0)
endif()

# When we're building with XPLM features (network visualization),
# we need to set XPLM version support flags
if(${LIBELEC_VIS})
	add_definitions(-DXPLM200=1 -DXPLM210=1)
	add_definitions(-DXPLM300=1 -DXPLM301=1 -DXPLM302=1)
else()
	# Stops libacfutils/log.h from complaining about log_xplm_cb()
	add_definitions(-D_LACF_WITHOUT_XPLM)
endif()

if(UNIX)
	# Do not export any symbols as externally visible
	set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fvisibility=hidden")
endif()

# Final build properties
set_target_properties(libelec PROPERTIES PREFIX "")
set_target_properties(libelec PROPERTIES SUFFIX "")
if(WIN32)
	set_target_properties(libelec PROPERTIES OUTPUT_NAME "libelec.lib")
else()
	set_target_properties(libelec PROPERTIES OUTPUT_NAME "libelec.a")
endif()

set_target_properties(libelec PROPERTIES ARCHIVE_OUTPUT_DIRECTORY
    "${CMAKE_SOURCE_DIR}/lib/${PLAT_SHORT}")
