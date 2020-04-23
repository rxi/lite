#include <stdio.h>
#include <SDL2/SDL.h>
#include "api/api.h"
#include "renderer.h"

#ifdef _WIN32
  #include <windows.h>
#elif __linux__
  #include <unistd.h>
#elif __APPLE__
  #include <mach-o/dyld.h>
#endif


SDL_Window *window;


static double get_scale(void) {
  float dpi;
  SDL_GetDisplayDPI(0, NULL, &dpi, NULL);
#if _WIN32
  return dpi / 96.0;
#elif __APPLE__
  return dpi / 72.0;
#else
  return 1.0;
#endif
}


static void get_exe_dir(char *buf, int sz) {
#if _WIN32
  int len = GetModuleFileName(NULL, buf, sz - 1);
  buf[len] = '\0';
#elif __linux__
  char path[512];
  sprintf(path, "/proc/%d/exe", getpid());
  int len = readlink(path, buf, sz - 1);
  buf[len] = '\0';
#elif __APPLE__
  unsigned size = sz;
  _NSGetExecutablePath(buf, &size);
#else
  strcpy(buf, ".")
#endif

  for (int i = strlen(buf) - 1; i > 0; i--) {
    if (buf[i] == '/' || buf[i] == '\\') {
      buf[i] = '\0';
      break;
    }
  }
}



int main(int argc, char **argv) {
#ifdef _WIN32
  HINSTANCE lib = LoadLibrary("user32.dll");
  int (*SetProcessDPIAware)() = (void*) GetProcAddress(lib, "SetProcessDPIAware");
  SetProcessDPIAware();
#endif

  SDL_Init(SDL_INIT_VIDEO | SDL_INIT_EVENTS);
  SDL_EnableScreenSaver();
  SDL_EventState(SDL_DROPFILE, SDL_ENABLE);
  atexit(SDL_Quit);
#if SDL_VERSION_ATLEAST(2, 0, 5)
  SDL_SetHint(SDL_HINT_MOUSE_FOCUS_CLICKTHROUGH, "1");
#endif

  SDL_DisplayMode dm;
  SDL_GetCurrentDisplayMode(0, &dm);

  window = SDL_CreateWindow(
    "", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
    dm.w * 0.8, dm.h * 0.8, SDL_WINDOW_RESIZABLE | SDL_WINDOW_ALLOW_HIGHDPI);
  ren_init(window);


  lua_State *L = luaL_newstate();
  luaL_openlibs(L);
  api_load_libs(L);


  lua_newtable(L);
  for (int i = 0; i < argc; i++) {
    lua_pushstring(L, argv[i]);
    lua_rawseti(L, -2, i + 1);
  }
  lua_setglobal(L, "_ARGS");

  lua_pushstring(L, SDL_GetPlatform());
  lua_setglobal(L, "_PLATFORM");

  lua_pushnumber(L, get_scale());
  lua_setglobal(L, "_SCALE");

  char exedir[2048];
  get_exe_dir(exedir, sizeof(exedir));
  lua_pushstring(L, exedir);
  lua_setglobal(L, "_EXEDIR");


  (void) luaL_dostring(L,
    "local core\n"
    "xpcall(function()\n"
    "  _SCALE = tonumber(os.getenv(\"LITE_SCALE\")) or _SCALE\n"
    "  _PATHSEP = package.config:sub(1, 1)\n"
    "  package.path = _EXEDIR .. '/data/?.lua;' .. package.path\n"
    "  package.path = _EXEDIR .. '/data/?/init.lua;' .. package.path\n"
    "  core = require('core')\n"
    "  core.init()\n"
    "  core.run()\n"
    "end, function(err)\n"
    "  print('Error: ' .. tostring(err))\n"
    "  print(debug.traceback(nil, 2))\n"
    "  if core and core.on_error then\n"
    "    pcall(core.on_error, err)\n"
    "  end\n"
    "  os.exit(1)\n"
    "end)");


  lua_close(L);
  SDL_DestroyWindow(window);

  return EXIT_SUCCESS;
}
