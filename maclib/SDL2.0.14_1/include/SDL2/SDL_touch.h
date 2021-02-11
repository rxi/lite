/*
  Simple DirectMedia Layer
  Copyright (C) 1997-2020 Sam Lantinga <slouken@libsdl.org>

  This software is provided 'as-is', without any express or implied
  warranty.  In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must not
     claim that you wrote the original software. If you use this software
     in a product, an acknowledgment in the product documentation would be
     appreciated but is not required.
  2. Altered source versions must be plainly marked as such, and must not be
     misrepresented as being the original software.
  3. This notice may not be removed or altered from any source distribution.
*/

/**
 *  \file SDL_touch.h
 *
 *  Include file for SDL touch event handling.
 */

#ifndef SDL_touch_h_
#define SDL_touch_h_

#include "SDL_stdinc.h"
#include "SDL_error.h"
#include "SDL_video.h"

#include "begin_code.h"
/* Set up for C function definitions, even when using C++ */
#ifdef __cplusplus
extern "C" {
#endif

typedef Sint64 SDL_TouchID;
typedef Sint64 SDL_FingerID;

typedef enum
{
    SDL_TOUCH_DEVICE_INVALID = -1,
    SDL_TOUCH_DEVICE_DIRECT,            /* touch screen with window-relative coordinates */
    SDL_TOUCH_DEVICE_INDIRECT_ABSOLUTE, /* trackpad with absolute device coordinates */
    SDL_TOUCH_DEVICE_INDIRECT_RELATIVE  /* trackpad with screen cursor-relative coordinates */
} SDL_TouchDeviceType;

typedef struct SDL_Finger
{
    SDL_FingerID id;
    float x;
    float y;
    float pressure;
} SDL_Finger;

/* Used as the device ID for mouse events simulated with touch input */
#define SDL_TOUCH_MOUSEID ((Uint32)-1)

/* Used as the SDL_TouchID for touch events simulated with mouse input */
#define SDL_MOUSE_TOUCHID ((Sint64)-1)


/* Function prototypes */

/**
 *  \brief Get the number of registered touch devices.
 */
extern DECLSPEC int SDLCALL SDL_GetNumTouchDevices(void);

/**
 *  \brief Get the touch ID with the given index, or 0 if the index is invalid.
 */
extern DECLSPEC SDL_TouchID SDLCALL SDL_GetTouchDevice(int index);

/**
 * \brief Get the type of the given touch device.
 */
extern DECLSPEC SDL_TouchDeviceType SDLCALL SDL_GetTouchDeviceType(SDL_TouchID touchID);

/**
 *  \brief Get the number of active fingers for a given touch device.
 */
extern DECLSPEC int SDLCALL SDL_GetNumTouchFingers(SDL_TouchID touchID);

/**
 *  \brief Get the finger object of the given touch, with the given index.
 */
extern DECLSPEC SDL_Finger * SDLCALL SDL_GetTouchFinger(SDL_TouchID touchID, int index);

/* Ends C function definitions when using C++ */
#ifdef __cplusplus
}
#endif
#include "close_code.h"

#endif /* SDL_touch_h_ */

/* vi: set ts=4 sw=4 expandtab: */
