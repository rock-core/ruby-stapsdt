#include "usdt.h"

VALUE rb_mUsdt;

void
Init_usdt(void)
{
  rb_mUsdt = rb_define_module("Usdt");
}
