/* debugging definitions */

#include <stdint.h>


/* in "boot.s" */

void kputs(char *s);
uint64_t ktime();


/* in "debug.c" */

void khex32(uint32_t x);
void khex64(uint64_t x);

