#ifndef API_H
#define API_H

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

#define API_TYPE_FONT "Font"

void api_load_libs(lua_State *L);

#endif
