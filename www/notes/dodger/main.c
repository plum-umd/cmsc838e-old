#include <stdio.h>
#include <inttypes.h>
#include "types.h"

int64_t entry();
void print_result(int64_t);
void print_char(int64_t);

int main(int argc, char** argv) {
  print_result(entry());
  return 0;
}

void print_result(int64_t result) {
  if (int_type_tag == (int_type_mask & result)) {
    printf("%" PRId64, result >> int_shift);
  } else if (char_type_tag == (char_type_mask & result)) {
    print_char(result);
  } else {
    switch (result) {
    case val_true:
      printf("#t");
      break;
    case val_false:
      printf("#f");
      break;
    }   
  }  
}