#include <SDL2/SDL.h>
#include <stdbool.h>
#include "api.h"
#ifdef _WIN32
  #include <windows.h>
#endif

extern SDL_Window *window;


static const char *window_opts[] = { "normal", "maximized", "fullscreen", 0 };

static int f_get_window_mode(lua_State *L) {
  unsigned flags = SDL_GetWindowFlags(window);
  bool isFullscreen = flags & SDL_WINDOW_FULLSCREEN_DESKTOP;
  bool isMaximized = flags & SDL_WINDOW_MAXIMIZED;
  int index = 0;
  if (isFullscreen) {
    index = 2;
  } else if (isMaximized) {
    index = 1;
  }
  lua_pushstring(L, window_opts[index]);
  return 1;
}


static int f_get_window_position(lua_State *L) {
  int x, y;
  SDL_GetWindowPosition(window, &x, &y);
  lua_pushnumber(L, x);
  lua_pushnumber(L, y);
  return 2;
}


static int f_get_window_size(lua_State *L) {
  int w = 0;
  int h = 0;
  SDL_GetWindowSize(window, &w, &h);
  lua_pushnumber(L, w);
  lua_pushnumber(L, h);
  return 2;
}

// does not seem to work on Fedora Gnome Wayland
// it returns true but visually nothing changes
// possibly bc the view paints solid?
static int f_set_window_opacity(lua_State *L) {
  double n = luaL_checknumber(L, 1);
  int r = SDL_SetWindowOpacity(window, n);
  lua_pushboolean(L, r > -1);
  return 1;
}


static int f_set_window_position(lua_State *L) {
  int x = luaL_checknumber(L, 1);
  int y = luaL_checknumber(L, 1);
  SDL_SetWindowPosition(window, x, y);
  return 0;
}


static int f_set_window_size(lua_State *L) {
  int w = luaL_checknumber(L, 1);
  int h = luaL_checknumber(L, 1);
  if ((0 >= w) || (0 >= h)) {
    lua_pushboolean(L, false);
    lua_pushstring(L, "Width and height must be bigger than 0");
    return 2;
  }
  SDL_SetWindowSize(window, w, h);
  lua_pushboolean(L, true);
  lua_pushnil(L);
  return 2;
}


static const luaL_Reg lib[] = {
  { "get_mode",          f_get_window_mode     },
  { "get_position",      f_get_window_position },
  { "get_size",          f_get_window_size     },
  { "set_opacity",       f_set_window_opacity  },
  { "set_position",      f_set_window_position },
  { "set_size",          f_set_window_size     },
  { NULL, NULL }
};


int luaopen_window(lua_State *L) {
  luaL_newlib(L, lib);
  return 1;
}

