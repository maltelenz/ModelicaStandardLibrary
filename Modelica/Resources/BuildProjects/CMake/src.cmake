if(NOT HAVE_LOCALE_H)
  add_definitions(-DNO_LOCALE)
endif()
if(NOT HAVE_PTHREAD_H AND NOT WIN32)
  add_definitions(-DNO_MUTEX)
endif()
if(HAVE_STDARG_H)
  add_definitions(-DHAVE_STDARG_H)
endif()
if(HAVE_UNISTD_H)
  add_definitions(-DHAVE_UNISTD_H)
endif()
if(NOT HAVE_DIRENT_H AND NOT WIN32)
  add_definitions(-DNO_FILE_SYSTEM)
endif()
if(NOT HAVE_TIME_H)
  add_definitions(-DNO_TIME)
endif()
if(HAVE_UNISTD_H)
  if(NOT HAVE_GETPID)
    add_definitions(-DNO_PID)
  endif()
endif()
if(HAVE_MEMCPY)
  add_definitions(-DHAVE_MEMCPY)
endif()

if(UNIX)
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -O3 -Wno-attributes -fno-delete-null-pointer-checks")
elseif(MSVC)
  add_definitions(-D_CRT_SECURE_NO_WARNINGS /W3)
endif()

if(MODELICA_BUILD_ZLIB)
  set(ZLIB_HEADER_LOCATION "${MODELICA_RESOURCES_DIR}/C-Sources/zlib")
elseif(NOT DEFINED ZLIB_HEADER_LOCATION)
  message(FATAL_ERROR "MODELICA_BUILD_ZLIB was turned off, but ZLIB_HEADER_LOCATION was not provided.")
endif()

include_directories("${ZLIB_HEADER_LOCATION}")

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
  "${ZLIB_HEADER_LOCATION}/zlib.h"
  "${MODELICA_UTILITIES_INCLUDE}/ModelicaUtilities.h"
)

set(IO_SOURCES
  "${MODELICA_RESOURCES_DIR}/C-Sources/ModelicaIO.c"
  "${MODELICA_RESOURCES_DIR}/C-Sources/ModelicaIO.h"
  "${MODELICA_RESOURCES_DIR}/C-Sources/ModelicaMatIO.h"
  "${MODELICA_UTILITIES_INCLUDE}/ModelicaUtilities.h"
)

if(MODELICA_BUILD_ZLIB)
  file(GLOB ZLIB_SOURCES
    "${MODELICA_RESOURCES_DIR}/C-Sources/zlib/*.c"
    "${MODELICA_RESOURCES_DIR}/C-Sources/zlib/*.h"
  )
endif()

add_library(ModelicaExternalC STATIC ${EXTC_SOURCES})
add_library(ModelicaStandardTables STATIC ${TABLES_SOURCES})
add_library(ModelicaMatIO STATIC ${MATIO_SOURCES})
add_library(ModelicaIO STATIC ${IO_SOURCES})

if(MODELICA_BUILD_ZLIB)
  add_library(zlib STATIC ${ZLIB_SOURCES})
endif()

if(MODELICA_DEBUG_TIME_EVENTS)
  target_compile_definitions(ModelicaStandardTables PUBLIC -DDEBUG_TIME_EVENTS=1)
endif()
if(MODELICA_SHARE_TABLE_DATA)
  target_compile_definitions(ModelicaStandardTables PUBLIC -DTABLE_SHARE=1)
endif()
if(NOT MODELICA_COPY_TABLE_DATA)
  target_compile_definitions(ModelicaStandardTables PUBLIC -DNO_TABLE_COPY=1)
endif()
if(MODELICA_DUMMY_FUNCTION_USERTAB)
  target_compile_definitions(ModelicaStandardTables PUBLIC -DDUMMY_FUNCTION_USERTAB=1)
endif()
if(MODELICA_BUILD_ZLIB AND (HAVE_WINAPIFAMILY_H OR (HAVE__OPEN AND HAVE__READ AND HAVE__WRITE AND HAVE__CLOSE)))
  target_compile_definitions(zlib PUBLIC -DWINAPI_FAMILY=100)
endif()
target_compile_definitions(ModelicaMatIO PUBLIC -DHAVE_ZLIB=1)
if(MSVC)
  target_compile_options(ModelicaMatIO PUBLIC /wd4267)
endif()

install(
  TARGETS ModelicaStandardTables ModelicaMatIO ModelicaIO
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
)

if(MODELICA_BUILD_ZLIB)
  install(
    TARGETS zlib
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
  )
endif()

if(MODELICA_INSTALL_EXTC)
  install(
    TARGETS ModelicaExternalC
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
  )
endif()
