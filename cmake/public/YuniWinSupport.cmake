#
# YuniWinSupport: Win32/Win64 support 
#

if(__YUNI_WINSUPPORT_INCLUDED)
    return()
endif()

set(__YUNI_WINSUPPORT_INCLUDED)

function(yuni_get_exe_abi var fn)
    # Calc PE header offset
    file(READ ${fn} peoffs OFFSET 60 LIMIT 2 HEX)
    if(${peoffs} STREQUAL "8000")
        set(offs 128)
    elseif(${peoffs} STREQUAL "d800")
        set(offs 216)
    elseif(${peoffs} STREQUAL "e800")
        set(offs 232)
    elseif(${peoffs} STREQUAL "f000")
        set(offs 240)
    elseif(${peoffs} STREQUAL "0001")
        set(offs 256)
    else()
        message(FATAL_ERROR "Unknown PE offset ${fn} = ${peoffs}")
    endif()
    file(READ ${fn} peheader OFFSET ${offs} LIMIT 6 HEX)
    # message(STATUS "${fn} = ${peheader}")

    # Detect machine
    if(${peheader} STREQUAL "504500006486")
        set(${var} "WIN64" PARENT_SCOPE)
    else()
        set(${var} "WIN32" PARENT_SCOPE)
    endif()
endfunction()

function(yuni_path_chop_drive var pth)
    get_filename_component(a ${pth} ABSOLUTE)
    file(TO_NATIVE_PATH ${a} x)
    string(SUBSTRING ${x} 2 -1 out)
    set(${var} ${out} PARENT_SCOPE)
endfunction()
