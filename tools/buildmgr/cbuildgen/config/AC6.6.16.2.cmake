# This file maps the CMSIS project options to toolchain settings.
#
#   - Applies to toolchain: ARM Compiler 6.16.2 and greater

set(AS "armasm")
set(CC "armclang")
set(CXX "armclang")
set(CPP "armclang")
set(LD "armlink")
set(AR "armar")
set(OC "fromelf")

set(TOOLCHAIN_ROOT "${REGISTERED_TOOLCHAIN_ROOT}")
set(TOOLCHAIN_VERSION "${REGISTERED_TOOLCHAIN_VERSION}")

if(DEFINED TOOLCHAIN_ROOT AND NOT TOOLCHAIN_ROOT STREQUAL "")
  set(EXT)
  set(AS ${TOOLCHAIN_ROOT}/${AS}${EXT})
  set(CC ${TOOLCHAIN_ROOT}/${CC}${EXT})
  set(CXX ${TOOLCHAIN_ROOT}/${CXX}${EXT})
  set(CPP ${TOOLCHAIN_ROOT}/${CPP}${EXT})
  set(LD ${TOOLCHAIN_ROOT}/${LD}${EXT})
  set(AR ${TOOLCHAIN_ROOT}/${AR}${EXT})
  set(OC ${TOOLCHAIN_ROOT}/${OC}${EXT})
endif()

# Helpers

function(cbuild_set_defines lang defines)
  set(TMP_DEFINES)
  foreach(DEFINE ${${defines}})
    string(REPLACE "\"" "\\\"" ENTRY ${DEFINE})
    string(REGEX REPLACE "=.*" "" KEY ${ENTRY})
    if (KEY STREQUAL ENTRY)
      set(VALUE "1")
    else()
      string(REGEX REPLACE ".*=" "" VALUE ${ENTRY})
    endif()
    if(${lang} STREQUAL "AS_LEG" OR ${lang} STREQUAL "AS_ARM")
      if (VALUE MATCHES "^0x[0-9a-fA-F]+|^[0-9]+$")
        set(SETX "SETA")
      else()
        set(SETX "SETS")
      endif()
      if(${lang} STREQUAL "AS_LEG")
        string(APPEND TMP_DEFINES "--pd \"${KEY} ${SETX} ${VALUE}\" ")
      elseif(${lang} STREQUAL "AS_ARM")
        string(APPEND TMP_DEFINES "-Wa,armasm,--pd,\"${KEY} ${SETX} ${VALUE}\" ")
      endif()
    elseif(${lang} STREQUAL "AS_GNU")
      string(APPEND TMP_DEFINES "-Wa,-defsym,\"${KEY}=${VALUE}\" ")
    else()
      string(APPEND TMP_DEFINES "-D${ENTRY} ")
    endif()
  endforeach()
  set(${defines} ${TMP_DEFINES} PARENT_SCOPE)
endfunction()

set(OPTIMIZE_VALUES       "debug" "none" "balanced" "size" "speed")
set(OPTIMIZE_CC_FLAGS     "-O1"   "-O0"  "-O2"      "-Oz"  "-O3")
set(OPTIMIZE_CXX_FLAGS    ${OPTIMIZE_CC_FLAGS})
set(OPTIMIZE_AS_ARM_FLAGS ${OPTIMIZE_CC_FLAGS})
set(OPTIMIZE_AS_GNU_FLAGS ${OPTIMIZE_CC_FLAGS})
set(OPTIMIZE_ASM_FLAGS    ${OPTIMIZE_CC_FLAGS})

set(DEBUG_VALUES          "on"      "off")
set(DEBUG_AS_LEG_FLAGS    "--debug" "")
set(DEBUG_LD_FLAGS        "--debug" "--no_debug")
set(DEBUG_CC_FLAGS        "-g"      "")
set(DEBUG_CXX_FLAGS       "-g"      "")
set(DEBUG_AS_ARM_FLAGS    "-g"      "")
set(DEBUG_AS_GNU_FLAGS    "-g"      "")
set(DEBUG_ASM_FLAGS       "-g"      "")

set(WARNINGS_VALUES       "on" "off"                     "all")
set(WARNINGS_AS_LEG_FLAGS ""   "--no_warn"               "")
set(WARNINGS_LD_FLAGS     ""   "--diag_suppress=warning" "--remarks")
set(WARNINGS_CC_FLAGS     ""   "-w"                      "-Wall")
set(WARNINGS_CXX_FLAGS    ""   "-w"                      "-Wall")
set(WARNINGS_AS_ARM_FLAGS ""   "-w"                      "")
set(WARNINGS_AS_GNU_FLAGS ""   "-w"                      "-Wall")
set(WARNINGS_ASM_FLAGS    ""   "-w"                      "-Wall")

set(LANGUAGE_VALUES       "c90"      "gnu90"      "c99"      "gnu99"      "c11"      "gnu11"      "c17"      "c23"      "c++98"      "gnu++98"      "c++03"      "gnu++03"      "c++11"      "gnu++11"      "c++14"      "gnu++14"      "c++17"      "gnu++17"      "c++20"      "gnu++20"     )
set(LANGUAGE_CC_FLAGS     "-std=c90" "-std=gnu90" "-std=c99" "-std=gnu99" "-std=c11" "-std=gnu11" "-std=c17" "-std=c23" ""           ""             ""           ""             ""           ""             ""           ""             ""           ""             ""           ""            )
set(LANGUAGE_CXX_FLAGS    ""         ""           ""         ""           ""         ""           ""         ""         "-std=c++98" "-std=gnu++98" "-std=c++03" "-std=gnu++03" "-std=c++11" "-std=gnu++11" "-std=c++14" "-std=gnu++14" "-std=c++17" "-std=gnu++17" "-std=c++17" "-std=gnu++17")

function(cbuild_set_option_flags lang option value flags)
  if(NOT DEFINED ${option}_${lang}_FLAGS)
    return()
  endif()
  list(FIND ${option}_VALUES "${value}" _index)
  if (${_index} GREATER -1)
    list(GET ${option}_${lang}_FLAGS ${_index} flag)
    set(${flags} "${flag} ${${flags}}" PARENT_SCOPE)
  elseif(NOT value STREQUAL "")
    string(TOLOWER "${option}" _option)
    message(FATAL_ERROR "unkown '${_option}' value '${value}' !")
  endif()
endfunction()

function(cbuild_set_options_flags lang optimize debug warnings language flags)
  set(opt_flags)
  cbuild_set_option_flags(${lang} OPTIMIZE "${optimize}" opt_flags)
  cbuild_set_option_flags(${lang} DEBUG    "${debug}"    opt_flags)
  cbuild_set_option_flags(${lang} WARNINGS "${warnings}" opt_flags)
  cbuild_set_option_flags(${lang} LANGUAGE "${language}" opt_flags)
  set(${flags} "${opt_flags} ${${flags}}" PARENT_SCOPE)
endfunction()

# Assembler

if(CPU STREQUAL "Cortex-M0")
  set(ARMASM_CPU "--cpu=Cortex-M0")
elseif(CPU STREQUAL "Cortex-M0+")
  set(ARMASM_CPU "--cpu=Cortex-M0plus")
elseif(CPU STREQUAL "Cortex-M1")
  set(ARMASM_CPU "--cpu=Cortex-M1")
elseif(CPU STREQUAL "Cortex-M3")
  set(ARMASM_CPU "--cpu=Cortex-M3")
elseif(CPU STREQUAL "Cortex-M4")
  if(FPU STREQUAL "NO_FPU")
    set(ARMASM_CPU "--cpu=Cortex-M4.no_fp")
  else()
    set(ARMASM_CPU "--cpu=Cortex-M4")
  endif()
elseif(CPU STREQUAL "Cortex-M7")
  if(FPU STREQUAL "NO_FPU")
    set(ARMASM_CPU "--cpu=Cortex-M7.no_fp")
  elseif(FPU STREQUAL "SP_FPU")
    set(ARMASM_CPU "--cpu=Cortex-M7.fp.sp")
  else()
    set(ARMASM_CPU "--cpu=Cortex-M7")
  endif()
elseif(CPU STREQUAL "Cortex-M23")
  set(ARMASM_CPU "--cpu=Cortex-M23")
elseif(CPU STREQUAL "Cortex-M33")
  if(FPU STREQUAL "NO_FPU")
    if(DSP STREQUAL "NO_DSP")
      set(ARMASM_CPU "--cpu=Cortex-M33.no_dsp.no_fp")
    else()
      set(ARMASM_CPU "--cpu=Cortex-M33.no_fp")
    endif()
  else()
    if(DSP STREQUAL "NO_DSP")
      set(ARMASM_CPU "--cpu=Cortex-M33.no_dsp")
    else()
      set(ARMASM_CPU "--cpu=Cortex-M33")
    endif()
  endif()
elseif(CPU STREQUAL "Star-MC1")
  if(FPU STREQUAL "NO_FPU")
    if(DSP STREQUAL "NO_DSP")
      set(ARMASM_CPU "--cpu=Star-MC1.no_dsp.no_fp")
    else()
      set(ARMASM_CPU "--cpu=Star-MC1.no_fp")
    endif()
  else()
    if(DSP STREQUAL "NO_DSP")
      set(ARMASM_CPU "--cpu=Star-MC1.no_dsp")
    else()
      set(ARMASM_CPU "--cpu=Star-MC1")
    endif()
  endif()
elseif(CPU STREQUAL "Cortex-M35P")
  if(FPU STREQUAL "NO_FPU")
    if(DSP STREQUAL "NO_DSP")
      set(ARMASM_CPU "--cpu=Cortex-M35P.no_dsp.no_fp")
    else()
      set(ARMASM_CPU "--cpu=Cortex-M35P.no_fp")
    endif()
  else()
    if(DSP STREQUAL "NO_DSP")
      set(ARMASM_CPU "--cpu=Cortex-M35P.no_dsp")
    else()
      set(ARMASM_CPU "--cpu=Cortex-M35P")
    endif()
  endif()
elseif(CPU STREQUAL "Cortex-M52")
  set(ARMASM_CPU " ")
elseif(CPU STREQUAL "Cortex-M55")
  if(FPU STREQUAL "NO_FPU")
    if(MVE STREQUAL "NO_MVE")
      set(ARMASM_CPU "--cpu=Cortex-M55.no_mve.no_fp")
    else()
      set(ARMASM_CPU "--cpu=Cortex-M55.no_fp")
    endif()
  else()
    if(MVE STREQUAL "NO_MVE")
      set(ARMASM_CPU "--cpu=Cortex-M55.no_mve")
    elseif(MVE STREQUAL "MVE")
      set(ARMASM_CPU "--cpu=Cortex-M55.no_mvefp")
    else()
      set(ARMASM_CPU "--cpu=Cortex-M55")
    endif()
  endif()
elseif(CPU STREQUAL "Cortex-M85")
  if(FPU STREQUAL "NO_FPU")
    if(MVE STREQUAL "NO_MVE")
      set(ARMASM_CPU "--cpu=Cortex-M85.no_mve.no_fp")
    else()
      set(ARMASM_CPU "--cpu=Cortex-M85.no_fp")
    endif()
  else()
    if(MVE STREQUAL "NO_MVE")
      set(ARMASM_CPU "--cpu=Cortex-M85.no_mve")
    elseif(MVE STREQUAL "MVE")
      set(ARMASM_CPU "--cpu=Cortex-M85.no_mvefp")
    else()
      set(ARMASM_CPU "--cpu=Cortex-M85")
    endif()
  endif()
elseif(CPU STREQUAL "SC000")
  set(ARMASM_CPU "--cpu=SC000")
elseif(CPU STREQUAL "SC300")
  set(ARMASM_CPU "--cpu=SC300")
elseif(CPU STREQUAL "ARMV8MBL")
  set(ARMASM_CPU "--cpu=8-M.Base")
elseif(CPU STREQUAL "ARMV8MML")
  if(FPU STREQUAL "NO_FPU")
    if(DSP STREQUAL "NO_DSP")
      set(ARMASM_CPU "--cpu=8-M.Main --fpu=softvfp")
    else()
      set(ARMASM_CPU "--cpu=8-M.Main.dsp --fpu=softvfp")
    endif()
  elseif(FPU STREQUAL "SP_FPU")
    if(DSP STREQUAL "NO_DSP")
      set(ARMASM_CPU "--cpu=8-M.Main --fpu=fpv5-sp")
    else()
      set(ARMASM_CPU "--cpu=8-M.Main.dsp --fpu=fpv5-sp")
    endif()
  elseif(FPU STREQUAL "DP_FPU")
    if(DSP STREQUAL "NO_DSP")
      set(ARMASM_CPU "--cpu=8-M.Main --fpu=fpv5_d16")
    else()
      set(ARMASM_CPU "--cpu=8-M.Main.dsp --fpu=fpv5_d16")
    endif()
  endif()
elseif(CPU STREQUAL "ARMV81MML")
  if(FPU STREQUAL "NO_FPU")
    if(MVE STREQUAL "NO_MVE")
      if(DSP STREQUAL "NO_DSP")
        set(ARMASM_CPU "--cpu=8.1-M.Main --fpu=SoftVFP")
      else()
        set(ARMASM_CPU "--cpu=8.1-M.Main.dsp --fpu=SoftVFP")
      endif()
    elseif(MVE STREQUAL "MVE")
      set(ARMASM_CPU "--cpu=8.1-M.Main.mve --fpu=SoftVFP")
    endif()
  elseif(FPU STREQUAL "SP_FPU")
    if(MVE STREQUAL "NO_MVE")
      if(DSP STREQUAL "NO_DSP")
        set(ARMASM_CPU "--cpu=8.1-M.Main --fpu=FPv5-SP")
      else()
        set(ARMASM_CPU "--cpu=8.1-M.Main.dsp --fpu=FPv5-SP")
      endif()
    elseif(MVE STREQUAL "MVE")
      set(ARMASM_CPU "--cpu=8.1-M.Main.mve --fpu=FPv5-SP")
    else()
      set(ARMASM_CPU "--cpu=8.1-M.Main.mve.fp --fpu=FPv5-SP")
    endif()
  elseif(FPU STREQUAL "DP_FPU")
    if(MVE STREQUAL "NO_MVE")
      if(DSP STREQUAL "NO_DSP")
        set(ARMASM_CPU "--cpu=8.1-M.Main --fpu=FPv5_D16")
      else()
        set(ARMASM_CPU "--cpu=8.1-M.Main.dsp --fpu=FPv5_D16")
      endif()
    elseif(MVE STREQUAL "MVE")
      set(ARMASM_CPU "--cpu=8.1-M.Main.mve --fpu=FPv5_D16")
    else()
      set(ARMASM_CPU "--cpu=8.1-M.Main.mve.fp --fpu=FPv5_D16")
    endif()
  endif()
elseif(CPU STREQUAL "Cortex-A5")
  if(FPU STREQUAL "DP_FPU")
    set(ARMASM_CPU "--cpu=Cortex-A5.no_neon --fpu=VFPv3_D16_FP16")
  else()
    set(ARMASM_CPU "--cpu=Cortex-A5.no_neon.no_fp")
  endif()
elseif(CPU STREQUAL "Cortex-A7")
  if(FPU STREQUAL "DP_FPU")
    set(ARMASM_CPU "--cpu=Cortex-A7.no_neon --fpu=VFPv4_D16")
  else()
    set(ARMASM_CPU "--cpu=Cortex-A7.no_neon.no_fp")
  endif()
elseif(CPU STREQUAL "Cortex-A9")
  if(FPU STREQUAL "DP_FPU")
    set(ARMASM_CPU "--cpu=Cortex-A9.no_neon --fpu=VFPv3_D16_FP16")
  else()
    set(ARMASM_CPU "--cpu=Cortex-A9.no_neon.no_fp")
  endif()
elseif(CPU STREQUAL "Cortex-A35" OR CPU STREQUAL "Cortex-A53" OR CPU STREQUAL "Cortex-A55" OR CPU STREQUAL "Cortex-A57")
  if(FPU STREQUAL "DP_FPU")
    set(ARMASM_CPU "--cpu=8.1-A.64 --fpu=FP-ARMv8")
  else()
    set(ARMASM_CPU "--cpu=8.1-A.64.no_fp")
  endif()
elseif(CPU STREQUAL "Cortex-R4")
  if(FPU STREQUAL "DP_FPU")
    set(ARMASM_CPU "--cpu=Cortex-R4F --fpu=VFPv3_D16_FP16")
  else()
    set(ARMASM_CPU "--cpu=Cortex-R4.no_fp")
  endif()
elseif(CPU STREQUAL "Cortex-R5")
  if(FPU STREQUAL "DP_FPU")
    set(ARMASM_CPU "--cpu=Cortex-R5 --fpu=VFPv3_D16_FP16")
  else()
    set(ARMASM_CPU "--cpu=Cortex-R5.no_fp")
  endif()
elseif(CPU STREQUAL "Cortex-R7")
  if(FPU STREQUAL "DP_FPU")
    set(ARMASM_CPU "--cpu=Cortex-R7 --fpu=VFPv3_D16_FP16")
  else()
    set(ARMASM_CPU "--cpu=Cortex-R7.no_fp")
  endif()
elseif(CPU STREQUAL "Cortex-R8")
  if(FPU STREQUAL "DP_FPU")
    set(ARMASM_CPU "--cpu=Cortex-R8 --fpu=VFPv3_D16_FP16")
  else()
    set(ARMASM_CPU "--cpu=Cortex-R8.no_fp")
  endif()
endif()
if(NOT DEFINED ARMASM_CPU)
  message(FATAL_ERROR "Error: CPU is not supported!")
endif()

if(CPU STREQUAL "Cortex-M0")
  set(ARMCLANG_ARCH "armv6m")
  set(ARMCLANG_CPU "-mcpu=Cortex-M0 -mfpu=none")
elseif(CPU STREQUAL "Cortex-M0+")
  set(ARMCLANG_ARCH "armv6m")
  set(ARMCLANG_CPU "-mcpu=cortex-m0plus -mfpu=none")
elseif(CPU STREQUAL "Cortex-M1")
  set(ARMCLANG_ARCH "armv6m")
  set(ARMCLANG_CPU "-mcpu=Cortex-M1 -mfpu=none")
elseif(CPU STREQUAL "Cortex-M3")
  set(ARMCLANG_ARCH "armv7m")
  set(ARMCLANG_CPU "-mcpu=Cortex-M3 -mfpu=none")
elseif(CPU STREQUAL "Cortex-M4")
  set(ARMCLANG_ARCH "armv7em")
  if(FPU STREQUAL "SP_FPU")
    set(ARMCLANG_CPU "-mcpu=Cortex-M4 -mfpu=fpv4-sp-d16 -mfloat-abi=hard")
  else()
    set(ARMCLANG_CPU "-mcpu=Cortex-M4 -mfpu=none")
  endif()
elseif(CPU STREQUAL "Cortex-M7")
  set(ARMCLANG_ARCH "armv7em")
  if(FPU STREQUAL "DP_FPU")
    set(ARMCLANG_CPU "-mcpu=Cortex-M7 -mfpu=fpv5-d16 -mfloat-abi=hard")
  elseif(FPU STREQUAL "SP_FPU")
    set(ARMCLANG_CPU "-mcpu=Cortex-M7 -mfpu=fpv5-sp-d16 -mfloat-abi=hard")
  else()
    set(ARMCLANG_CPU "-mcpu=Cortex-M7 -mfpu=none")
  endif()
elseif(CPU STREQUAL "Cortex-M23")
  set(ARMCLANG_ARCH "armv8m.base")
  set(ARMCLANG_CPU "-mcpu=Cortex-M23 -mfpu=none")
elseif(CPU STREQUAL "Cortex-M33")
  set(ARMCLANG_ARCH "armv8m.main")
  if(FPU STREQUAL "SP_FPU")
    if(DSP STREQUAL "DSP")
      set(ARMCLANG_CPU "-mcpu=Cortex-M33 -mfpu=fpv5-sp-d16 -mfloat-abi=hard")
    else()
      set(ARMCLANG_CPU "-mcpu=Cortex-M33+nodsp -mfpu=fpv5-sp-d16 -mfloat-abi=hard")
    endif()
  else()
    if(DSP STREQUAL "DSP")
      set(ARMCLANG_CPU "-mcpu=Cortex-M33 -mfpu=none")
    else()
      set(ARMCLANG_CPU "-mcpu=Cortex-M33+nodsp -mfpu=none")
    endif()
  endif()
elseif(CPU STREQUAL "Star-M1")
  if(FPU STREQUAL "SP_FPU")
    if(DSP STREQUAL "DSP")
      set(ARMCLANG_CPU "-mcpu=Star-MC1 -mfpu=fpv5-sp-d16 -mfloat-abi=hard")
    else()
      set(ARMCLANG_CPU "-mcpu=Star-MC1+nodsp -mfpu=fpv5-sp-d16 -mfloat-abi=hard")
    endif()
  else()
    if(DSP STREQUAL "DSP")
      set(ARMCLANG_CPU "-mcpu=Star-MC1 -mfpu=none")
    else()
      set(ARMCLANG_CPU "-mcpu=Star-MC1+nodsp -mfpu=none")
    endif()
  endif()
elseif(CPU STREQUAL "Cortex-M35P")
  set(ARMCLANG_ARCH "armv8m.main")
  if(FPU STREQUAL "SP_FPU")
    if(DSP STREQUAL "DSP")
      set(ARMCLANG_CPU "-mcpu=Cortex-M35P -mfpu=fpv5-sp-d16 -mfloat-abi=hard")
    else()
      set(ARMCLANG_CPU "-mcpu=Cortex-M35P+nodsp -mfpu=fpv5-sp-d16 -mfloat-abi=hard")
    endif()
  else()
    if(DSP STREQUAL "DSP")
      set(ARMCLANG_CPU "-mcpu=Cortex-M35P -mfpu=none")
    else()
      set(ARMCLANG_CPU "-mcpu=Cortex-M35P+nodsp -mfpu=none")
    endif()
  endif()
elseif(CPU STREQUAL "Cortex-M52")
  set(ARMCLANG_ARCH "armv8.1m.main")
  if(MVE STREQUAL "NO_MVE")
    if(FPU STREQUAL "DP_FPU")
      set(ARMCLANG_CPU "-mcpu=Cortex-M52+nomve -mfloat-abi=hard")
    elseif(FPU STREQUAL "SP_FPU")
      set(ARMCLANG_CPU "-mcpu=Cortex-M52+nomve+nofp.dp -mfloat-abi=hard")
    else()
      message(FATAL_ERROR "Error: Cortex-M52+nomve+nofp is not supported!")
    endif()
  elseif(MVE STREQUAL "INT_MVE")
    if(FPU STREQUAL "SP_FPU")
      set(ARMCLANG_CPU "-mcpu=Cortex-M52+nomve.fp+nofp.dp -mfloat-abi=hard")
    elseif(FPU STREQUAL "DP_FPU")
      message(FATAL_ERROR "Error: Cortex-M52+nomve.fp is not supported!")
    else()
      set(ARMCLANG_CPU "-mcpu=Cortex-M52+nomve.fp+nofp")
    endif()
  else()
    if(FPU STREQUAL "DP_FPU")
      set(ARMCLANG_CPU "-mcpu=Cortex-M52 -mfloat-abi=hard")  
    elseif(FPU STREQUAL "SP_FPU")
      message(FATAL_ERROR "Error: Cortex-M52+nofp.dp is not supported!")
    else()
      message(FATAL_ERROR "Error: Cortex-M52+nofp is not supported!")
    endif()
  endif()
elseif(CPU STREQUAL "Cortex-M55")
  set(ARMCLANG_ARCH "armv8.1m.main")
  if(FPU STREQUAL "NO_FPU")
    if(MVE STREQUAL "NO_MVE")
      set(ARMCLANG_CPU "-mcpu=Cortex-M55+nofp+nomve")
    else()
      set(ARMCLANG_CPU "-mcpu=Cortex-M55+nofp")
    endif()
  else()
    if(MVE STREQUAL "NO_MVE")
      set(ARMCLANG_CPU "-mcpu=Cortex-M55+nomve -mfloat-abi=hard")
    elseif(MVE STREQUAL "MVE")
      set(ARMCLANG_CPU "-mcpu=Cortex-M55+nomve.fp -mfloat-abi=hard")
    else()
      set(ARMCLANG_CPU "-mcpu=Cortex-M55 -mfloat-abi=hard")
    endif()
  endif()
elseif(CPU STREQUAL "Cortex-M85")
  set(ARMCLANG_ARCH "armv8.1m.main")
  if(FPU STREQUAL "NO_FPU")
    if(MVE STREQUAL "NO_MVE")
      set(ARMCLANG_CPU "-mcpu=Cortex-M85+nofp+nomve")
    else()
      set(ARMCLANG_CPU "-mcpu=Cortex-M85+nofp")
    endif()
  else()
    if(MVE STREQUAL "NO_MVE")
      set(ARMCLANG_CPU "-mcpu=Cortex-M85+nomve -mfloat-abi=hard")
    elseif(MVE STREQUAL "MVE")
      set(ARMCLANG_CPU "-mcpu=Cortex-M85+nomve.fp -mfloat-abi=hard")
    else()
      set(ARMCLANG_CPU "-mcpu=Cortex-M85 -mfloat-abi=hard")
    endif()
  endif()
elseif(CPU STREQUAL "SC000")
  set(ARMCLANG_CPU "-mcpu=SC000 -mfpu=none")
elseif(CPU STREQUAL "SC300")
  set(ARMCLANG_CPU "-mcpu=SC300 -mfpu=none")
elseif(CPU STREQUAL "ARMV8MBL")
  set(ARMCLANG_CPU "-march=armv8-m.base")
elseif(CPU STREQUAL "ARMV8MML")
  if(FPU STREQUAL "NO_FPU")
    if(DSP STREQUAL "NO_DSP")
      set(ARMCLANG_CPU "-march=armv8-m.main -mfpu=none -mfloat-abi=soft")
    else()
      set(ARMCLANG_CPU "-march=armv8-m.main+dsp -mfpu=none -mfloat-abi=soft")
    endif()
  elseif(FPU STREQUAL "SP_FPU")
    if(DSP STREQUAL "NO_DSP")
      set(ARMCLANG_CPU "-march=armv8-m.main -mfpu=fpv5-sp-d16 -mfloat-abi=hard")
    else()
      set(ARMCLANG_CPU "-march=armv8-m.main+dsp -mfpu=fpv5-sp-d16 -mfloat-abi=hard")
    endif()
  elseif(FPU STREQUAL "DP_FPU")
    if(DSP STREQUAL "NO_DSP")
      set(ARMCLANG_CPU "-march=armv8-m.main -mfpu=fpv5-d16 -mfloat-abi=hard")
    else()
      set(ARMCLANG_CPU "-march=armv8-m.main+dsp -mfpu=fpv5-d16 -mfloat-abi=hard")
    endif()
  endif()
elseif(CPU STREQUAL "ARMV81MML")
  if(FPU STREQUAL "NO_FPU")
    if(DSP STREQUAL "NO_DSP")
      if(MVE STREQUAL "NO_MVE")
        set(ARMCLANG_CPU "-march=armv8.1-m.main+nofp -mfloat-abi=soft")
      elseif(MVE STREQUAL "MVE")
        set(ARMCLANG_CPU "-march=armv8.1-m.main+mve+nofp -mfloat-abi=soft")
      endif()
    else()
      if(MVE STREQUAL "NO_MVE")
        set(ARMCLANG_CPU "-march=armv8.1-m.main+dsp+nofp -mfloat-abi=soft")
      elseif(MVE STREQUAL "MVE")
        set(ARMCLANG_CPU "-march=armv8.1-m.main+dsp+mve+nofp -mfloat-abi=soft")
      endif()
    endif()
  elseif(FPU STREQUAL "SP_FPU")
    if(DSP STREQUAL "NO_DSP")
      if(MVE STREQUAL "NO_MVE")
        set(ARMCLANG_CPU "-march=armv8.1-m.main+fp -mfloat-abi=hard")
      elseif(MVE STREQUAL "MVE")
        set(ARMCLANG_CPU "-march=armv8.1-m.main+mve+fp -mfloat-abi=hard")
      else()
        set(ARMCLANG_CPU "-march=armv8.1-m.main+mve.fp+fp -mfloat-abi=hard")
      endif()
    else()
      if(MVE STREQUAL "NO_MVE")
        set(ARMCLANG_CPU "-march=armv8.1-m.main+dsp+fp -mfloat-abi=hard")
      elseif(MVE STREQUAL "MVE")
        set(ARMCLANG_CPU "-march=armv8.1-m.main+dsp+mve+fp -mfloat-abi=hard")
      else()
        set(ARMCLANG_CPU "-march=armv8.1-m.main+dsp+mve.fp+fp -mfloat-abi=hard")
      endif()
    endif()
  elseif(FPU STREQUAL "DP_FPU")
    if(DSP STREQUAL "NO_DSP")
      if(MVE STREQUAL "NO_MVE")
        set(ARMCLANG_CPU "-march=armv8.1-m.main+fp.dp -mfloat-abi=hard")
      elseif(MVE STREQUAL "MVE")
        set(ARMCLANG_CPU "-march=armv8.1-m.main+mve+fp.dp -mfloat-abi=hard")
      else()
        set(ARMCLANG_CPU "-march=armv8.1-m.main+mve.fp+fp.dp -mfloat-abi=hard")
      endif()
    else()
      if(MVE STREQUAL "NO_MVE")
        set(ARMCLANG_CPU "-march=armv8.1-m.main+dsp+fp.dp -mfloat-abi=hard")
      elseif(MVE STREQUAL "MVE")
        set(ARMCLANG_CPU "-march=armv8.1-m.main+dsp+mve+fp.dp -mfloat-abi=hard")
      else()
        set(ARMCLANG_CPU "-march=armv8.1-m.main+dsp+mve.fp+fp.dp -mfloat-abi=hard")
      endif()
    endif()
  endif()
elseif(CPU STREQUAL "Cortex-A5")
  set(ARMCLANG_ARCH "armv7")
  if(FPU STREQUAL "DP_FPU")
    set(ARMCLANG_CPU "-mcpu=Cortex-A5 -mfpu=vfpv3-d16-fp16 -mfloat-abi=hard")
  else()
    set(ARMCLANG_CPU "-mcpu=Cortex-A5 -mfpu=none")
  endif()
elseif(CPU STREQUAL "Cortex-A7")
  set(ARMCLANG_ARCH "armv7")
  if(FPU STREQUAL "DP_FPU")
    set(ARMCLANG_CPU "-mcpu=Cortex-A7 -mfpu=vfpv4-d16 -mfloat-abi=hard")
  else()
    set(ARMCLANG_CPU "-mcpu=Cortex-A7 -mfpu=none")
  endif()
elseif(CPU STREQUAL "Cortex-A9")
  set(ARMCLANG_ARCH "armv7")
  if(FPU STREQUAL "DP_FPU")
    set(ARMCLANG_CPU "-mcpu=Cortex-A9 -mfpu=vfpv3-d16-fp16 -mfloat-abi=hard")
  else()
    set(ARMCLANG_CPU "-mcpu=Cortex-A9 -mfpu=none")
  endif()
elseif(CPU STREQUAL "Cortex-A35")
  set(ARMCLANG_ARCH "armv8")
  set(ARMCLANG_CPU "-mcpu=Cortex-A35+nosimd")
elseif(CPU STREQUAL "Cortex-A53")
  set(ARMCLANG_ARCH "armv8")
  set(ARMCLANG_CPU "-mcpu=Cortex-A53+nosimd")
elseif(CPU STREQUAL "Cortex-A55")
  set(ARMCLANG_ARCH "armv8")
  set(ARMCLANG_CPU "-mcpu=Cortex-A55+nosimd")
elseif(CPU STREQUAL "Cortex-A57")
  set(ARMCLANG_ARCH "armv8")
  set(ARMCLANG_CPU "-mcpu=Cortex-A57+nosimd")
elseif(CPU STREQUAL "Cortex-R4")
  set(ARMCLANG_ARCH "armv7")
  if(FPU STREQUAL "DP_FPU")
    set(ARMCLANG_CPU "-mcpu=Cortex-R4f -mfpu=vfpv3-d16-fp16 -mfloat-abi=hard")
  else()
    set(ARMCLANG_CPU "-mcpu=Cortex-R4+nofp")
  endif()
elseif(CPU STREQUAL "Cortex-R5")
  set(ARMCLANG_ARCH "armv7")
  if(FPU STREQUAL "DP_FPU")
    set(ARMCLANG_CPU "-mcpu=Cortex-R5 -mfpu=vfpv3-d16-fp16 -mfloat-abi=hard")
  else()
    set(ARMCLANG_CPU "-mcpu=Cortex-R5+nofp")
  endif()
elseif(CPU STREQUAL "Cortex-R7")
  set(ARMCLANG_ARCH "armv7")
  if(FPU STREQUAL "DP_FPU")
    set(ARMCLANG_CPU "-mcpu=Cortex-R7 -mfpu=vfpv3-d16-fp16 -mfloat-abi=hard")
  else()
    set(ARMCLANG_CPU "-mcpu=Cortex-R7+nofp")
  endif()
elseif(CPU STREQUAL "Cortex-R8")
  set(ARMCLANG_ARCH "armv7")
  if(FPU STREQUAL "DP_FPU")
    set(ARMCLANG_CPU "-mcpu=Cortex-R8 -mfpu=vfpv3-d16-fp16 -mfloat-abi=hard")
  else()
    set(ARMCLANG_CPU "-mcpu=Cortex-R8+nofp")
  endif()
endif()
if(NOT DEFINED ARMCLANG_CPU)
  message(FATAL_ERROR "Error: CPU is not supported!")
endif()

# Supported Assembly Variants:
#   AS_LEG: armasm + Arm syntax
#   AS_ARM: armclang + Arm syntax
#   AS_GNU: armclang + GNU syntax
#   ASM: armclang + pre-processing

if(ARMCLANG_ARCH STREQUAL "armv8")
  set(ARMCLANG_TARGET "aarch64-arm-none-eabi")
else()
  set(ARMCLANG_TARGET "arm-arm-none-eabi")
endif()

set(CMAKE_CXX_COMPILER_TARGET "${ARMCLANG_TARGET}")
set(CMAKE_C_COMPILER_TARGET   "${ARMCLANG_TARGET}")

set(AS_LEG_CPU ${ARMASM_CPU})
set(AS_ARM_CPU ${ARMCLANG_CPU})
set(AS_GNU_CPU ${ARMCLANG_CPU})
set(ASM_CPU ${ARMCLANG_CPU})

set(AS_LEG_FLAGS "")
set(AS_ARM_FLAGS "--target=${ARMCLANG_TARGET} -c")
set(AS_GNU_FLAGS "--target=${ARMCLANG_TARGET} -c")
set(ASM_FLAGS    "--target=${ARMCLANG_TARGET} -c")

set(AS_LEG_OPTIONS_FLAGS)
cbuild_set_options_flags(AS_LEG "${OPTIMIZE}" "${DEBUG}" "${WARNINGS}" "" AS_LEG_OPTIONS_FLAGS)
set(AS_ARM_OPTIONS_FLAGS)
cbuild_set_options_flags(AS_ARM "${OPTIMIZE}" "${DEBUG}" "${WARNINGS}" "" AS_ARM_OPTIONS_FLAGS)
set(AS_GNU_OPTIONS_FLAGS)
cbuild_set_options_flags(AS_GNU "${OPTIMIZE}" "${DEBUG}" "${WARNINGS}" "" AS_GNU_OPTIONS_FLAGS)
set(ASM_OPTIONS_FLAGS)
cbuild_set_options_flags(ASM "${OPTIMIZE}" "${DEBUG}" "${WARNINGS}" "" ASM_OPTIONS_FLAGS)

set(AS_LEG_DEFINES ${DEFINES})
cbuild_set_defines(AS_LEG AS_LEG_DEFINES)
set(AS_ARM_DEFINES ${DEFINES})
cbuild_set_defines(AS_ARM AS_ARM_DEFINES)
set(AS_GNU_DEFINES ${DEFINES})
cbuild_set_defines(AS_GNU AS_GNU_DEFINES)
set(ASM_DEFINES ${DEFINES})
cbuild_set_defines(ASM ASM_DEFINES)

if(BYTE_ORDER STREQUAL "Little-endian")
  set(AS_LEG_BYTE_ORDER "--littleend")
  set(ASM_BYTE_ORDER "-mlittle-endian")
elseif(BYTE_ORDER STREQUAL "Big-endian")
  set(AS_LEG_BYTE_ORDER "--bigend")
  set(ASM_BYTE_ORDER "-mbig-endian")
endif()
set(AS_ARM_BYTE_ORDER "${AS_BYTE_ORDER}")
set(AS_GNU_BYTE_ORDER "${AS_BYTE_ORDER}")

# C Pre-Processor

if(SECURE STREQUAL "Secure" OR SECURE STREQUAL "Secure-only")
  set(CC_SECURE "-mcmse")
endif()

set(CPP_FLAGS "-E --target=${ARMCLANG_TARGET} ${ARMCLANG_CPU} -xc ${CC_SECURE}")
set(CPP_DEFINES ${LD_SCRIPT_PP_DEFINES})
cbuild_set_defines(CC CPP_DEFINES)
if(DEFINED LD_REGIONS AND NOT LD_REGIONS STREQUAL "")
  set(CPP_INCLUDES "-include \"${LD_REGIONS}\"")
endif()
set(CPP_ARGS_LD_SCRIPT "${CPP_FLAGS} ${CPP_DEFINES} ${CPP_INCLUDES} \"${LD_SCRIPT}\" -o \"${LD_SCRIPT_PP}\"")
separate_arguments(CPP_ARGS_LD_SCRIPT NATIVE_COMMAND ${CPP_ARGS_LD_SCRIPT})

# C Compiler

set(CC_CPU "--target=${ARMCLANG_TARGET} ${ARMCLANG_CPU}")
set(CC_DEFINES ${ASM_DEFINES})
set(CC_BYTE_ORDER ${ASM_BYTE_ORDER})
set(CC_FLAGS ${ASM_FLAGS})
set(_PI "-include ")
set(_ISYS "-isystem ")
set(CC_OPTIONS_FLAGS)
cbuild_set_options_flags(CC "${OPTIMIZE}" "${DEBUG}" "${WARNINGS}" "${LANGUAGE_CC}" CC_OPTIONS_FLAGS)

if(BRANCHPROT STREQUAL "NO_BRANCHPROT")
  set(CC_BRANCHPROT "-mbranch-protection=none")
elseif(BRANCHPROT STREQUAL "BTI")
  set(CC_BRANCHPROT "-mbranch-protection=bti")
elseif(BRANCHPROT STREQUAL "BTI_SIGNRET")
  set(CC_BRANCHPROT "-mbranch-protection=bti+pac-ret")
endif()

set(CC_SYS_INC_PATHS_LIST
  "\${TOOLCHAIN_ROOT}/../include"
)

# C++ Compiler

set(CXX_CPU "${CC_CPU}")
set(CXX_DEFINES "${CC_DEFINES}")
set(CXX_BYTE_ORDER "${CC_BYTE_ORDER}")
set(CXX_SECURE "${CC_SECURE}")
set(CXX_BRANCHPROT "${CC_BRANCHPROT}")
set(CXX_FLAGS "${CC_FLAGS}")
set(CXX_OPTIONS_FLAGS)
cbuild_set_options_flags(CXX "${OPTIMIZE}" "${DEBUG}" "${WARNINGS}" "${LANGUAGE_CXX}" CXX_OPTIONS_FLAGS)

set(CXX_SYS_INC_PATHS_LIST
  "\${TOOLCHAIN_ROOT}/../include/libcxx"
  "${CC_SYS_INC_PATHS_LIST}"
)

# Linker

set(LD_CPU ${ARMASM_CPU})
set(_LS "--scatter=")

if(SECURE STREQUAL "Secure")
  set(LD_SECURE "--import-cmse-lib-out \"${OUT_DIR}/${CMSE_LIB}\"")
endif()

set(LD_FLAGS "")
set(LD_OPTIONS_FLAGS)
cbuild_set_options_flags(LD "${OPTIMIZE}" "${DEBUG}" "${WARNINGS}" "" LD_OPTIONS_FLAGS)

# ELF to HEX conversion
set (ELF2HEX --i32combined --output "${OUT_DIR}/${HEX_FILE}" "${OUT_DIR}/$<TARGET_PROPERTY:${TARGET},OUTPUT_NAME>$<TARGET_PROPERTY:${TARGET},SUFFIX>")

# ELF to BIN conversion
set (ELF2BIN --bin --output "${OUT_DIR}/${BIN_FILE}" "${OUT_DIR}/$<TARGET_PROPERTY:${TARGET},OUTPUT_NAME>$<TARGET_PROPERTY:${TARGET},SUFFIX>")

# Set CMake variables for toolchain initialization
set(CMAKE_C_FLAGS_INIT "${CC_CPU}")
set(CMAKE_CXX_FLAGS_INIT "${CXX_CPU}")
set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_CROSSCOMPILING TRUE)
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)
set(CMAKE_ASM_COMPILER "${CC}")
set(CMAKE_AS_LEG_COMPILER "${AS}")
set(CMAKE_AS_ARM_COMPILER "${CC}")
set(CMAKE_AS_GNU_COMPILER "${CC}")
set(CMAKE_C_COMPILER "${CC}")
set(CMAKE_CXX_COMPILER "${CXX}")
set(CMAKE_LINKER "${LD}")
set(CMAKE_AR "${AR}")
set(CMAKE_OBJCOPY "${OC}")
set(CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/CMakeASM")

# Set CMake flags for compiler identification
set(CMAKE_C_FLAGS_INIT ${CC_CPU})
set(CMAKE_CXX_FLAGS_INIT ${CXX_CPU})
