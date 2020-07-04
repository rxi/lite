#include <SDL2/SDL.h>
#include <stdbool.h>
#include "api.h"
#ifdef _WIN32
  #include <windows.h>
#endif

extern SDL_Window *window;


static const char *window_opts[] = { "normal", "maximized", "fullscreen", 0 };
enum { WIN_NORMAL, WIN_MAXIMIZED, WIN_FULLSCREEN };

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

static int f_set_window_mode(lua_State *L) {
  int n = luaL_checkoption(L, 1, "normal", window_opts);
  SDL_SetWindowFullscreen(window,
    n == WIN_FULLSCREEN ? SDL_WINDOW_FULLSCREEN_DESKTOP : 0);
  if (n == WIN_NORMAL) { SDL_RestoreWindow(window); }
  if (n == WIN_MAXIMIZED) { SDL_MaximizeWindow(window); }
  return 0;
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


static int f_set_window_title(lua_State *L) {
  const char *title = luaL_checkstring(L, 1);
  SDL_SetWindowTitle(window, title);
  return 0;
}


static int f_show_confirm_dialog(lua_State *L) {
  const char *title = luaL_checkstring(L, 1);
  const char *msg = luaL_checkstring(L, 2);

#if _WIN32
  int id = MessageBox(0, msg, title, MB_YESNO | MB_ICONWARNING);
  lua_pushboolean(L, id == IDYES);

#else
  SDL_MessageBoxButtonData buttons[] = {
    { SDL_MESSAGEBOX_BUTTON_RETURNKEY_DEFAULT, 1, "Yes" },
    { SDL_MESSAGEBOX_BUTTON_ESCAPEKEY_DEFAULT, 0, "No" },
  };
  SDL_MessageBoxData data = {
    .title = title,
    .message = msg,
    .numbuttons = 2,
    .buttons = buttons,
  };
  int buttonid;
  SDL_ShowMessageBox(&data, &buttonid);
  lua_pushboolean(L, buttonid == 1);
#endif
  return 1;
}


static int f_window_has_focus(lua_State *L) {
  unsigned flags = SDL_GetWindowFlags(window);
  lua_pushboolean(L, flags & SDL_WINDOW_INPUT_FOCUS);
  return 1;
}


static const luaL_Reg lib[] = {
  { "get_mode",            f_get_window_mode     },
  { "get_position",        f_get_window_position },
  { "get_size",            f_get_window_size     },
  { "set_mode",            f_set_window_mode     },
  { "set_opacity",         f_set_window_opacity  },
  { "set_position",        f_set_window_position },
  { "set_size",            f_set_window_size     },
  { "set_title",           f_set_window_title    },
  { "show_confirm_dialog", f_show_confirm_dialog },
  { "has_focus",           f_window_has_focus    },
  { NULL, NULL }
};


int luaopen_window(lua_State *L) {
  luaL_newlib(L, lib);
  return 1;
}

