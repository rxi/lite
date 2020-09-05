#include <stdio.h>
#include <stdbool.h>
#include <assert.h>
#include <math.h>
#include "lib/stb/stb_truetype.h"
#include "renderer.h"

#define MAX_GLYPHSET 256

struct RenImage {
  RenColor *pixels;
  int width, height;
};

typedef struct {
  RenImage *image;
  stbtt_bakedchar glyphs[256];
} GlyphSet;

struct RenFont {
  void *data;
  stbtt_fontinfo stbfont;
  GlyphSet *sets[MAX_GLYPHSET];
  float size;
  int height;
};


static SDL_Window *window;
static struct { int left, top, right, bottom; } clip;


static void* check_alloc(void *ptr) {
  if (!ptr) {
    fprintf(stderr, "Fatal error: memory allocation failed\n");
    exit(EXIT_FAILURE);
  }
  return ptr;
}


static const char* utf8_to_codepoint(const char *p, unsigned *dst) {
  unsigned res, n;
  switch (*p & 0xf0) {
    case 0xf0 :  res = *p & 0x07;  n = 3;  break;
    case 0xe0 :  res = *p & 0x0f;  n = 2;  break;
    case 0xd0 :
    case 0xc0 :  res = *p & 0x1f;  n = 1;  break;
    default   :  res = *p;         n = 0;  break;
  }
  while (n--) {
    res = (res << 6) | (*(++p) & 0x3f);
  }
  *dst = res;
  return p + 1;
}


void ren_init(SDL_Window *win) {
  assert(win);
  window = win;
  SDL_Surface *surf = SDL_GetWindowSurface(window);
  ren_set_clip_rect( (RenRect) { 0, 0, surf->w, surf->h } );
}


void ren_update_rects(RenRect *rects, int count) {
  SDL_UpdateWindowSurfaceRects(window, (SDL_Rect*) rects, count);
  static bool initial_frame = true;
  if (initial_frame) {
    SDL_ShowWindow(window);
    initial_frame = false;
  }
}


void ren_set_clip_rect(RenRect rect) {
  clip.left   = rect.x;
  clip.top    = rect.y;
  clip.right  = rect.x + rect.width;
  clip.bottom = rect.y + rect.height;
}


void ren_get_size(int *x, int *y) {
  SDL_Surface *surf = SDL_GetWindowSurface(window);
  *x = surf->w;
  *y = surf->h;
}


RenImage* ren_new_image(int width, int height) {
  assert(width > 0 && height > 0);
  RenImage *image = malloc(sizeof(RenImage) + width * height * sizeof(RenColor));
  check_alloc(image);
  image->pixels = (void*) (image + 1);
  image->width = width;
  image->height = height;
  return image;
}


void ren_free_image(RenImage *image) {
  free(image);
}


static GlyphSet* load_glyphset(RenFont *font, int idx) {
  GlyphSet *set = check_alloc(calloc(1, sizeof(GlyphSet)));

  /* init image */
  int width = 128;
  int height = 128;
retry:
  set->image = ren_new_image(width, height);

  /* load glyphs */
  float s =
    stbtt_ScaleForMappingEmToPixels(&font->stbfont, 1) /
    stbtt_ScaleForPixelHeight(&font->stbfont, 1);
  int res = stbtt_BakeFontBitmap(
    font->data, 0, font->size * s, (void*) set->image->pixels,
    width, height, idx * 256, 256, set->glyphs);

  /* retry with a larger image buffer if the buffer wasn't large enough */
  if (res < 0) {
    width *= 2;
    height *= 2;
    ren_free_image(set->image);
    goto retry;
  }

  /* adjust glyph yoffsets and xadvance */
  int ascent, descent, linegap;
  stbtt_GetFontVMetrics(&font->stbfont, &ascent, &descent, &linegap);
  float scale = stbtt_ScaleForMappingEmToPixels(&font->stbfont, font->size);
  int scaled_ascent = ascent * scale + 0.5;
  for (int i = 0; i < 256; i++) {
    set->glyphs[i].yoff += scaled_ascent;
    set->glyphs[i].xadvance = floor(set->glyphs[i].xadvance);
  }

  /* convert 8bit data to 32bit */
  for (int i = width * height - 1; i >= 0; i--) {
    uint8_t n = *((uint8_t*) set->image->pixels + i);
    set->image->pixels[i] = (RenColor) { .r = 255, .g = 255, .b = 255, .a = n };
  }

  return set;
}


static GlyphSet* get_glyphset(RenFont *font, int codepoint) {
  int idx = (codepoint >> 8) % MAX_GLYPHSET;
  if (!font->sets[idx]) {
    font->sets[idx] = load_glyphset(font, idx);
  }
  return font->sets[idx];
}


RenFont* ren_load_font(const char *filename, float size) {
  RenFont *font = NULL;
  FILE *fp = NULL;

  /* init font */
  font = check_alloc(calloc(1, sizeof(RenFont)));
  font->size = size;

  /* load font into buffer */
  fp = fopen(filename, "rb");
  if (!fp) { return NULL; }
  /* get size */
  fseek(fp, 0, SEEK_END); int buf_size = ftell(fp); fseek(fp, 0, SEEK_SET);
  /* load */
  font->data = check_alloc(malloc(buf_size));
  int _ = fread(font->data, 1, buf_size, fp); (void) _;
  fclose(fp);
  fp = NULL;

  /* init stbfont */
  int ok = stbtt_InitFont(&font->stbfont, font->data, 0);
  if (!ok) { goto fail; }

  /* get height and scale */
  int ascent, descent, linegap;
  stbtt_GetFontVMetrics(&font->stbfont, &ascent, &descent, &linegap);
  float scale = stbtt_ScaleForMappingEmToPixels(&font->stbfont, size);
  font->height = (ascent - descent + linegap) * scale + 0.5;

  /* make tab and newline glyphs invisible */
  stbtt_bakedchar *g = get_glyphset(font, '\n')->glyphs;
  g['\t'].x1 = g['\t'].x0;
  g['\n'].x1 = g['\n'].x0;

  return font;

fail:
  if (fp) { fclose(fp); }
  if (font) { free(font->data); }
  free(font);
  return NULL;
}


void ren_free_font(RenFont *font) {
  for (int i = 0; i < MAX_GLYPHSET; i++) {
    GlyphSet *set = font->sets[i];
    if (set) {
      ren_free_image(set->image);
      free(set);
    }
  }
  free(font->data);
  free(font);
}


void ren_set_font_tab_width(RenFont *font, int n) {
  GlyphSet *set = get_glyphset(font, '\t');
  set->glyphs['\t'].xadvance = n;
}


int ren_get_font_tab_width(RenFont *font) {
  GlyphSet *set = get_glyphset(font, '\t');
  return set->glyphs['\t'].xadvance;
}


int ren_get_font_width(RenFont *font, const char *text) {
  int x = 0;
  const char *p = text;
  unsigned codepoint;
  while (*p) {
    p = utf8_to_codepoint(p, &codepoint);
    GlyphSet *set = get_glyphset(font, codepoint);
    stbtt_bakedchar *g = &set->glyphs[codepoint & 0xff];
    x += g->xadvance;
  }
  return x;
}


int ren_get_font_height(RenFont *font) {
  return font->height;
}


static inline RenColor blend_pixel(RenColor dst, RenColor src) {
  int ia = 0xff - src.a;
  dst.r = ((src.r * src.a) + (dst.r * ia)) >> 8;
  dst.g = ((src.g * src.a) + (dst.g * ia)) >> 8;
  dst.b = ((src.b * src.a) + (dst.b * ia)) >> 8;
  return dst;
}


static inline RenColor blend_pixel2(RenColor dst, RenColor src, RenColor color) {
  src.a = (src.a * color.a) >> 8;
  int ia = 0xff - src.a;
  dst.r = ((src.r * color.r * src.a) >> 16) + ((dst.r * ia) >> 8);
  dst.g = ((src.g * color.g * src.a) >> 16) + ((dst.g * ia) >> 8);
  dst.b = ((src.b * color.b * src.a) >> 16) + ((dst.b * ia) >> 8);
  return dst;
}


#define rect_draw_loop(expr)        \
  for (int j = y1; j < y2; j++) {   \
    for (int i = x1; i < x2; i++) { \
      *d = expr;                    \
      d++;                          \
    }                               \
    d += dr;                        \
  }

void ren_draw_rect(RenRect rect, RenColor color) {
  if (color.a == 0) { return; }

  int x1 = rect.x < clip.left ? clip.left : rect.x;
  int y1 = rect.y < clip.top  ? clip.top  : rect.y;
  int x2 = rect.x + rect.width;
  int y2 = rect.y + rect.height;
  x2 = x2 > clip.right  ? clip.right  : x2;
  y2 = y2 > clip.bottom ? clip.bottom : y2;

  SDL_Surface *surf = SDL_GetWindowSurface(window);
  RenColor *d = (RenColor*) surf->pixels;
  d += x1 + y1 * surf->w;
  int dr = surf->w - (x2 - x1);

  if (color.a == 0xff) {
    rect_draw_loop(color);
  } else {
    rect_draw_loop(blend_pixel(*d, color));
  }
}


void ren_draw_image(RenImage *image, RenRect *sub, int x, int y, RenColor color) {
  if (color.a == 0) { return; }

  /* clip */
  int n;
  if ((n = clip.left - x) > 0) { sub->width  -= n; sub->x += n; x += n; }
  if ((n = clip.top  - y) > 0) { sub->height -= n; sub->y += n; y += n; }
  if ((n = x + sub->width  - clip.right ) > 0) { sub->width  -= n; }
  if ((n = y + sub->height - clip.bottom) > 0) { sub->height -= n; }

  if (sub->width <= 0 || sub->height <= 0) {
    return;
  }

  /* draw */
  SDL_Surface *surf = SDL_GetWindowSurface(window);
  RenColor *s = image->pixels;
  RenColor *d = (RenColor*) surf->pixels;
  s += sub->x + sub->y * image->width;
  d += x + y * surf->w;
  int sr = image->width - sub->width;
  int dr = surf->w - sub->width;

  for (int j = 0; j < sub->height; j++) {
    for (int i = 0; i < sub->width; i++) {
      *d = blend_pixel2(*d, *s, color);
      d++;
      s++;
    }
    d += dr;
    s += sr;
  }
}


int ren_draw_text(RenFont *font, const char *text, int x, int y, RenColor color) {
  RenRect rect;
  const char *p = text;
  unsigned codepoint;
  while (*p) {
    p = utf8_to_codepoint(p, &codepoint);
    GlyphSet *set = get_glyphset(font, codepoint);
    stbtt_bakedchar *g = &set->glyphs[codepoint & 0xff];
    rect.x = g->x0;
    rect.y = g->y0;
    rect.width = g->x1 - g->x0;
    rect.height = g->y1 - g->y0;
    ren_draw_image(set->image, &rect, x + g->xoff, y + g->yoff, color);
    x += g->xadvance;
  }
  return x;
}
