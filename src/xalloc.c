#include <stdio.h>
#include "xalloc.h"


static void panic(void) {
  fprintf(stderr, "Fatal error: out of memory\n");
  exit(1);
}


void* xmalloc(size_t size) {
  void *ptr = malloc(size);
  if (!ptr) {
    panic();
  }
  return ptr;
}


void xfree(void *ptr) {
  free(ptr);
}


void* xcalloc(size_t nmemb, size_t size) {
  void *ptr = calloc(nmemb, size);
  if (!ptr) {
    panic();
  }
  return ptr;
}


void* xrealloc(void *ptr, size_t size) {
  ptr = realloc(ptr, size);
  if (!ptr) {
    panic();
  }
  return ptr;
}
