; Parallel vectorized sub-byte with the AES S-Box.
;
; Chiefly derived from Hamburg's implementation (there's a lot of copy-paste involved)
;
; PK 2014-05

default rel ; default mode is rip-relative addressing

section .data align=16

; s0F
k_s0F:    dq 0x0F0F0F0F0F0F0F0F, 0x0F0F0F0F0F0F0F0F

; input transform (lo, hi)
k_ipt_lo: dq 0xC2B2E8985A2A7000, 0xCABAE09052227808
k_ipt_hi: dq 0x4C01307D317C4D00, 0xCD80B1FCB0FDCC81

; inv, inva
k_inv:    dq 0x0E05060F0D080180, 0x040703090A0B0C02
k_inva:   dq 0x01040A060F0B0780, 0x030D0E0C02050809

; sbou, sbot
k_sbou:   dq 0xD0D26D176FBDC700, 0x15AABF7AC502A878
k_sbot:   dq 0xCFE474A55FBB6A00, 0x8E1E90D1412B35FA

;; sb1u, sb1t
;k_sb1u:   dq 0xB19BE18FCB503E00, 0xA5DF7A6E142AF544
;k_sb1t:   dq 0x3618D415FAE22300, 0x3BF7CCC10D2ED9EF
;
;; sb2u, sb2t
;k_sb2u:   dq 0xE27A93C60B712400, 0x5EB7E955BC982FCD
;k_sb2t:   dq 0x69EB88400AE12900, 0xC2A163C8AB82234A

; multiplication tables of F_2[x] / x^4 + x^3 + x^2 + x + 1
;ttim2 : dq 0x0e0c0a0806040200, 0x01030507090b0d0f
;ttim3 : dq 0x090a0f0c05060300, 0x0e0d080b02010407
;ttim4 : dq 0x03070b0f0c080400, 0x02060a0e0d090501
;ttim5 : dq 0x04010e0b0f0a0500, 0x0d08070206030c09
;ttim6 : dq 0x0d0b01070a0c0600, 0x03050f090402080e
;ttim7 : dq 0x0a0d0403090e0700, 0x0c0b02050f080106
;ttim8 : dq 0x060e0901070f0800, 0x040c0b03050d0a02
;ttim9 : dq 0x01080c05040d0900, 0x0b02060f0e07030a
;ttima : dq 0x08020309010b0a00, 0x050f0e040c06070d
;ttimb : dq 0x0f04060d02090b00, 0x0a010308070c0e05
;ttimc : dq 0x0509020e0b070c00, 0x060a010d08040f03
;ttimd : dq 0x020f070a08050d00, 0x09040c01030e060b
;ttime : dq 0x0b0508060d030e00, 0x0709040a010f020c
;ttimf : dq 0x0c030d020e010f00, 0x080709060a050b04

; multiplication tables in nice order
; (we're assuming the same matrix than with the other representation, rather for lolz)
; also, this is probably not correct anymore because of the change
; of repr, but you get the idea
ttim2 : dq 0x0e0c0a0806040200, 0x01030507090b0d0f
ttim8 : dq 0x060e0901070f0800, 0x040c0b03050d0a02
ttimD : dq 0x020f070a08050d00, 0x09040c01030e060b
ttimC : dq 0x0509020e0b070c00, 0x060a010d08040f03
ttimF : dq 0x0c030d020e010f00, 0x080709060a050b04
ttimD2: dq 0x020f070a08050d00, 0x09040c01030e060b
ttimE : dq 0x0b0508060d030e00, 0x0709040a010f020c
ttim7 : dq 0x0a0d0403090e0700, 0x0c0b02050f080106
ttimD3: dq 0x020f070a08050d00, 0x09040c01030e060b
ttim9 : dq 0x01080c05040d0900, 0x0b02060f0e07030a
ttimB : dq 0x0f04060d02090b00, 0x0a010308070c0e05
ttimD4: dq 0x020f070a08050d00, 0x09040c01030e060b
ttim22: dq 0x0e0c0a0806040200, 0x01030507090b0d0f

; shuffles
pp10: dq 0x0005000507040d02, 0x0f01040a03060809
pp11: dq 0xffff0e0c0e0bffff, 0xff0b08ff040cffff
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

; not exactly correct because of representation
; but you get the idea
oe1: dq 0xff0ff000ff0ff000, 0xff0ff000ff0ff000
;oe1: dq 0xffffffffffffffff, 0xffffffffffffffff
; oddeven mask for x^4,x^8 (for realz)
oe2: dq 0xf0f0f0f000000000, 0xffffffff0f0f0f0f
; first (zero) line & first line times x^2 (alternate) (for realz)
c01: dq 0x91a7efa76c126cb5, 0x9124fd91cb3636d9
; first line times x^4 & first line times x^8 (alternate) (for realz)
c02: dq 0x24efd9efb548b5a7, 0x248391245acbcb12
c11: dq 0x249183244800cb6c, 0x6cfd12485a91b55a
c12: dq 0x83246c8336005ab5, 0xb59148367e24a77e
c21: dq 0xfdd9b5122424b591, 0xa73612ef122436d9
c22: dq 0x9112a7488383a724, 0xefcb48d94883cb12
c31: dq 0x12246cb583910000, 0xef12fda7a7fda7b5
c32: dq 0x4883b5a76c240000, 0xd94891efef91efa7
c41: dq 0x24b51236fd36d9d9, 0x2412b512efa72491
c42: dq 0x83a748cb91cb1212, 0x8348a748d9ef8324
c51: dq 0x5a24a7ef48839112, 0x9112a791cbcb24fd
c52: dq 0x7e83efd9366c2448, 0x2448ef245a5a8391
c61: dq 0x48cb12fd24b5915a, 0x9124835a486c006c
c62: dq 0x365a489183a7247e, 0x24836c7e36b500b5
c71: dq 0xcba724d991ef4812, 0xa7b50024916c6c00
c72: dq 0x5aef831224d93648, 0xefa7008324b5b500
c81: dq 0x6c6cfd249136a7d9, 0x36a7efcb919112b5
c82: dq 0xb5b5918324cbef12, 0xcbefd95a242448a7
c91: dq 0x914800b5cb6ca700, 0x6cd9249124a7ef12
c92: dq 0x243600a75ab5ef00, 0xb512832483efd948
ca1: dq 0x5a1200916c5a0024, 0xb5d9b512fdd9cbfd
ca2: dq 0x7e480024b57e0083, 0xa712a74891125a91
cb1: dq 0x8300fd1212a724b5, 0xfdb56ca7a7ef9100
cb2: dq 0x6c00914848ef83a7, 0x91a7b5efefd92400
cc1: dq 0x006ca736b5a7efcb, 0x362491248312b55a
cc2: dq 0x00b5efcba7efd95a, 0xcb8324836c48a77e
cd1: dq 0x4891a7125a2424fd, 0xcbefa7cb91918312
cd2: dq 0x3624ef487e838391, 0x5ad9ef5a24246c48
ce1: dq 0x6c00b5d95acb12fd, 0xd99100fd12b55a24
ce2: dq 0xb500a7127e5a4891, 0x1224009148a77e83
cf1: dq 0xb5ef912400b56c5a, 0x1236a7832436a7cb
cf2: dq 0xa7d9248300a7b57e, 0x48cbef6c83cbef5a

section .text
global _para_sb, _m128, _m128_2

; input in xmm0

_para_sb:
;	movdqa xmm9,  [k_s0F]
;	movdqa xmm10, [k_inv]
;	movdqa xmm11, [k_inva]
;	movdqa xmm13, [k_sb1u]
;	movdqa xmm12, [k_sb1t]
;	movdqa xmm15, [k_sb2u]
;	movdqa xmm14, [k_sb2t]
.input:
	movdqa xmm2, [k_ipt_lo]
	movdqa xmm1, [k_s0F] 
	pandn  xmm1, xmm0
	psrld  xmm1, 4
	pand   xmm0, [k_s0F] 
	pshufb xmm2, xmm0
	movdqa xmm0, [k_ipt_hi]
	pshufb xmm0, xmm1
	pxor   xmm0, xmm2
.inv:
	movdqa  xmm1, [k_s0F] 	; 1 : i
	pandn	  xmm1, xmm0 	; 1 = i<<4
	psrld  	xmm1, 4     ; 1 = i
	pand	  xmm0, [k_s0F]  ; 0 = k
	movdqa	xmm2, [k_inva]	; 2 : a/k
	pshufb  xmm2, xmm0	; 2 = a/k
	pxor	  xmm0, xmm1	; 0 = j
	movdqa  xmm3, [k_inv] ; 3 : 1/i
	pshufb  xmm3, xmm1	; 3 = 1/i
	pxor	  xmm3, xmm2 	; 3 = iak = 1/i + a/k
	movdqa	xmm4, [k_inv]	; 4 : 1/j
	pshufb	xmm4, xmm0 	; 4 = 1/j
	pxor	  xmm4, xmm2	; 4 = jak = 1/j + a/k
	movdqa  xmm2, [k_inv]	; 2 : 1/iak
	pshufb  xmm2, xmm3 	; 2 = 1/iak
	pxor	  xmm2, xmm0	; 2 = io
	movdqa  xmm3, [k_inv] ; 3 : 1/jak
	pshufb  xmm3, xmm4  ; 3 = 1/jak
	pxor	  xmm3, xmm1  ; 3 = jo
.fin:
	movdqa	xmm4, [k_sbou] ; 4 : sbou
	pshufb  xmm4, xmm2     ; 4 = sbou
	movdqa	xmm0, [k_sbot] ; 0 : sbot
	pshufb  xmm0, xmm3     ; 0 = sb1t
	pxor	  xmm0, xmm4     ; 0 = A

	ret


; 1 is the location of the vector, 2 is the temporary register where to store the multiplied thingy, 3 is the constant index
%macro vec_mul 3
  movdqa %2, [ttim2 + %3*16]
  pshufb %2, %1
  movdqa %1, %2
%endmacro

; 1 is the accu, 2 is the multiplied vector, 3 is storage for the shuffled thingy, 4 is the index for the shuffle
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
%macro pp_accu_a 4
  vpshufb %3, %2, [pp10 + %4*16]
  pxor   %1, %3
%endmacro

; input is in xmm0, which is then split into xmm0 and xmm1
; output in xmm0
; tries to interleave the multiplications on lo and hi somehow

_m128:
.input:
	movdqa xmm1, [k_s0F] 
	pandn  xmm1, xmm0
	psrld  xmm1, 4
	pand   xmm0, [k_s0F]
  pxor xmm4, xmm4 ; init the accumulators
  pxor xmm5, xmm5
.mainstuff:
  ; 1.x
  pp_accu_a xmm4, xmm0, xmm2, 0
  pp_accu_a xmm5, xmm1, xmm3, 0
  pp_accu_a xmm4, xmm0, xmm2, 1
  pp_accu_a xmm5, xmm1, xmm3, 1
  pp_accu_a xmm4, xmm0, xmm2, 2
  pp_accu_a xmm5, xmm1, xmm3, 2
  ; 2.x
  vec_mul_a xmm0, xmm2, 0
  vec_mul_a xmm1, xmm3, 0
  pp_accu_a xmm4, xmm0, xmm2, 3
  pp_accu_a xmm5, xmm1, xmm3, 3
  pp_accu_a xmm4, xmm0, xmm2, 4
  pp_accu_a xmm5, xmm1, xmm3, 4
  pp_accu_a xmm4, xmm0, xmm2, 5
  pp_accu_a xmm5, xmm1, xmm3, 5
  ; 3.x
  vec_mul_a xmm0, xmm2, 1
  vec_mul_a xmm1, xmm3, 1
  pp_accu_a xmm4, xmm0, xmm2, 6
  pp_accu_a xmm5, xmm1, xmm3, 6
  pp_accu_a xmm4, xmm0, xmm2, 7
  pp_accu_a xmm5, xmm1, xmm3, 7
  ; 4.x
  vec_mul_a xmm0, xmm2, 2
  vec_mul_a xmm1, xmm3, 2
  pp_accu_a xmm4, xmm0, xmm2, 8
  pp_accu_a xmm5, xmm1, xmm3, 8
  pp_accu_a xmm4, xmm0, xmm2, 9
  pp_accu_a xmm5, xmm1, xmm3, 9
  ; 5.x
  vec_mul_a xmm0, xmm2, 3
  vec_mul_a xmm1, xmm3, 3
  pp_accu_a xmm4, xmm0, xmm2, 10
  pp_accu_a xmm5, xmm1, xmm3, 10
  pp_accu_a xmm4, xmm0, xmm2, 11
  pp_accu_a xmm5, xmm1, xmm3, 11
  ; 6.x
  vec_mul_a xmm0, xmm2, 4
  vec_mul_a xmm1, xmm3, 4
  pp_accu_a xmm4, xmm0, xmm2, 12
  pp_accu_a xmm5, xmm1, xmm3, 12
  pp_accu_a xmm4, xmm0, xmm2, 13
  pp_accu_a xmm5, xmm1, xmm3, 13
  ; 8.x
  vec_mul_a xmm0, xmm2, 5
  vec_mul_a xmm1, xmm3, 5
  pp_accu_a xmm4, xmm0, xmm2, 14
  pp_accu_a xmm5, xmm1, xmm3, 14
  ; 9.x
  vec_mul_a xmm0, xmm2, 6
  vec_mul_a xmm1, xmm3, 6
  pp_accu_a xmm4, xmm0, xmm2, 15
  pp_accu_a xmm5, xmm1, xmm3, 15
  pp_accu_a xmm4, xmm0, xmm2, 16
  pp_accu_a xmm5, xmm1, xmm3, 16
  pp_accu_a xmm4, xmm0, xmm2, 17
  pp_accu_a xmm5, xmm1, xmm3, 17
  ; 10.x
  vec_mul_a xmm0, xmm2, 7
  vec_mul_a xmm1, xmm3, 7
  pp_accu_a xmm4, xmm0, xmm2, 18
  pp_accu_a xmm5, xmm1, xmm3, 18
  pp_accu_a xmm4, xmm0, xmm2, 19
  pp_accu_a xmm5, xmm1, xmm3, 19
  pp_accu_a xmm4, xmm0, xmm2, 20
  pp_accu_a xmm5, xmm1, xmm3, 20
  ; 11.x
  vec_mul_a xmm0, xmm2, 8
  vec_mul_a xmm1, xmm3, 8
  pp_accu_a xmm4, xmm0, xmm2, 21
  pp_accu_a xmm5, xmm1, xmm3, 21
  pp_accu_a xmm4, xmm0, xmm2, 22
  pp_accu_a xmm5, xmm1, xmm3, 22
  ; 12.x
  vec_mul_a xmm0, xmm2, 9
  vec_mul_a xmm1, xmm3, 9
  pp_accu_a xmm4, xmm0, xmm2, 23
  pp_accu_a xmm5, xmm1, xmm3, 23
  pp_accu_a xmm4, xmm0, xmm2, 24
  pp_accu_a xmm5, xmm1, xmm3, 24
  ; 13.x
  vec_mul_a xmm0, xmm2, 10
  vec_mul_a xmm1, xmm3, 10
  pp_accu_a xmm4, xmm0, xmm2, 25
  pp_accu_a xmm5, xmm1, xmm3, 25
  pp_accu_a xmm4, xmm0, xmm2, 26
  pp_accu_a xmm5, xmm1, xmm3, 26
  ; 14.x
  vec_mul_a xmm0, xmm2, 11
  vec_mul_a xmm1, xmm3, 11
  pp_accu_a xmm4, xmm0, xmm2, 27
  pp_accu_a xmm5, xmm1, xmm3, 27
  ; 15.x
  vec_mul_a xmm0, xmm2, 12
  vec_mul_a xmm1, xmm3, 12
  pp_accu_a xmm4, xmm0, xmm2, 28
  pp_accu_a xmm5, xmm1, xmm3, 28
  pp_accu_a xmm4, xmm0, xmm2, 29
  pp_accu_a xmm5, xmm1, xmm3, 29
.fin:
  pslld  xmm5, 4
  movdqa xmm0, xmm4
  pxor   xmm0, xmm5

  ret



; %1 is input
; %2,%3, %4, %5 are storage
; %6 is constant zero
; %7 is accumulator
; %8 is index
%macro m_1_line_2 8
  ; selects the right double-masks
  movdqa %2, [oe1]
  movdqa %3, [oe2]
  pshufb %2, %1 
  pshufb %3, %1
  ; shifted input for next round selection
  psrldq %1, 1
  ; expand
  pshufb %2, %6
  pshufb %3, %6
  ; select the lines with the double-masks
  pand   %2, [c01 + %8*16*2]
  pand   %3, [c02 + %8*16*2]
  ; shift and xor the lines together
  movdqa %4, %2
  movdqa %5, %3
  psrlq  %2, 4
  psrlq  %3, 4
  pxor   %4, %5
  pxor   %2, %3
  ; accumulate everything
  pxor   %2, %4 
  pxor   %7, %2
%endmacro

; AVX version
; -----------
; %1 is input
; %2,%3, %4, %5 are storage
; %6 is constant zero
; %7 is accumulator
; %8 is index
%macro m_1_line_a 8
  ; selects the right double-masks
  movdqa %2, [oe1]
  movdqa %3, [oe2]
  pshufb %2, %1 
  pshufb %3, %1
  ; shifted input for next round selection
  psrldq %1, 1
  ; expand
  pshufb %2, %6
  pshufb %3, %6
  ; select the lines with the double-masks
  pand   %2, [c01 + %8*16*2]
  pand   %3, [c02 + %8*16*2]
  ; shift and xor the lines together
  vpsrlq  %4, %2, 4
  vpsrlq  %5, %3, 4
  pxor   %4, %5
  pxor   %2, %3
  ; accumulate everything
  pxor   %2, %4 
  pxor   %7, %2
%endmacro

_m128_2:
.input:
	movdqa xmm1, [k_s0F] 
	pandn  xmm1, xmm0
	psrld  xmm1, 4
	pand   xmm0, [k_s0F]
  pxor xmm12, xmm12 ; constant zero
  pxor xmm10, xmm10 ; init the accumulators
  pxor xmm11, xmm11
.mainstuff:
  m_1_line_a xmm0, xmm2, xmm4, xmm6, xmm8, xmm12, xmm10, 0
  m_1_line_a xmm1, xmm3, xmm5, xmm7, xmm9, xmm12, xmm11, 0
  m_1_line_a xmm0, xmm2, xmm4, xmm6, xmm8, xmm12, xmm10, 1
  m_1_line_a xmm1, xmm3, xmm5, xmm7, xmm9, xmm12, xmm11, 1
  m_1_line_a xmm0, xmm2, xmm4, xmm6, xmm8, xmm12, xmm10, 2
  m_1_line_a xmm1, xmm3, xmm5, xmm7, xmm9, xmm12, xmm11, 2
  m_1_line_a xmm0, xmm2, xmm4, xmm6, xmm8, xmm12, xmm10, 3
  m_1_line_a xmm1, xmm3, xmm5, xmm7, xmm9, xmm12, xmm11, 3
  m_1_line_a xmm0, xmm2, xmm4, xmm6, xmm8, xmm12, xmm10, 4
  m_1_line_a xmm1, xmm3, xmm5, xmm7, xmm9, xmm12, xmm11, 4
  m_1_line_a xmm0, xmm2, xmm4, xmm6, xmm8, xmm12, xmm10, 5
  m_1_line_a xmm1, xmm3, xmm5, xmm7, xmm9, xmm12, xmm11, 5
  m_1_line_a xmm0, xmm2, xmm4, xmm6, xmm8, xmm12, xmm10, 6
  m_1_line_a xmm1, xmm3, xmm5, xmm7, xmm9, xmm12, xmm11, 6
  m_1_line_a xmm0, xmm2, xmm4, xmm6, xmm8, xmm12, xmm10, 7
  m_1_line_a xmm1, xmm3, xmm5, xmm7, xmm9, xmm12, xmm11, 7
  m_1_line_a xmm0, xmm2, xmm4, xmm6, xmm8, xmm12, xmm10, 8
  m_1_line_a xmm1, xmm3, xmm5, xmm7, xmm9, xmm12, xmm11, 8
  m_1_line_a xmm0, xmm2, xmm4, xmm6, xmm8, xmm12, xmm10, 9
  m_1_line_a xmm1, xmm3, xmm5, xmm7, xmm9, xmm12, xmm11, 9
  m_1_line_a xmm0, xmm2, xmm4, xmm6, xmm8, xmm12, xmm10, 10
  m_1_line_a xmm1, xmm3, xmm5, xmm7, xmm9, xmm12, xmm11, 10
  m_1_line_a xmm0, xmm2, xmm4, xmm6, xmm8, xmm12, xmm10, 11
  m_1_line_a xmm1, xmm3, xmm5, xmm7, xmm9, xmm12, xmm11, 11
  m_1_line_a xmm0, xmm2, xmm4, xmm6, xmm8, xmm12, xmm10, 12
  m_1_line_a xmm1, xmm3, xmm5, xmm7, xmm9, xmm12, xmm11, 12
  m_1_line_a xmm0, xmm2, xmm4, xmm6, xmm8, xmm12, xmm10, 13
  m_1_line_a xmm1, xmm3, xmm5, xmm7, xmm9, xmm12, xmm11, 13
  m_1_line_a xmm0, xmm2, xmm4, xmm6, xmm8, xmm12, xmm10, 14
  m_1_line_a xmm1, xmm3, xmm5, xmm7, xmm9, xmm12, xmm11, 14
  m_1_line_a xmm0, xmm2, xmm4, xmm6, xmm8, xmm12, xmm10, 15
  m_1_line_a xmm1, xmm3, xmm5, xmm7, xmm9, xmm12, xmm11, 15
.fin:
  pand   xmm10, [k_s0F]
  pand   xmm11, [k_s0F]
  pslld  xmm11, 4
  movdqa xmm0, xmm10
  pxor   xmm0, xmm11

  ret
