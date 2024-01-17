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

option(MODELICA_DEBUG_TIME_EVENTS "Trace time events of CombiTimeTable" OFF)
option(MODELICA_SHARE_TABLE_DATA "Store shared table arrays (read from file) in a global hash table" ON)
option(MODELICA_COPY_TABLE_DATA "Deep-copy table arrays (passed as array)" ON)
option(MODELICA_DUMMY_FUNCTION_USERTAB "Add a dummy usertab function" OFF)

# Check for include attributes, files, functions
include(CheckCSourceCompiles)
include(CheckIncludeFile)
include(CheckSymbolExists)

check_include_file("locale.h" HAVE_LOCALE_H)
if (NOT HAVE_LOCALE_H)
    add_definitions(-DNO_LOCALE)
endif()
check_include_file("pthread.h" HAVE_PTHREAD_H)
if (NOT HAVE_PTHREAD_H AND NOT WIN32)
    add_definitions(-DNO_MUTEX)
endif()
check_include_file("stdarg.h" HAVE_STDARG_H)
if (HAVE_STDARG_H)
    add_definitions(-DHAVE_STDARG_H)
endif()
check_include_file("dirent.h" HAVE_DIRENT_H)
if (NOT HAVE_DIRENT_H AND NOT WIN32)
    add_definitions(-DNO_FILE_SYSTEM)
endif()
check_include_file("time.h" HAVE_TIME_H)
if (NOT HAVE_TIME_H)
    add_definitions(-DNO_TIME)
endif()
check_include_file("unistd.h" HAVE_UNISTD_H)
if (HAVE_UNISTD_H)
    add_definitions(-DHAVE_UNISTD_H)
    check_c_source_compiles(
        "
            #include <unistd.h>
            int main(void) {getpid(); return 0;}
        "
        HAVE_GETPID
    )
    if (NOT HAVE_GETPID)
        add_definitions(-DNO_PID)
    endif()
endif()
check_symbol_exists(memcpy "string.h" HAVE_MEMCPY)
if (HAVE_MEMCPY)
    add_definitions(-DHAVE_MEMCPY)
endif()
check_c_source_compiles(
    "
        #include <stdlib.h>
        static void f(void) __attribute__ ((visibility(\"hidden\")));
        int main(void) {return 0;}
    "
    HAVE_ATTRIBUTE_VISIBILITY_HIDDEN
)
if (HAVE_ATTRIBUTE_VISIBILITY_HIDDEN)
    add_definitions(-DHAVE_HIDDEN)
endif()

# UNIX configurations...
if (UNIX)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -O3 -Wno-attributes -fno-delete-null-pointer-checks")
endif()

# Set installation prefix
set(MODELICA_RESOURCES_DIR "${PROJECT_SOURCE_DIR}/../..")
get_filename_component(ABSOLUTE_MODELICA_RESOURCES_DIR "${MODELICA_RESOURCES_DIR}" ABSOLUTE)
set(CMAKE_INSTALL_PREFIX "${ABSOLUTE_MODELICA_RESOURCES_DIR}" CACHE PATH "Library installation prefix path (don't change)" FORCE)

# Include directories...
include_directories("${ABSOLUTE_MODELICA_RESOURCES_DIR}/C-Sources/zlib")

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
    "${MODELICA_RESOURCES_DIR}/C-Sources/ModelicaFFT.c"
    "${MODELICA_RESOURCES_DIR}/C-Sources/ModelicaFFT.h"
    "${MODELICA_RESOURCES_DIR}/C-Sources/ModelicaInternal.c"
    "${MODELICA_RESOURCES_DIR}/C-Sources/ModelicaInternal.h"
    "${MODELICA_RESOURCES_DIR}/C-Sources/ModelicaRandom.c"
    "${MODELICA_RESOURCES_DIR}/C-Sources/ModelicaRandom.h"
    "${MODELICA_RESOURCES_DIR}/C-Sources/ModelicaStrings.c"
    "${MODELICA_RESOURCES_DIR}/C-Sources/ModelicaStrings.h"
    "${MODELICA_RESOURCES_DIR}/C-Sources/gconstructor.h"
    "${MODELICA_RESOURCES_DIR}/C-Sources/stdint_msvc.h"
    "${MODELICA_RESOURCES_DIR}/C-Sources/stdint_wrap.h"
    "${MODELICA_RESOURCES_DIR}/C-Sources/uthash.h"
    "${MODELICA_RESOURCES_DIR}/C-Sources/win32_dirent.c"
    "${MODELICA_RESOURCES_DIR}/C-Sources/win32_dirent.h"
    "${MODELICA_UTILITIES_INCLUDE}/ModelicaUtilities.h"
)

set(TABLES_SOURCES
    "${MODELICA_RESOURCES_DIR}/C-Sources/ModelicaStandardTables.c"
    "${MODELICA_RESOURCES_DIR}/C-Sources/ModelicaStandardTables.h"
    "${MODELICA_RESOURCES_DIR}/C-Sources/ModelicaStandardTablesUsertab.c"
    "${MODELICA_RESOURCES_DIR}/C-Sources/ModelicaMatIO.h"
    "${MODELICA_RESOURCES_DIR}/C-Sources/gconstructor.h"
    "${MODELICA_RESOURCES_DIR}/C-Sources/stdint_msvc.h"
    "${MODELICA_RESOURCES_DIR}/C-Sources/stdint_wrap.h"
    "${MODELICA_RESOURCES_DIR}/C-Sources/uthash.h"
    "${MODELICA_UTILITIES_INCLUDE}/ModelicaUtilities.h"
)

set(MATIO_SOURCES
    "${MODELICA_RESOURCES_DIR}/C-Sources/ModelicaMatIO.c"
    "${MODELICA_RESOURCES_DIR}/C-Sources/ModelicaMatIO.h"
    "${MODELICA_RESOURCES_DIR}/C-Sources/read_data_impl.h"
    "${MODELICA_RESOURCES_DIR}/C-Sources/safe-math.h"
    "${MODELICA_RESOURCES_DIR}/C-Sources/snprintf.c"
    "${MODELICA_RESOURCES_DIR}/C-Sources/stdint_msvc.h"
    "${MODELICA_RESOURCES_DIR}/C-Sources/zlib/zlib.h"
    "${MODELICA_UTILITIES_INCLUDE}/ModelicaUtilities.h"
)

set(IO_SOURCES
    "${MODELICA_RESOURCES_DIR}/C-Sources/ModelicaIO.c"
    "${MODELICA_RESOURCES_DIR}/C-Sources/ModelicaIO.h"
    "${MODELICA_RESOURCES_DIR}/C-Sources/ModelicaMatIO.h"
    "${MODELICA_UTILITIES_INCLUDE}/ModelicaUtilities.h"
)

file(GLOB ZLIB_SOURCES
    "${MODELICA_RESOURCES_DIR}/C-Sources/zlib/*.c"
    "${MODELICA_RESOURCES_DIR}/C-Sources/zlib/*.h"
)

# Libraries...
add_library(ModelicaExternalC STATIC ${EXTC_SOURCES})
add_library(ModelicaStandardTables STATIC ${TABLES_SOURCES})
add_library(ModelicaMatIO STATIC ${MATIO_SOURCES})
add_library(ModelicaIO STATIC ${IO_SOURCES})
add_library(zlib STATIC ${ZLIB_SOURCES})

if (MODELICA_DEBUG_TIME_EVENTS)
    target_compile_definitions(ModelicaStandardTables PUBLIC -DDEBUG_TIME_EVENTS=1)
endif()
if (MODELICA_SHARE_TABLE_DATA)
    target_compile_definitions(ModelicaStandardTables PUBLIC -DTABLE_SHARE=1)
endif()
if (NOT MODELICA_COPY_TABLE_DATA)
    target_compile_definitions(ModelicaStandardTables PUBLIC -DNO_TABLE_COPY=1)
endif()
if (MODELICA_DUMMY_FUNCTION_USERTAB)
    target_compile_definitions(ModelicaStandardTables PUBLIC -DDUMMY_FUNCTION_USERTAB=1)
endif()
target_compile_definitions(ModelicaMatIO PUBLIC -DHAVE_ZLIB=1)

# Installation...
install(TARGETS ModelicaStandardTables ModelicaMatIO ModelicaIO zlib
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
)
