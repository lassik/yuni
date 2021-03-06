# yunistub for chibi-scheme

include_directories(${CMAKE_CURRENT_LIST_DIR}
    ${CMAKE_CURRENT_LIST_DIR}/../include)

find_path(chibi-scheme_incdir "chibi/eval.h")

if(YUNI_CHIBI_FFI)
    set(stub ${CMAKE_CURRENT_BINARY_DIR}/yuniffi.stub.c)
    set(stubfile "${CMAKE_CURRENT_LIST_DIR}/yuniffi.stub.scm")
    if(chibi-scheme_incdir)
        include_directories(${chibi-scheme_incdir})
    else()
        message(FATAL_ERROR "chibi-scheme header was not found..")
    endif()

    if(APPLE)
        set(sufx .dylib)
    elseif(WIN32 OR CYGWIN)
        # Actually we do not need to set .dll on cygwin...
        set(sufx .dll)
    else()
        set(sufx .so)
    endif()


    # Generate stub source
    add_custom_command(OUTPUT ${stub}
        COMMAND ${YUNI_CHIBI_FFI} ${stubfile} ${stub}
        DEPENDS ${stubfile})
    add_library(chibi-scheme-yuniffi MODULE
        ${stub})
    add_library(chibi-scheme-yuniffi-bridge MODULE
        chibi_scheme_yuniffi_bridge.c
        )
    set_target_properties(chibi-scheme-yuniffi
        PROPERTIES
        PREFIX ""
        SUFFIX ${sufx}
        LIBRARY_OUTPUT_NAME chibi-scheme-yuniffi)
    set_target_properties(chibi-scheme-yuniffi-bridge
        PROPERTIES
        PREFIX ""
        SUFFIX ${sufx}
        LIBRARY_OUTPUT_NAME chibi-scheme-yuniffi-bridge)
    target_link_libraries(chibi-scheme-yuniffi ${YUNI_CHIBI_SCHEME_LIB}) 
    target_link_libraries(chibi-scheme-yuniffi-bridge ${YUNI_CHIBI_SCHEME_LIB}) 
    yuni_runtime_deploy(TARGETS 
        chibi-scheme-yuniffi
        chibi-scheme-yuniffi-bridge)
endif()
