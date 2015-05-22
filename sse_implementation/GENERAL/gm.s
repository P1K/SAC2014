; Matrix/vector multiplication for one diffusion matrix of dim. 16
; over F_16.
;
; PK -- 2014-05

default rel ; default mode is rip-relative addressing

section .data align=16

cle: dq 0x0f0f0f0f0f0f0f0f, 0x0f0f0f0f0f0f0f0f
; oddeven mask for x,x^2 (for realz)
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
global _m64

; Checked okay a bit with M4RIE ref (it is transposed here)
; below a bit messy and not optimized, check ref for better code
; input   : in xmm0 (only 4 lower bits of each 16 byte are set)
; output  : "
; uses    : xmm1--6
; --------------------------

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

_m64:
  pxor xmm5, xmm5 ; constant zero
  pxor xmm6, xmm6 ; accumulator
.mainstuff:
  m_1_line_a xmm0, xmm1, xmm2, xmm3, xmm4, xmm5, xmm6, 0
  m_1_line_a xmm0, xmm1, xmm2, xmm3, xmm4, xmm5, xmm6, 1
  m_1_line_a xmm0, xmm1, xmm2, xmm3, xmm4, xmm5, xmm6, 2
  m_1_line_a xmm0, xmm1, xmm2, xmm3, xmm4, xmm5, xmm6, 3
  m_1_line_a xmm0, xmm1, xmm2, xmm3, xmm4, xmm5, xmm6, 4
  m_1_line_a xmm0, xmm1, xmm2, xmm3, xmm4, xmm5, xmm6, 5
  m_1_line_a xmm0, xmm1, xmm2, xmm3, xmm4, xmm5, xmm6, 6
  m_1_line_a xmm0, xmm1, xmm2, xmm3, xmm4, xmm5, xmm6, 7
  m_1_line_a xmm0, xmm1, xmm2, xmm3, xmm4, xmm5, xmm6, 8
  m_1_line_a xmm0, xmm1, xmm2, xmm3, xmm4, xmm5, xmm6, 9
  m_1_line_a xmm0, xmm1, xmm2, xmm3, xmm4, xmm5, xmm6, 10
  m_1_line_a xmm0, xmm1, xmm2, xmm3, xmm4, xmm5, xmm6, 11
  m_1_line_a xmm0, xmm1, xmm2, xmm3, xmm4, xmm5, xmm6, 12
  m_1_line_a xmm0, xmm1, xmm2, xmm3, xmm4, xmm5, xmm6, 13
  m_1_line_a xmm0, xmm1, xmm2, xmm3, xmm4, xmm5, xmm6, 14
  m_1_line_a xmm0, xmm1, xmm2, xmm3, xmm4, xmm5, xmm6, 15
.fin:
  pand xmm6, [cle]
  movdqa xmm0, xmm6
  ret
