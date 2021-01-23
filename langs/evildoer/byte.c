#include <stdio.h>
#include <inttypes.h>
#include "types.h"

int64_t read_byte(void) {
  char c = getc(stdin);
  return (c == EOF) ?
    val_eof :
    (int64_t)(c << int_shift);
}

int64_t peek_byte(void) {
  char c = getc(stdin);
  ungetc(c, stdin);
  return (c == EOF) ?
    val_eof :
    (int64_t)(c << int_shift);
}

int64_t write_byte(int64_t c) {
  int64_t codepoint = c >> int_shift;
  putc((char) codepoint, stdout);
  return 0;
}
