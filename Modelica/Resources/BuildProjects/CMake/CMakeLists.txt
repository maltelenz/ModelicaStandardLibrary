cmake_minimum_required(VERSION 3.15)

# Set MSVC runtime library type
if (POLICY CMP0091)
    cmake_policy(SET CMP0091 NEW)
    if (WIN32 AND CMAKE_GENERATOR MATCHES "Visual Studio .*|NMake.*")
        message(STATUS "Configuring to link the MSVC runtime library statically")
        set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
    endif()
endif()

project(Modelica_Standard_Library_Tables C)

# Check for include files and functions
include(CheckIncludeFile)
include(CheckFunctionExists)

check_include_file("stdarg.h" HAVE_STDARG_H)
if (HAVE_STDARG_H)
    add_definitions(-DHAVE_STDARG_H)
endif()

check_include_file("unistd.h" HAVE_UNISTD_H)
if (HAVE_UNISTD_H)
    add_definitions(-DHAVE_UNISTD_H)
endif()

check_function_exists(memcpy HAVE_MEMCPY)
if (HAVE_MEMCPY)
    add_definitions(-DHAVE_MEMCPY)
endif()

# UNIX configurations...
if (UNIX)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -O3 -Wno-attributes -fno-delete-null-pointer-checks")
endif()

# Set installation prefix
set(MSL_RESOURCES_DIR "${PROJECT_SOURCE_DIR}/../..")
get_filename_component(ABSOLUTE_MSL_RESOURCES_DIR "${MSL_RESOURCES_DIR}" ABSOLUTE)
set(CMAKE_INSTALL_PREFIX "${ABSOLUTE_MSL_RESOURCES_DIR}" CACHE PATH "Library installation prefix path (don't change)" FORCE)

# Include directories...
include_directories("${ABSOLUTE_MSL_RESOURCES_DIR}/C-Sources/zlib")

# ModelicaUtilities.h include...
if (DEFINED MODELICA_UTILITIES_INCLUDE)
    if (NOT MODELICA_UTILITIES_INCLUDE STREQUAL "")
        include_directories(${MODELICA_UTILITIES_INCLUDE})
    else()
        message(FATAL_ERROR "MODELICA_UTILITIES_INCLUDE is an empty string.")
    endif()
else()
    set(MODELICA_UTILITIES_INCLUDE "" CACHE PATH "Include directory of the (tool-vendor specific) ModelicaUtilities.h header file")
    if (NOT MODELICA_UTILITIES_INCLUDE STREQUAL "")
        include_directories(${MODELICA_UTILITIES_INCLUDE})
    else()
        message(FATAL_ERROR "MODELICA_UTILITIES_INCLUDE is an empty string.")
    endif()
endif()

# Target architecture configurations...
if (UNIX)
    if ((CMAKE_SIZEOF_VOID_P EQUAL 8) AND (NOT M32_FLAG))
        set(TARGET_DIR "linux64")
    elseif ((CMAKE_SIZEOF_VOID_P EQUAL 4) OR (M32_FLAG))
        set(TARGET_DIR "linux32")
    else()
        message(FATAL_ERROR "Shouldn't be possible to get here")
    endif()
elseif (MSVC OR MINGW)
    if (CMAKE_SIZEOF_VOID_P EQUAL 8)
        set(TARGET_DIR "win64")
    elseif (CMAKE_SIZEOF_VOID_P EQUAL 4)
        set(TARGET_DIR "win32")
    else()
        message(FATAL_ERROR "Shouldn't be possible to get here")
    endif()
else()
    message(FATAL_ERROR "Not UNIX (or CYGWIN), not MSVC or MINGW => No Support")
endif()

if (WIN32 AND CMAKE_GENERATOR MATCHES "Visual Studio 17.*")
    set(COMPILER_NAME_DIR "vs2022")
elseif (WIN32 AND CMAKE_GENERATOR MATCHES "Visual Studio 16.*")
    set(COMPILER_NAME_DIR "vs2019")
elseif (WIN32 AND CMAKE_GENERATOR MATCHES "Visual Studio 15.*")
    set(COMPILER_NAME_DIR "vs2017")
elseif (WIN32 AND CMAKE_GENERATOR MATCHES "Visual Studio 14.*")
    set(COMPILER_NAME_DIR "vs2015")
elseif (WIN32 AND CMAKE_GENERATOR MATCHES "Visual Studio 12.*")
    set(COMPILER_NAME_DIR "vs2013")
elseif (WIN32 AND CMAKE_GENERATOR MATCHES "Visual Studio 11.*")
    set(COMPILER_NAME_DIR "vs2012")
elseif (WIN32 AND CMAKE_GENERATOR MATCHES "Visual Studio 10.*")
    set(COMPILER_NAME_DIR "vs2010")
elseif (WIN32 AND CMAKE_GENERATOR MATCHES "Visual Studio 9.*")
    set(COMPILER_NAME_DIR "vs2008")
elseif (WIN32 AND CMAKE_GENERATOR MATCHES "Visual Studio 8.*")
    set(COMPILER_NAME_DIR "vs2005")
else()
    set(CMAKE_INSTALL_LIBDIR "")
endif()

if (NOT COMPILER_NAME_DIR STREQUAL "")
    set(CMAKE_INSTALL_LIBDIR "${CMAKE_INSTALL_PREFIX}/Library/${TARGET_DIR}/${COMPILER_NAME_DIR}" CACHE PATH "Library installation path (don't change)" FORCE)
else()
    set(CMAKE_INSTALL_LIBDIR "${CMAKE_INSTALL_PREFIX}/Library/${TARGET_DIR}" CACHE PATH "Library installation path (don't change)" FORCE)
endif()

# Check for 32-bit flag on UNIX
if (UNIX)
    if (($ENV{CFLAGS} MATCHES "-m32") AND ($ENV{CXXFLAGS} MATCHES "-m32"))
        set(M32_FLAG TRUE)
    endif()
endif()

# Source files...
set(EXTC_SOURCES
    "${MSL_RESOURCES_DIR}/C-Sources/ModelicaFFT.c"
    "${MSL_RESOURCES_DIR}/C-Sources/ModelicaInternal.c"
    "${MSL_RESOURCES_DIR}/C-Sources/ModelicaRandom.c"
    "${MSL_RESOURCES_DIR}/C-Sources/ModelicaStrings.c"
)

set(TABLES_SOURCES
    "${MSL_RESOURCES_DIR}/C-Sources/ModelicaStandardTables.c"
    "${MSL_RESOURCES_DIR}/C-Sources/ModelicaStandardTablesUsertab.c"
)

set(MATIO_SOURCES
    "${MSL_RESOURCES_DIR}/C-Sources/ModelicaMatIO.c"
    "${MSL_RESOURCES_DIR}/C-Sources/snprintf.c"
)

set(IO_SOURCES
    "${MSL_RESOURCES_DIR}/C-Sources/ModelicaIO.c"
)

set(ZLIB_SOURCES
    "${MSL_RESOURCES_DIR}/C-Sources/zlib/adler32.c"
    "${MSL_RESOURCES_DIR}/C-Sources/zlib/compress.c"
    "${MSL_RESOURCES_DIR}/C-Sources/zlib/crc32.c"
    "${MSL_RESOURCES_DIR}/C-Sources/zlib/deflate.c"
    "${MSL_RESOURCES_DIR}/C-Sources/zlib/gzclose.c"
    "${MSL_RESOURCES_DIR}/C-Sources/zlib/gzlib.c"
    "${MSL_RESOURCES_DIR}/C-Sources/zlib/gzread.c"
    "${MSL_RESOURCES_DIR}/C-Sources/zlib/gzwrite.c"
    "${MSL_RESOURCES_DIR}/C-Sources/zlib/infback.c"
    "${MSL_RESOURCES_DIR}/C-Sources/zlib/inffast.c"
    "${MSL_RESOURCES_DIR}/C-Sources/zlib/inflate.c"
    "${MSL_RESOURCES_DIR}/C-Sources/zlib/inftrees.c"
    "${MSL_RESOURCES_DIR}/C-Sources/zlib/trees.c"
    "${MSL_RESOURCES_DIR}/C-Sources/zlib/uncompr.c"
    "${MSL_RESOURCES_DIR}/C-Sources/zlib/zutil.c"
)

# Libraries...
add_library(ModelicaExternalC STATIC ${EXTC_SOURCES})
add_library(ModelicaStandardTables STATIC ${TABLES_SOURCES})
add_library(ModelicaMatIO STATIC ${MATIO_SOURCES})
add_library(ModelicaIO STATIC ${IO_SOURCES})
add_library(zlib STATIC ${ZLIB_SOURCES})

# Installation...
install(TARGETS ModelicaStandardTables ModelicaMatIO ModelicaIO zlib
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
)
