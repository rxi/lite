#ifndef XALLOC_H
#define XALLOC_H

#include <stdlib.h>

void* xmalloc(size_t size);
void  xfree(void *ptr);
void* xcalloc(size_t nmemb, size_t size);
void* xrealloc(void *ptr, size_t size);

#endif
