#include <stdio.h>
#include <stdint.h>
#include <emmintrin.h>
#include <tmmintrin.h>
#include <x86intrin.h>
#include "r43_8.h"
#include "compat.h"

#define M128(x) m128_2(x)
#define SB(x) para_sb(x)

void print128(__m128i x)
{
  for (int i = 7; i >= 0; i--)
  {
    printf("%04x", _mm_extract_epi16(x, i));
  }
  printf("\n");

  return;
}

/*
 * Simulates an implementation of a
 * Littlun-like cipher many times, for speed
 * evaluation
 */
__m128i dummy_cipher_eval()
{
  __m128i x, k;
  unsigned long long tick1, tick2, dum;

  x = _mm_set_epi64x(0x0001020304050607, 0x08090a0b0c0d0e0f);
  k = _mm_set_epi64x(0x0a030d0c0f050607, 0x08090a000c0d0e0f);

  dum = 0;

  for (tick1 = 0; tick1 < 1ull << 31; tick1++)
    dum += 2*tick1 & (~tick1 | (tick1 >> 2));
  
  x = SB(x);
  x = M128(x);
  x = SB(x);
  x = M128(x);
  x = SB(x);
  x = M128(x);
  x = SB(x);
  x = M128(x);
  x = SB(x);
  x = M128(x);
  x = SB(x);
  x = M128(x);
  x = SB(x);
  x = M128(x);
  x = SB(x);
  x = M128(x);
  x = SB(x);
  x = M128(x);
  x = SB(x);
  x = M128(x);
  x = SB(x);
  x = M128(x);
  x = SB(x);
  x = M128(x);
  x = SB(x);
  x = M128(x);
  x = SB(x);
  x = M128(x);
  x = SB(x);
  x = M128(x);
  x = SB(x);
  x = M128(x);

  tick1 = rdtsc();

//  // r1
//  x = _mm_xor_si128(x,k);
//  x = SB(x);
//  x = M128(x);
//  // r2
//  x = _mm_xor_si128(x,k);
//  x = SB(x);
//  x = M128(x);
//  // r3
//  x = _mm_xor_si128(x,k);
//  x = SB(x);
//  x = M128(x);
//  // r4
//  x = _mm_xor_si128(x,k);
//  x = SB(x);
//  x = M128(x);
//  // r5
//  x = _mm_xor_si128(x,k);
//  x = SB(x);
//  x = M128(x);
//  // r6
//  x = _mm_xor_si128(x,k);
//  x = SB(x);
//  x = M128(x);
//  // r7
//  x = _mm_xor_si128(x,k);
//  x = SB(x);
//  x = M128(x);
//  // r8
//  x = _mm_xor_si128(x,k);
//  x = SB(x);
//  x = M128(x);
//  // final
//  x = _mm_xor_si128(x,k);

  tick2 = rdtsc();

  printf("%llu ~ %llu cycles\n\n", dum, tick2 - tick1); 

  return x;
}

__m128i mul_check(void)
{
  __m128i x;

  //x = _mm_set_epi64x(0x0f0e0d0c0b0a0908, 0x0706050403020100);
  x = _mm_set_epi64x(0x0000000000000000, 0x00000000000000f0);
  //x = _mm_set_epi64x(0x0f0e0d030b0a0908, 0x0706050403020100);
  x = M128(x);

  return x;
}

__m128i para_test(void)
{
  __m128i x;

  x = _mm_set_epi64x  (0x0102030405060708, 0x090a0b0c0d0e0f1f);
  x = SB(x);

  return x;
}

int main()
{

  //print128(dummy_cipher_eval());
  print128(mul_check());
  //print128(para_test());

  return 0;
}
