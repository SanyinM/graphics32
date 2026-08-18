unit GR32.Types.SIMD;

(* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1 or LGPL 2.1 with linking exception
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * Alternatively, the contents of this file may be used under the terms of the
 * Free Pascal modified version of the GNU Lesser General Public License
 * Version 2.1 (the "FPC modified LGPL License"), in which case the provisions
 * of this license are applicable instead of those above.
 * Please see the file LICENSE.txt for additional information concerning this
 * license.
 *
 * The Original Code is SIMD for Graphics32
 *
 * The Initial Developer of the Original Code is Anders Melander
 *
 * Portions created by the Initial Developer are Copyright (C) 2025
 * the Initial Developer. All Rights Reserved.
 *
 * ***** END LICENSE BLOCK ***** *)

interface

{$include GR32.inc}

(*

        Asm register usage

        32-bit, x86 stdcall calling convention
        ------------------------------------------------
        Parameters: EAX, EDX, ECX, Stack
        Return value: EAX
        Can modify: EAX, ECX, and EDX
        Must preserve: EDI, ESI, ESP, EBP, and EBX

        64-bit, x64 calling convention
        ------------------------------------------------
        Parameters: RCX, RDX, R8, R9 (integer) or XMMO, XMM1, XMM2, XMM3 (float), Stack
        Return value: RAX (integer), XMM+ (float)
        Can modify: RAX, RCX, RDX, R8, R9, R10, R11, XMMO, XMM1, XMM2, XMM3
        Must preserve: R12, R13, R14, R15, RDI, RSI, RBX, RBP, RSP, XMM4, XMM5, XMM6, XMM7, XMM8, XMM8, XMM9, XMM10, XMM11, XMM12, XMM13, XMM14, and XMM15

*)

{$if not defined(PUREPASCAL)}

//------------------------------------------------------------------------------
//
//      SSE MXCSR rounding modes
//      For use with the SSE2 CVTSS2SI instruction - and friends.
//
//------------------------------------------------------------------------------
type
  MXCSR = record
    const
      MASK              = $FFFF9FFF;
      NEAREST           = $00000000;        // Round
      DOWN              = $00002000;        // Floor
      UP                = $00004000;        // Ceil
      TRUNC             = $00006000;        // Trunc
  end;


//------------------------------------------------------------------------------
//
//      Rounding control values.
//      For use with the SSE4.1 ROUND[S/P][S/D] instruction
//
//------------------------------------------------------------------------------
type
  SSE_ROUND = record
    const
      TO_NEAREST_INT    = $00; // Round
      TO_NEG_INF        = $01; // Floor
      TO_POS_INF        = $02; // Ceil
      TO_ZERO           = $03; // Trunc
      CUR_DIRECTION     = $04; // Rounds using default from MXCSR register

      RAISE_EXC         = $00; // Raise exceptions
      NO_EXC            = $08; // Suppress exceptions
  end;


//------------------------------------------------------------------------------
//
//      SIMD constants
//
//------------------------------------------------------------------------------
// All SIMD values are arrays of 4 elements.
// Element size is 32-bits so the type is either Single, Cardinal or Integer.
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Unaligned constants
//------------------------------------------------------------------------------
const
  SSE_FloatOne          : array[0..3] of Single   = (1, 1, 1, 1);
  SSE_Float255          : array[0..3] of Single   = (255, 255, 255, 255);
  SSE_Float256x256      : array[0..3] of Single   = ($00010000, $00010000, $00010000, $00010000); // 256*256
  SSE_FloatScale        : array[0..3] of Single   = (1/65536.0, 1/65536.0, 1/65536.0, 1/65536.0);
  SSE_IntAbsMask        : array[0..3] of Cardinal = ($7FFFFFFF, $7FFFFFFF, $7FFFFFFF, $7FFFFFFF);


//------------------------------------------------------------------------------
// Aligned constants. Implemented as no-code assembly routines.
//------------------------------------------------------------------------------
// 8 x $FF00
procedure SSE_FF00FF00_ALIGNED;
// 8 x $00FF
procedure SSE_00FF00FF_ALIGNED;
// 8 x 257 for use in x div 255 = ((x + 128) * 257) >> 16
procedure SSE_01010101_ALIGNED;
// 8 x 128 for use in x div 255 = ((x + 128) * 257) >> 16
procedure SSE_00800080_ALIGNED;

// x/255 bias table ($7F * $8101)
procedure SSE_003FFF7F_ALIGNED;

// Aligned pack table for PSHUFB: Picks low byte of 4 dwords
procedure SSE_0C080400_ALIGNED;

// Four aligned 0.5 floats
procedure SSE_FloatHalf_ALIGNED;

// Four aligned 1.0 floats
procedure SSE_FloatOne_ALIGNED;

// Four aligned 2.0 floats
procedure SSE_FloatTwo_ALIGNED;

// 1 x $80000000
procedure SSE_80000000_ALIGNED;

// (6,7,6,7,6,7,6,7,14,15,14,15,14,15,14,15)
procedure SSE_PSHUFB_ALPHA_WORD_MASK_ALIGNED;

procedure SSE_AlphaMask_ALIGNED;

procedure SSE_AlphaExtractMask_ALIGNED;

// Ra words -> Alpha bytes (for PSHUFB)
procedure SSE_RaToAlpha_Mask_ALIGNED;

// Four 1 dwords
procedure SSE_00000001_ALIGNED;

// ARGB alpha byte positions: B G R A  B G R A ...
procedure SSE_AlphaClearMask_ALIGNED;

// 4 x 255 (floats)
procedure SSE_255f_ALIGNED;

// Broadcast Wa across all 4 word lanes
procedure SSE_Wa01_Mask_ALIGNED;

// $00000000 $00000000 $00000000 $FFFFFFFF
procedure SSE_AlphaLaneMask_ALIGNED;

// PSHUFB mask
procedure SSE_DwordsToWords_Mask_ALIGNED;

procedure SSE_PSHUFB_R4_BYTE_MASK;

procedure SSE_PSHUFB_G4_BYTE_MASK;

procedure SSE_PSHUFB_B4_BYTE_MASK;

procedure SSE_PSHUFB_A4_BYTE_MASK;

// 4 x (1 / 255.0) floats
procedure SSE_INV255_FLOAT_ALIGNED;

// $FF000000 $FF000000 $FF000000 $FF000000
procedure SSE_ALPHA_MASK_ALIGNED;
{$ifend}

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

implementation


procedure SSE_PSHUFB_ALPHA_WORD_MASK_ALIGNED; {$IFDEF FPC} assembler; nostackframe; {$ENDIF}
asm
{$ifdef FPC}
  ALIGN 16
{$else}
  .ALIGN 16
{$endif}
  db $6, $7, $6, $7, $6, $7, $6, $7
  db $E, $F, $E, $F, $E, $F, $E, $F
end;

// 8 x $FF00
procedure SSE_FF00FF00_ALIGNED; {$IFDEF FPC} assembler; nostackframe; {$ENDIF}
asm
{$ifdef FPC}
  ALIGN 16
{$else}
  .ALIGN 16
{$endif}
  dw $FF00, $FF00, $FF00, $FF00
  dw $FF00, $FF00, $FF00, $FF00
end;

// 8 x $00FF
procedure SSE_00FF00FF_ALIGNED; {$IFDEF FPC} assembler; nostackframe; {$ENDIF}
asm
{$ifdef FPC}
  ALIGN 16
{$else}
  .ALIGN 16
{$endif}
  dw $00FF, $00FF, $00FF, $00FF
  dw $00FF, $00FF, $00FF, $00FF
end;

// 8 x 257
procedure SSE_01010101_ALIGNED; {$IFDEF FPC} assembler; nostackframe; {$ENDIF}
asm
{$ifdef FPC}
ALIGN 16
{$else}
.ALIGN 16
{$endif}
  dw $0101, $0101, $0101, $0101
  dw $0101, $0101, $0101, $0101
end;

// 8 x 128
procedure SSE_00800080_ALIGNED; {$IFDEF FPC} assembler; nostackframe; {$ENDIF}
asm
{$ifdef FPC}
  ALIGN 16
{$else}
  .ALIGN 16
{$endif}
  dw $0080, $0080, $0080, $0080
  dw $0080, $0080, $0080, $0080
end;

// Aligned bias table
procedure SSE_003FFF7F_ALIGNED; {$IFDEF FPC} assembler; nostackframe; {$ENDIF}
asm
{$ifdef FPC}
  ALIGN 16
{$else}
  .ALIGN 16
{$endif}
  db $7F, $FF, $3F, $0
  db $7F, $FF, $3F, $0
  db $7F, $FF, $3F, $0
  db $7F, $FF, $3F, $0
end;

// Aligned pack table for PSHUFB: Picks low byte of 4 dwords
procedure SSE_0C080400_ALIGNED; {$IFDEF FPC} assembler; nostackframe; {$ENDIF}
asm
{$ifdef FPC}
  ALIGN 16
{$else}
  .ALIGN 16
{$endif}
  db $00, $04, $08, $0C
  db $00, $04, $08, $0C
  db $00, $04, $08, $0C
  db $00, $04, $08, $0C
end;

// Four aligned 0.5 floats
procedure SSE_FloatHalf_ALIGNED; {$IFDEF FPC} assembler; nostackframe; {$ENDIF}
asm
  {$IFDEF FPC}
  ALIGN 16
  {$ELSE}
  .ALIGN 16
  {$ENDIF}
  db $00, $00, $00, $3F
  db $00, $00, $00, $3F
  db $00, $00, $00, $3F
  db $00, $00, $00, $3F
end;

// Four aligned 1.0 floats
procedure SSE_FloatOne_ALIGNED; {$IFDEF FPC} assembler; nostackframe; {$ENDIF}
asm
  {$IFDEF FPC}
  ALIGN 16
  {$ELSE}
  .ALIGN 16
  {$ENDIF}
  db $00, $00, $80, $3F
  db $00, $00, $80, $3F
  db $00, $00, $80, $3F
  db $00, $00, $80, $3F
end;

// 1 x $80000000
procedure SSE_80000000_ALIGNED; {$IFDEF FPC} assembler; nostackframe; {$ENDIF}
asm
  {$IFDEF FPC}
  ALIGN 16
  {$ELSE}
  .ALIGN 16
  {$ENDIF}
  db $00, $00, $00, $80
  db $00, $00, $00, $00
  db $00, $00, $00, $00
  db $00, $00, $00, $00
end;

procedure SSE_AlphaMask_ALIGNED; {$IFDEF FPC} assembler; nostackframe; {$ENDIF}
asm
{$ifdef FPC}
  ALIGN 16
{$else}
  .ALIGN 16
{$endif}
  dw $0000, $0000, $0000, $FFFF
  dw $0000, $0000, $0000, $FFFF
end;

procedure SSE_AlphaExtractMask_ALIGNED; {$IFDEF FPC} assembler; nostackframe; {$ENDIF}
asm
{$ifdef FPC}
  ALIGN 16
{$else}
  .ALIGN 16
{$endif}
   dd $0F0B0703
   dd $80808080
   dd $80808080
   dd $80808080
end;

procedure SSE_FloatTwo_ALIGNED; {$IFDEF FPC} assembler; nostackframe; {$ENDIF}
asm
{$ifdef FPC}
  ALIGN 16
{$else}
  .ALIGN 16
{$endif}
  dd $40000000
  dd $40000000
  dd $40000000
  dd $40000000
end;

procedure SSE_RaToAlpha_Mask_ALIGNED; {$IFDEF FPC} assembler; nostackframe; {$ENDIF}
asm
{$ifdef FPC}
  ALIGN 16
{$else}
  .ALIGN 16
{$endif}
  db $80, $80, $80, $00, $80, $80, $80, $02
  db $80, $80, $80, $04, $80, $80, $80, $06
end;

procedure SSE_00000001_ALIGNED; {$IFDEF FPC} assembler; nostackframe; {$ENDIF}
asm
{$ifdef FPC}
  ALIGN 16
{$else}
  .ALIGN 16
{$endif}
  dd $00000001
  dd $00000001
  dd $00000001
  dd $00000001
end;

procedure SSE_AlphaClearMask_ALIGNED; {$IFDEF FPC} assembler; nostackframe; {$ENDIF}
asm
{$ifdef FPC}
  ALIGN 16
{$else}
  .ALIGN 16
{$endif}
   dd $00FFFFFF
   dd $00FFFFFF
   dd $00FFFFFF
   dd $00FFFFFF
end;

procedure SSE_255f_ALIGNED; {$IFDEF FPC} assembler; nostackframe; {$ENDIF}
asm
{$ifdef FPC}
  ALIGN 16
{$else}
  .ALIGN 16
{$endif}
  dd $437F0000
  dd $437F0000
  dd $437F0000
  dd $437F0000
end;

procedure SSE_Wa01_Mask_ALIGNED; {$IFDEF FPC} assembler; nostackframe; {$ENDIF}
asm
{$ifdef FPC}
  ALIGN 16
{$else}
  .ALIGN 16
{$endif}
  db $00, $80, $00, $80, $00, $80, $00, $80
  db $04, $80, $04, $80, $04, $80, $04, $80
end;

procedure SSE_AlphaLaneMask_ALIGNED; {$IFDEF FPC} assembler; nostackframe; {$ENDIF}
asm
{$ifdef FPC}
  ALIGN 16
{$else}
  .ALIGN 16
{$endif}
  dd $00000000
  dd $00000000
  dd $00000000
  dd $FFFFFFFF
end;

procedure SSE_DwordsToWords_Mask_ALIGNED; {$IFDEF FPC} assembler; nostackframe; {$ENDIF}
asm
{$ifdef FPC}
  ALIGN 16
{$else}
  .ALIGN 16
{$endif}
  db $08, $80, $08, $80, $08, $80, $08, $80
  db $0C, $80, $0C, $80, $0C, $80, $0C, $80
end;

procedure SSE_PSHUFB_R4_BYTE_MASK; {$IFDEF FPC} assembler; nostackframe; {$ENDIF}
asm
{$ifdef FPC}
  ALIGN 16
{$else}
  .ALIGN 16
{$endif}
  db 2, 6, 10, 14, $80, $80, $80, $80
  db $80, $80, $80, $80, $80, $80, $80, $80
end;

procedure SSE_PSHUFB_G4_BYTE_MASK; {$IFDEF FPC} assembler; nostackframe; {$ENDIF}
asm
{$ifdef FPC}
  ALIGN 16
{$else}
  .ALIGN 16
{$endif}
  db 1, 5, 9, 13, $80, $80, $80, $80
  db $80, $80, $80, $80, $80, $80, $80, $80
end;

procedure SSE_PSHUFB_B4_BYTE_MASK; {$IFDEF FPC} assembler; nostackframe; {$ENDIF}
asm
{$ifdef FPC}
  ALIGN 16
{$else}
  .ALIGN 16
{$endif}
  db 0, 4, 8, 12, $80, $80, $80, $80
  db $80, $80, $80, $80, $80, $80, $80, $80
end;

procedure SSE_PSHUFB_A4_BYTE_MASK; {$IFDEF FPC} assembler; nostackframe; {$ENDIF}
asm
{$ifdef FPC}
  ALIGN 16
{$else}
  .ALIGN 16
{$endif}
  db 3, 7, 11, 15, $80, $80, $80, $80
  db $80, $80, $80, $80, $80, $80, $80, $80
end;

procedure SSE_INV255_FLOAT_ALIGNED; {$IFDEF FPC} assembler; nostackframe; {$ENDIF}
asm
{$ifdef FPC}
  ALIGN 16
{$else}
  .ALIGN 16
{$endif}
  dd $3B808081
  dd $3B808081
  dd $3B808081
  dd $3B808081
end;

procedure SSE_ALPHA_MASK_ALIGNED; {$IFDEF FPC} assembler; nostackframe; {$ENDIF}
asm
  {$IFDEF FPC}
  ALIGN 16
  {$ELSE}
  .ALIGN 16
  {$ENDIF}
  dd $FF000000
  dd $FF000000
  dd $FF000000
  dd $FF000000
end;


end.

