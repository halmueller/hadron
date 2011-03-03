/*
 *  SharedPrefix.h
 *  WBConfig
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright © 2004 - 2011 Jean-Daniel Dupas. All rights reserved.
 */
/*!
@header SharedPrefix
 @abstract Visibility macros + basics functions
*/

#if !defined(__WBC_WIN32_CORE_H__)
#define __WBC_WIN32_CORE_H__ 1

#if defined(__cplusplus) && !defined(__STDC_LIMIT_MACROS)
  #define __STDC_LIMIT_MACROS
#endif

#ifdef _MSC_VER
  #if !defined(__cplusplus)
    // C support in MSVC is badly broken
    #error Broken C Compiler. Use C++ if you want to use it.
  #endif
  // Symbols visibilities
  #pragma warning(disable:4251)
#endif

#define NOMINMAX // avoid declaration of min() max() macros which conflicts with c++ functions
#define WIN32_LEAN_AND_MEAN  // Exclude rarely-used stuff from Windows headers

// Important: We expect 64 bit off_t, so we have to define it ourself
typedef long _off_t; // expected and used by Windows (so we declare it compatible with the Win32 API)
typedef __int64 off_t;
#define _OFF_T_DEFINED // prevent redefinition

#include "stdint.h" // Must be before windows.h

// MARK: System Include
// If you wish to build your application for a previous Windows platform,
// set the _WIN32_WINNT macro to the platform you wish to support before including SDKDDKVer.h.
#include <SDKDDKVer.h>

#include "AssertMacros.h"
#include "AvailabilityMacros.h"

#include <windows.h>

#include <CoreFoundation\CoreFoundation.h> // defines endian macros

// Missing types
#include "libc.h"
#include "stdbool.h"
#include "macerrors.h"

#include "OSAtomic.h"
#include "OSByteOrder.h"

#define SC_HIDDEN

#if defined(SC_SYMBOLS_EXPORTS)
  #define SC_VISIBLE __declspec(dllexport)
#else
  #define SC_VISIBLE __declspec(dllimport)
#endif

#endif /* __WBC_WIN32_CORE_H__ */