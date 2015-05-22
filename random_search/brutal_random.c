/*
 * PK, 2014
 */

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <SFMT.h>

#include <m4rie/gf2e.h>
#include <m4rie/echelonform.h>

// #define MAX(x,y) ((x) > (y) ? (x) : (y))

/* `word' is unsigned long long here */

typedef word(*base_fun)(gf2e *, word, word);

void fy_shuffle(sfmt_t *sfmt, int size, const unsigned base[], unsigned shuffd[])
{
  int i;
  unsigned ri, t;

  for (i = 0; i < size; i++)
    shuffd[i] = base[i];

  for (i = size - 1; i > 0; i--)
  {
    ri = sfmt_genrand_uint32(sfmt) % (i + 1); // most of the output is thrown out most of the time...
    t           = shuffd[ri];
    shuffd[ri]  = shuffd[i];
    shuffd[i]   = t;
  }
}

/*
 * Base functions for L(17Q)
 */
/* 1 */
word lb0(gf2e *ff, word x, word y)
{
  return 1;
}

/* x */
word lb1(gf2e *ff, word x, word y)
{
  return x;
}

/* x^2 */
word lb2(gf2e *ff, word x, word y)
{
  return gf2e_mul(ff, x, x);
}

/* x^3 */
word lb3(gf2e *ff, word x, word y)
{
  word t0 = gf2e_mul(ff, x, x); // 2

  return gf2e_mul(ff, x, t0); // 3
}

/* x^4 */
word lb4(gf2e *ff, word x, word y)
{
  word t0 = gf2e_mul(ff, x, x); // 2

  return gf2e_mul(ff, t0, t0); // 4
}

/* x^5 */
word lb5(gf2e *ff, word x, word y)
{
  word t0 = gf2e_mul(ff, x, x); // 2
  word t1 = gf2e_mul(ff, t0, t0); // 4

  return gf2e_mul(ff, x, t1); // 5
}

/* x^6 */
word lb6(gf2e *ff, word x, word y)
{
  word t0 = gf2e_mul(ff, x, x); // 2
  word t1 = gf2e_mul(ff, t0, t0); //4

  return gf2e_mul(ff, t0, t1); // 6
}

/* x^7 */
word lb7(gf2e *ff, word x, word y)
{
  word t0 = gf2e_mul(ff, x, x); // 2
  word t1 = gf2e_mul(ff, t0, t0); // 4
  word t2 = gf2e_mul(ff, t0, t1); // 6

  return gf2e_mul(ff, x, t2); // 7
}

/* x^8 */
word lb8(gf2e *ff, word x, word y)
{
  word t0 = gf2e_mul(ff, x, x); // 2
  word t1 = gf2e_mul(ff, t0, t0); // 4

  return gf2e_mul(ff, t1, t1); // 8
}

/* y */
word lb9(gf2e *ff, word x, word y)
{
  return y;
}

/* x*y */
word lb10(gf2e *ff, word x, word y)
{
  return gf2e_mul(ff,x ,y);
}

/* x^2*y */
word lb11(gf2e *ff, word x, word y)
{
  word t0 = gf2e_mul(ff, x, x); // 2

  return gf2e_mul(ff, y, t0);
}

/* x^3*y */
word lb12(gf2e *ff, word x, word y)
{
  word t0 = gf2e_mul(ff, x, x); // 2
  word t1 = gf2e_mul(ff, x, t0); // 3

  return gf2e_mul(ff, y, t1);
}

/* x^4*y */
word lb13(gf2e *ff, word x, word y)
{
  word t0 = gf2e_mul(ff, x, x); // 2
  word t1 = gf2e_mul(ff, t0, t0); // 4

  return gf2e_mul(ff, y, t1);
}

/* x^5*y */
word lb14(gf2e *ff, word x, word y)
{
  word t0 = gf2e_mul(ff, x, x); // 2
  word t1 = gf2e_mul(ff, t0, t0); //4
  word t2 = gf2e_mul(ff, x, t1); //5

  return gf2e_mul(ff, y, t2);
}

/* x^6*y */
word lb15(gf2e *ff, word x, word y)
{
  word t0 = gf2e_mul(ff, x, x); // 2
  word t1 = gf2e_mul(ff, t0, t0); // 4
  word t2 = gf2e_mul(ff, t0, t1); // 6

  return gf2e_mul(ff, y, t2);
}

void init_base(base_fun base[16])
{
  base[ 0] = &lb0;
  base[ 1] = &lb1;
  base[ 2] = &lb2;
  base[ 3] = &lb3;
  base[ 4] = &lb4;
  base[ 5] = &lb5;
  base[ 6] = &lb6;
  base[ 7] = &lb7;
  base[ 8] = &lb8;
  base[ 9] = &lb9;
  base[10] = &lb10;
  base[11] = &lb11;
  base[12] = &lb12;
  base[13] = &lb13;
  base[14] = &lb14;
  base[15] = &lb15;

  return;
}

/*
 * End of base functions for L(17Q)
 */

/*
 * Points init
 */

typedef struct point
{
  word x;
  word y;
} point_t;

void init_points(point_t points[32])
{
  points[ 0].x = 0;
  points[ 0].y = 0;

  points[ 1].x = 0;
  points[ 1].y = 1;

  points[ 2].x = 1;
  points[ 2].y = 6;

  points[ 3].x = 1;
  points[ 3].y = 7;

  points[ 4].x = 2;
  points[ 4].y = 2;

  points[ 5].x = 2;
  points[ 5].y = 3;

  points[ 6].x = 3;
  points[ 6].y = 2;

  points[ 7].x = 3;
  points[ 7].y = 3;

  points[ 8].x = 4;
  points[ 8].y = 4;

  points[ 9].x = 4;
  points[ 9].y = 5;

  points[10].x = 5;
  points[10].y = 4;

  points[11].x = 5;
  points[11].y = 5;

  points[12].x = 6;
  points[12].y = 4;

  points[13].x = 6;
  points[13].y = 5;

  points[14].x = 7;
  points[14].y = 2;

  points[15].x = 7;
  points[15].y = 3;

  points[16].x = 8;
  points[16].y = 6;

  points[17].x = 8;
  points[17].y = 7;

  points[18].x = 9;
  points[18].y = 4;

  points[19].x = 9;
  points[19].y = 5;

  points[20].x = 10;
  points[20].y = 6;

  points[21].x = 10;
  points[21].y = 7;

  points[22].x = 11;
  points[22].y = 2;

  points[23].x = 11;
  points[23].y = 3;

  points[24].x = 12;
  points[24].y = 6;

  points[25].x = 12;
  points[25].y = 7;

  points[26].x = 13;
  points[26].y = 2;

  points[27].x = 13;
  points[27].y = 3;

  points[28].x = 14;
  points[28].y = 4;

  points[29].x = 14;
  points[29].y = 5;

  points[30].x = 15;
  points[30].y = 6;

  points[31].x = 15;
  points[31].y = 7;

  return;
}

/*
 * Set an initialized matrix with the evaluation of the base functions on the points
 * with order defined by perm
 */
void set_matrix(mzed_t *m1, gf2e *f16, base_fun base[16], point_t points[32], unsigned perm[32])
{
  int i, j;

  for (i = 0; i < 16; i++)
  {
    for (j = 0; j < 32; j++)
    {
      mzed_write_elem(m1, i, j, base[i](f16, points[perm[j]].x, points[perm[j]].y));
    }
  }

  return;
}

void gen_random_encoder(sfmt_t *sfmt, mzed_t *m1, gf2e *f16, base_fun base[16], point_t points[32], unsigned perm[32])
{
  static unsigned id[32] = { 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15,
                            16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31
                           };

  fy_shuffle(sfmt, 32, id, perm);
  set_matrix(m1, f16, base, points, perm);
  mzed_echelonize(m1, 1);
}

int is_systematic(mzed_t *m1)
{
  int i;

  for (i = 0; i < 16; i++)
  {
    if (mzed_read_elem(m1, i, i) != 1)
      return 0;
  }

  return 1;
}

/*
 * Evaluate one cost function for matrix/vector multiplication of the coding part of
 * a systematic encoder
 * (for fixed dimensions, like many of the functions above in case you hadn't noticed)
 */
unsigned matrix_cost1(mzed_t *m1, int verbose)
{
  unsigned constants_used[16]; // i is 1 if we use this constant
  unsigned line_use[16][16];   // for each line, how many times we use a constant
  unsigned cost = 0;
  int i, j;

  if (!is_systematic(m1))
    return 1729;

  for (i = 0; i < 16; i++)
  {
    constants_used[i] = 0;
    for (j = 0; j < 16; j++)
    {
      line_use[i][j] = 0;
    }
  }

  for (i = 0; i < 16; i++)
  {
    for (j = 0; j < 16; j++)
    {
      constants_used[mzed_read_elem(m1, i, j + 16)] |= 1;
      line_use[i][mzed_read_elem(m1, i, j + 16)]    += 1;
    }
  }

  for (i = 2; i < 16; i++) // each different constant costs one multiplication (apart from zero and one)
    cost += constants_used[i];

  // for each positive constant, we'll need to pay $n$ `shuffles', for $n$ the maximum occurence of this constant in a line
  for (i = 1; i < 16; i++)
  {
    unsigned maxline = 0;
    for (j = 0; j < 16; j++)
    {
      maxline = MAX(maxline, line_use[j][i]);
    }
    cost += maxline;
  }

  if (verbose)
  {
    //printf("\x1b[31m]");
    printf("Matrix cost detail:\n");
    printf("Constants:\n");
    for (i = 0; i < 16; i++)
    {
      printf("%d\t", i);
    }
    printf("\n");
    for (i = 0; i < 16; i++)
    {
      printf("%d\t", constants_used[i]);
    }
    printf("\n");
    printf("Line usage\n");
    for (i = 0; i < 16; i++)
    {
      printf("%d\t", i);
    }
    printf("\n");
    for (i = 0; i < 16; i++)
    {
      unsigned maxline = 0;
      for (j = 0; j < 16; j++)
      {
        maxline = MAX(maxline, line_use[j][i]);
      }
      printf("%u\t", maxline);
    }
    printf("\n");
    //printf("\x1b[0m]");
  }

  return cost;
}

void find_good_encoders(sfmt_t *sfmt, unsigned long long howmany)
{
  gf2e   *f16;
  mzed_t *m1;
  base_fun base[16];
  point_t points[32];
  unsigned perm[32];
  unsigned long long tries;
  unsigned long long cost_breakup[60];
  int current, best = 1729;

  f16 = gf2e_init(0x13);
  m1 = mzed_init(f16, 16, 32);
  init_base(base);
  init_points(points);

  for (int i = 0; i < 60; i++)
    cost_breakup[i] = 0;

  for (tries = 0; tries < howmany; tries++)
  {
    gen_random_encoder(sfmt, m1, f16, base, points, perm);
    current = matrix_cost1(m1, 0);
    if (current < best)
    {
      best = current;
      printf("Encoder with cost %d:\n", best);
      mzed_print(m1);
      printf("Is obtained from point permutation:\n");
      for (int i = 0; i < 32; i++)
        printf("%d ", perm[i]);
      printf("\n-------------------------------------------------------------------------------------\n");
      fflush(stdout);
    }
    if (current < 60)
    {
      cost_breakup[current] += 1;
    }

    if ((tries & 0x3fffffff) == 0)
    {
      printf("@ %llu:\n\n", tries);
      for (int i = 0; i < 60; i++)
      {
        if (cost_breakup[i] > 0)
          printf("So much for #%d: %llu\n", i, cost_breakup[i]);

      }
      printf("\n");
      fflush(stdout);
    }
  }

  printf("@ %llu:\n\n", tries);
  for (int i = 0; i < 60; i++)
  {
    if (cost_breakup[i] > 0)
      printf("So much for #%d: %llu\n", i, cost_breakup[i]);
  }
  fflush(stdout);

  return;
}

/*
 * Tests
 */

void shuff_test(sfmt_t *sfmt, uint64_t seed)
{
  unsigned id[8];
  unsigned sh[8];

  for (int i = 0; i < 8; i++)
    id[i] = i;

  for (int i = 0; i < 10; i++)
  {
    fy_shuffle(sfmt, 8, id, sh);
    for (int j = 0; j < 8; j++)
      printf("%u ", sh[j]);
    printf("\n");
  }

  return;
}

void m4rie_test()
{
  gf2e   *f16;
  mzed_t *m1;

  f16 = gf2e_init(0x13);

  m1 = mzed_init(f16, 16, 32);

  mzed_print(m1);

  return;
}

void test_base(void)
{
  gf2e   *f16;
  word a, b;
  base_fun base[16];

  f16 = gf2e_init(0x13);

  init_base(base);

  a = 7;
  b = 13;

  for (int i = 0; i < 16; i++)
  {
    printf("%llu\n", base[i](f16, a, b));
  }

  return;
}

void test_systematic(void)
{
  gf2e   *f16;
  mzed_t *m1;
  base_fun base[16];
  point_t points[32];
  unsigned perm[32];

  f16 = gf2e_init(0x13);
  m1 = mzed_init(f16, 16, 32);
  init_base(base);
  init_points(points);
  for (int i = 0; i < 32; i++)
    perm[i] = (7*i + 5) % 32;

  set_matrix(m1, f16, base, points, perm);
  mzed_echelonize(m1, 1);
  printf("%d\n", is_systematic(m1));
  printf("%d\n", matrix_cost1(m1, 0));

  mzed_print(m1);
}

void test_good_ortho(void)
{
  gf2e   *f16;
  mzed_t *m1;
  mzed_t *a1, *a1t, *a1r;
  base_fun base[16];
  point_t points[32];
  unsigned perm[32] = {2, 7, 27, 30, 28, 16, 0, 20, 8, 19, 10, 24, 14, 5, 13, 23, 12, 6, 9, 31, 25, 1, 4, 22, 11, 15, 26, 3, 18, 21, 29, 17};

  f16 = gf2e_init(0x13);
  m1  = mzed_init(f16, 16, 32);
  a1  = mzed_init(f16, 16, 16);
  a1t = mzed_init(f16, 16, 16);
  a1r = mzed_init(f16, 16, 16);
  init_base(base);
  init_points(points);

  set_matrix(m1, f16, base, points, perm);
  mzed_echelonize(m1, 1);

  for (int i = 0; i < 16; i++)
  {
    for (int j = 0; j < 16; j++)
    {
      mzed_write_elem(a1, i, j, mzed_read_elem(m1, i, j + 16));
      mzed_write_elem(a1t, j, i, mzed_read_elem(m1, i, j + 16));
    }
  }

  mzed_mul(a1r, a1, a1t);

  mzed_print(a1);
  printf("#\n");
  mzed_print(a1t);
  printf("#\n");
  mzed_print(a1r);

  return;
}

void test_good_mul(void)
{
  gf2e   *f16;
  mzed_t *m1;
  mzed_t *a1, *v1, *v1r;
  base_fun base[16];
  point_t points[32];
  unsigned perm[32] = {17, 26, 9, 0, 29, 30, 15, 3, 4, 23, 7, 21, 12, 11, 19, 24, 6, 22, 25, 27, 8, 1, 2, 14, 18, 13, 5, 10, 31, 20, 28, 16};

  f16 = gf2e_init(0x13);
  m1  = mzed_init(f16, 16, 32);
  a1  = mzed_init(f16, 16, 16);
  v1  = mzed_init(f16, 16, 1);
  v1r = mzed_init(f16, 16, 1);
  init_base(base);
  init_points(points);

  set_matrix(m1, f16, base, points, perm);
  mzed_echelonize(m1, 1);

  for (int i = 0; i < 16; i++)
  {
    for (int j = 0; j < 16; j++)
    {
      mzed_write_elem(a1, i, j, mzed_read_elem(m1, i, j + 16));
    }
  }

//  for (int i = 0; i < 16; i++)
//  {
//    mzed_write_elem(v1, i, 0, 0xa);
//  }
//  mzed_write_elem(v1, 0, 0, 0x3);
  for (int i = 0; i < 16; i++)
  {
    mzed_write_elem(v1, i, 0, i);
  }
  mzed_write_elem(v1, 12, 0, 0x3);

  mzed_mul(v1r, a1, v1);

  mzed_print(a1);
  printf("#\n");
  mzed_print(v1);
  printf("#\n");
  mzed_print(v1r);

  return;
}

int main(int argc, char **argv)
{
  uint64_t seed;
  sfmt_t sfmt;

  if (argc != 2)
  {
    printf("usage: brutal_random <seed>\n");
    return 1;
  }

  seed = atoi(argv[1]);
  sfmt_init_gen_rand(&sfmt, seed);

  //shuff_test(&sfmt, seed);
  //m4rie_test();
  //test_base();
  //test_systematic();
  //test_good_ortho();
  test_good_mul();
  //find_good_encoders(&sfmt, 1ull << LOGOMANY);

  return 0;
}
