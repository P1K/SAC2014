; Matrix/vector multiplication for one diffusion matrix of dim. 16
; over F_16.
;
; PK -- 2014-05

default rel ; default mode is rip-relative addressing

section .data align=16

; multiplication table
;tim0: dq 0x0000000000000000, 0x0000000000000000
;tim1: dq 0x0706050403020100, 0x0f0e0d0c0b0a0908
;tim2: dq 0x0e0c0a0806040200, 0x0d0f090b05070103
;tim3: dq 0x090a0f0c05060300, 0x020104070e0d080b
;tim4: dq 0x0f0b07030c080400, 0x090d01050a0e0206
;tim5: dq 0x080d02070f0a0500, 0x06030c0901040b0e
;tim6: dq 0x01070d0b0a0c0600, 0x0402080e0f090305
;tim7: dq 0x0601080f090e0700, 0x0b0c050204030a0d
;tim8: dq 0x0d050e060b030800, 0x0109020a070f040c
;tim9: dq 0x0a030b0208010900, 0x0e070f060c050d04
;timA: dq 0x0309040e0d070a00, 0x0c060b010208050f
;timB: dq 0x040f010a0e050b00, 0x0308060d09020c07
;timC: dq 0x020e0905070b0c00, 0x0804030f0d01060a
;timD: dq 0x05080c0104090d00, 0x070a0e03060b0f02
;timE: dq 0x0c02030d010f0e00, 0x050b0a0408060709
;timF: dq 0x0b040609020d0f00, 0x0a050708030c0e01

; same, but in nice order for m64
ttim2 : dq 0x0e0c0a0806040200, 0x0d0f090b05070103
ttim8 : dq 0x0d050e060b030800, 0x0109020a070f040c
ttimD : dq 0x05080c0104090d00, 0x070a0e03060b0f02
ttimC : dq 0x020e0905070b0c00, 0x0804030f0d01060a
ttimF : dq 0x0b040609020d0f00, 0x0a050708030c0e01
ttimD2: dq 0x05080c0104090d00, 0x070a0e03060b0f02
ttimE : dq 0x0c02030d010f0e00, 0x050b0a0408060709
ttim7 : dq 0x0601080f090e0700, 0x0b0c050204030a0d
ttimD3: dq 0x05080c0104090d00, 0x070a0e03060b0f02
ttim9 : dq 0x0a030b0208010900, 0x0e070f060c050d04
ttimB : dq 0x040f010a0e050b00, 0x0308060d09020c07
ttimD4: dq 0x05080c0104090d00, 0x070a0e03060b0f02
ttim22: dq 0x0e0c0a0806040200, 0x0d0f090b05070103

; shuffles for _m64 (For Realz, matrix of cost 43.)
pp10: dq 0x0005000507040d02, 0x0f01040a03060809
pp11: dq 0xffff0e0c0e0bffff, 0xff0b08ff040cffff ; 0xff for not selected nibbles (t'will zero 'em)
pp12: dq 0xffffff0eff0dffff, 0xffffffffffffffff
;
pp20: dq 0x050306070602040e, 0x0408010c01000b04
pp21: dq 0x0c0e0909ff0307ff, 0x0bff020effff0dff
pp22: dq 0xffffff0fff0affff, 0xffffffffffffffff
;
pp30: dq 0xffffff02ff09ff09, 0x0affff04ffffff02
pp31: dq 0xffffff04ff0eff0a, 0x0effff0fffffff0f
;
pp40: dq 0x010703ffffff03ff, 0xffff07ffffff06ff
pp41: dq 0xff0bffffffff0cff, 0xffffffffffffffff
;
pp50: dq 0xff0007ffffff08ff, 0x00030308ff02ffff
pp51: dq 0xff0cffffffff0bff, 0xff09ffffff07ffff
;
pp60: dq 0x0908ffff05ff0001, 0x0107ff060d030206
pp61: dq 0x0a0affffffff0f03, 0xffffffffffff0f07
;
pp80: dq 0xff0d02ff03ff05ff, 0x0cff090b07ffffff
;
pp90: dq 0x0301010802000607, 0x050e060d09040703
pp91: dq 0x0b0f0cffffff0a0c, 0xffff0affffff0c0a
pp92: dq 0xffff0fffffffff0f, 0xffff0bffffffff0b
;
ppA0: dq 0x06ff050a090fff04, 0x09ff050202ff0101
ppA1: dq 0x0fff0dff0bffff06, 0x0dff0d050bff0a0e
ppA2: dq 0xffffffff0cffffff, 0xffffffff0cffffff
;
ppB0: dq 0x0e02ff0604010900, 0x0205ff03000d0408
ppB1: dq 0xffffff0d0805ffff, 0x070aff090e0fffff
;
ppC0: dq 0x07060affffff010b, 0x08020c00ff09030c
ppC1: dq 0xffff0bffffffffff, 0xffff0fffffffffff
;
ppD0: dq 0x04ffff00ff06ff08, 0xff04ffffff0a0e00
ppD1: dq 0xffffff01ff08ffff, 0xff0fffffff0effff
;
ppE0: dq 0x02ff040b0f0cff05, 0x06ff0e010aff090d
;
ppF0: dq 0xff0408030a070e0d, 0xff0000ff0508ff05
ppF1: dq 0xffffffff0dffffff, 0xff0cffff0f0bffff

section .text
global _m64

; THIS WAS VERIFIED quite a bit with a reference M4RIE implementation
; multiplication in the real mixed special case where the matrix
; can be computed as the sum of multiples of selections of the vector
; input   : in xmm0 (only 4 lower bits of each 16 byte are set)
; output  : ""
; uses    : xmm1, xmm2
; --------------------------

; 1 is the location of the vector, 2 is the temporary register where to store the multiplied thingy, 3 is the constant index
%macro vec_mul 3
  movdqa %2, [ttim2 + %3*16]
  pshufb %2, %1
  movdqa %1, %2
%endmacro

; 1 is the accu, 2 is the multiplied vector, 3 is storage for the shuffled thingy, 4 is the index for the shuffle
; (the movdqa could be removed in some cases if we can start from where the previous thingy was left)
%macro pp_accu 4
  movdqa %3, %2
  pshufb %3, [pp10 + %4*16]
  pxor   %1, %3
%endmacro

; AVX versions
;-------------

; 1 is the location of the vector, 2 is the temporary register where to store the multiplied thingy, 3 is the constant index
%macro vec_mul_a 3
  movdqa %2, [ttim2 + %3*16]
  vpshufb %1, %2, %1
%endmacro

; 1 is the accu, 2 is the multiplied vector, 3 is storage for the shuffled thingy, 4 is the index for the shuffle
; (the movdqa could be removed in some cases if we can start from where the previous thingy was left)
%macro pp_accu_a 4
  vpshufb %3, %2, [pp10 + %4*16]
  pxor   %1, %3
%endmacro

_m64:
  pxor xmm1, xmm1 ; init the accumulator
.mainstuff:
  ; 1.x
  pp_accu_a xmm1, xmm0, xmm2, 0
  pp_accu_a xmm1, xmm0, xmm2, 1
  pp_accu_a xmm1, xmm0, xmm2, 2
  ; 2.x
  vec_mul_a xmm0, xmm2, 0
  pp_accu_a xmm1, xmm0, xmm2, 3
  pp_accu_a xmm1, xmm0, xmm2, 4
  pp_accu_a xmm1, xmm0, xmm2, 5
  ; 3.x
  vec_mul_a xmm0, xmm2, 1
  pp_accu_a xmm1, xmm0, xmm2, 6
  pp_accu_a xmm1, xmm0, xmm2, 7
  ; 4.x
  vec_mul_a xmm0, xmm2, 2
  pp_accu_a xmm1, xmm0, xmm2, 8
  pp_accu_a xmm1, xmm0, xmm2, 9
  ; 5.x
  vec_mul_a xmm0, xmm2, 3
  pp_accu_a xmm1, xmm0, xmm2, 10
  pp_accu_a xmm1, xmm0, xmm2, 11
  ; 6.x
  vec_mul_a xmm0, xmm2, 4
  pp_accu_a xmm1, xmm0, xmm2, 12
  pp_accu_a xmm1, xmm0, xmm2, 13
  ; 8.x
  vec_mul_a xmm0, xmm2, 5
  pp_accu_a xmm1, xmm0, xmm2, 14
  ; 9.x
  vec_mul_a xmm0, xmm2, 6
  pp_accu_a xmm1, xmm0, xmm2, 15
  pp_accu_a xmm1, xmm0, xmm2, 16
  pp_accu_a xmm1, xmm0, xmm2, 17
  ; 10.x
  vec_mul_a xmm0, xmm2, 7
  pp_accu_a xmm1, xmm0, xmm2, 18
  pp_accu_a xmm1, xmm0, xmm2, 19
  pp_accu_a xmm1, xmm0, xmm2, 20
  ; 11.x
  vec_mul_a xmm0, xmm2, 8
  pp_accu_a xmm1, xmm0, xmm2, 21
  pp_accu_a xmm1, xmm0, xmm2, 22
  ; 12.x
  vec_mul_a xmm0, xmm2, 9
  pp_accu_a xmm1, xmm0, xmm2, 23
  pp_accu_a xmm1, xmm0, xmm2, 24
  ; 13.x
  vec_mul_a xmm0, xmm2, 10
  pp_accu_a xmm1, xmm0, xmm2, 25
  pp_accu_a xmm1, xmm0, xmm2, 26
  ; 14.x
  vec_mul_a xmm0, xmm2, 11
  pp_accu_a xmm1, xmm0, xmm2, 27
  ; 15.x
  vec_mul_a xmm0, xmm2, 12
  pp_accu_a xmm1, xmm0, xmm2, 28
  pp_accu_a xmm1, xmm0, xmm2, 29
.fin:
  ; the result is still of the form r0r0r0r0r0r0r0r0r0r0r0r0r0r0r0r0
  movdqa xmm0, xmm1
  ret
