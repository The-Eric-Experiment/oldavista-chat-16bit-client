Unit JFDctInt;


{ This file contains a slow-but-accurate integer implementation of the
  forward DCT (Discrete Cosine Transform).

  A 2-D DCT can be done by 1-D DCT on each row followed by 1-D DCT
  on each column.  Direct algorithms are also available, but they are
  much more complex and seem not to be any faster when reduced to code.

  This implementation is based on an algorithm described in
    C. Loeffler, A. Ligtenberg and G. Moschytz, "Practical Fast 1-D DCT
    Algorithms with 11 Multiplications", Proc. Int'l. Conf. on Acoustics,
    Speech, and Signal Processing 1989 (ICASSP '89), pp. 988-991.
  The primary algorithm described there uses 11 multiplies and 29 adds.
  We use their alternate method with 12 multiplies and 32 adds.
  The advantage of this method is that no data path contains more than one
  multiplication; this allows a very simple and accurate implementation in
  scaled fixed-point arithmetic, with a minimal number of shifts. }

{ Original : jfdctint.c ; Copyright (C) 1991-1996, Thomas G. Lane. }

interface

{$I jconfig.inc}

uses
  jmorecfg,
  jinclude,
  jutils,
  jpeglib,
  jdct;		{ Private declarations for DCT subsystem }


{ Perform the forward DCT on one block of samples. }

{GLOBAL}
procedure jpeg_fdct_islow (var data : array of DCTELEM);

implementation

{ This module is specialized to the case DCTSIZE = 8. }

{$ifdef DCTSIZE != 8}
  Sorry, this code only copes with 8x8 DCTs. { deliberate syntax err }
{$endif}


{ The poop on this scaling stuff is as follows:

  Each 1-D DCT step produces outputs which are a factor of sqrt(N)
  larger than the true DCT outputs.  The final outputs are therefore
  a factor of N larger than desired; since N=8 this can be cured by
  a simple right shift at the end of the algorithm.  The advantage of
  this arrangement is that we save two multiplications per 1-D DCT,
  because the y0 and y4 outputs need not be divided by sqrt(N).
  In the IJG code, this factor of 8 is removed by the quantization step
  (in jcdctmgr.c), NOT in this module.

  We have to do addition and subtraction of the integer inputs, which
  is no problem, and multiplication by fractional constants, which is
  a problem to do in integer arithmetic.  We multiply all the constants
  by CONST_SCALE and convert them to integer constants (thus retaining
  CONST_BITS bits of precision in the constants).  After doing a
  multiplication we have to divide the product by CONST_SCALE, with proper
  rounding, to produce the correct output.  This division can be done
  cheaply as a right shift of CONST_BITS bits.  We postpone shifting
  as long as possible so that partial sums can be added together with
  full fractional precision.

  The outputs of the first pass are scaled up by PASS1_BITS bits so that
  they are represented to better-than-integral precision.  These outputs
  require BITS_IN_JSAMPLE + PASS1_BITS + 3 bits; this fits in a 16-bit word
  with the recommended scaling.  (For 12-bit sample data, the intermediate
  array is INT32 anyway.)

  To avoid overflow of the 32-bit intermediate results in pass 2, we must
  have BITS_IN_JSAMPLE + CONST_BITS + PASS1_BITS <= 26.  Error analysis
  shows that the values given below are the most effective. }

{$ifdef BITS_IN_JSAMPLE_IS_8}
const
  CONST_BITS = 13;
  PASS1_BITS = 2;
{$else}
const
  CONST_BITS = 13;
  PASS1_BITS = 1;	{ lose a little precision to avoid overflow }
{$endif}

const
  ONE   = INT32(1);
  CONST_SCALE = (ONE shl CONST_BITS);

const
  FIX_0_298631336 = INT32(Round(CONST_SCALE * 0.298631336));  {2446}
  FIX_0_390180644 = INT32(Round(CONST_SCALE * 0.390180644));  {3196}
  FIX_0_541196100 = INT32(Round(CONST_SCALE * 0.541196100));  {4433}
  FIX_0_765366865 = INT32(Round(CONST_SCALE * 0.765366865));  {6270}
  FIX_0_899976223 = INT32(Round(CONST_SCALE * 0.899976223));  {7373}
  FIX_1_175875602 = INT32(Round(CONST_SCALE * 1.175875602));  {9633}
  FIX_1_501321110 = INT32(Round(CONST_SCALE * 1.501321110));  {12299}
  FIX_1_847759065 = INT32(Round(CONST_SCALE * 1.847759065));  {15137}
  FIX_1_961570560 = INT32(Round(CONST_SCALE * 1.961570560));  {16069}
  FIX_2_053119869 = INT32(Round(CONST_SCALE * 2.053119869));  {16819}
  FIX_2_562915447 = INT32(Round(CONST_SCALE * 2.562915447));  {20995}
  FIX_3_072711026 = INT32(Round(CONST_SCALE * 3.072711026));  {25172}


{ Multiply an INT32 variable by an INT32 constant to yield an INT32 result.
  For 8-bit samples with the recommended scaling, all the variable
  and constant values involved are no more than 16 bits wide, so a
  16x16->32 bit multiply can be used instead of a full 32x32 multiply.
  For 12-bit samples, a full 32-bit multiplication will be needed. }

{$ifdef BITS_IN_JSAMPLE_IS_8}

   {MULTIPLY16C16(var,const)}
   function Multiply(X, Y: int): INT32;
   begin
     Multiply := int(X) * INT32(Y);
   end;

{$else}
#define MULTIPLY(var,const)  ((var) * (const))
{$endif}

{ Descale and correctly round an INT32 value that's scaled by N bits.
  We assume RIGHT_SHIFT rounds towards minus infinity, so adding
  the fudge factor is correct for either sign of X. }

function DESCALE(x : INT32; n : int) : INT32;
var
  shift_temp : INT32;
begin
{$ifdef RIGHT_SHIFT_IS_UNSIGNED}
  shift_temp := x + (ONE shl (n-1));
  if shift_temp < 0 then
    Descale :=  (shift_temp shr n) or ((not INT32(0)) shl (32-n))
  else
    Descale :=  (shift_temp shr n);
{$else}
  Descale := (x + (ONE shl (n-1)) shr n;
{$endif}
end;


{ Perform the forward DCT on one block of samples. }

{GLOBAL}
procedure jpeg_fdct_islow (var data : array of DCTELEM);
type
  PWorkspace = ^TWorkspace;
  TWorkspace = array [0..DCTSIZE2-1] of DCTELEM;
var
  tmp0, tmp1, tmp2, tmp3, tmp4, tmp5, tmp6, tmp7 : INT32;
  tmp10, tmp11, tmp12, tmp13 : INT32;
  z1, z2, z3, z4, z5 : INT32;
  dataptr : PWorkspace;
  ctr : int;
  {SHIFT_TEMPS}
begin

  { Pass 1: process rows. }
  { Note results are scaled up by sqrt(8) compared to a true DCT; }
  { furthermore, we scale the results by 2**PASS1_BITS. }

  dataptr := PWorkspace(@data);
  for ctr := DCTSIZE-1 downto 0 do
  begin
    tmp0 := dataptr^[0] + dataptr^[7];
    tmp7 := dataptr^[0] - dataptr^[7];
    tmp1 := dataptr^[1] + dataptr^[6];
    tmp6 := dataptr^[1] - dataptr^[6];
    tmp2 := dataptr^[2] + dataptr^[5];
    tmp5 := dataptr^[2] - dataptr^[5];
    tmp3 := dataptr^[3] + dataptr^[4];
    tmp4 := dataptr^[3] - dataptr^[4];

    { Even part per LL&M figure 1 --- note that published figure is faulty;
      rotator "sqrt(2)*c1" should be "sqrt(2)*c6".  }

    tmp10 := tmp0 + tmp3;
    tmp13 := tmp0 - tmp3;
    tmp11 := tmp1 + tmp2;
    tmp12 := tmp1 - tmp2;

    dataptr^[0] := DCTELEM ((tmp10 + tmp11) shl PASS1_BITS);
    dataptr^[4] := DCTELEM ((tmp10 - tmp11) shl PASS1_BITS);

    z1 := MULTIPLY(tmp12 + tmp13, FIX_0_541196100);
    dataptr^[2] := DCTELEM (DESCALE(z1 + MULTIPLY(tmp13, FIX_0_765366865),
				   CONST_BITS-PASS1_BITS));
    dataptr^[6] := DCTELEM (DESCALE(z1 + MULTIPLY(tmp12, - FIX_1_847759065),
				   CONST_BITS-PASS1_BITS));

    { Odd part per figure 8 --- note paper omits factor of sqrt(2).
      cK represents cos(K*pi/16).
      i0..i3 in the paper are tmp4..tmp7 here. }

    z1 := tmp4 + tmp7;
    z2 := tmp5 + tmp6;
    z3 := tmp4 + tmp6;
    z4 := tmp5 + tmp7;
    z5 := MULTIPLY(z3 + z4, FIX_1_175875602); { sqrt(2) * c3 }

    tmp4 := MULTIPLY(tmp4, FIX_0_298631336); { sqrt(2) * (-c1+c3+c5-c7) }
    tmp5 := MULTIPLY(tmp5, FIX_2_053119869); { sqrt(2) * ( c1+c3-c5+c7) }
    tmp6 := MULTIPLY(tmp6, FIX_3_072711026); { sqrt(2) * ( c1+c3+c5-c7) }
    tmp7 := MULTIPLY(tmp7, FIX_1_501321110); { sqrt(2) * ( c1+c3-c5-c7) }
    z1 := MULTIPLY(z1, - FIX_0_899976223); { sqrt(2) * (c7-c3) }
    z2 := MULTIPLY(z2, - FIX_2_562915447); { sqrt(2) * (-c1-c3) }
    z3 := MULTIPLY(z3, - FIX_1_961570560); { sqrt(2) * (-c3-c5) }
    z4 := MULTIPLY(z4, - FIX_0_390180644); { sqrt(2) * (c5-c3) }

    Inc(z3, z5);
    Inc(z4, z5);

    dataptr^[7] := DCTELEM(DESCALE(tmp4 + z1 + z3, CONST_BITS-PASS1_BITS));
    dataptr^[5] := DCTELEM(DESCALE(tmp5 + z2 + z4, CONST_BITS-PASS1_BITS));
    dataptr^[3] := DCTELEM(DESCALE(tmp6 + z2 + z3, CONST_BITS-PASS1_BITS));
    dataptr^[1] := DCTELEM(DESCALE(tmp7 + z1 + z4, CONST_BITS-PASS1_BITS));

    Inc(DCTELEMPTR(dataptr), DCTSIZE);	{ advance pointer to next row }
  end;

  { Pass 2: process columns.
    We remove the PASS1_BITS scaling, but leave the results scaled up
    by an overall factor of 8. }

  dataptr := PWorkspace(@data);
  for ctr := DCTSIZE-1 downto 0 do
  begin
    tmp0 := dataptr^[DCTSIZE*0] + dataptr^[DCTSIZE*7];
    tmp7 := dataptr^[DCTSIZE*0] - dataptr^[DCTSIZE*7];
    tmp1 := dataptr^[DCTSIZE*1] + dataptr^[DCTSIZE*6];
    tmp6 := dataptr^[DCTSIZE*1] - dataptr^[DCTSIZE*6];
    tmp2 := dataptr^[DCTSIZE*2] + dataptr^[DCTSIZE*5];
    tmp5 := dataptr^[DCTSIZE*2] - dataptr^[DCTSIZE*5];
    tmp3 := dataptr^[DCTSIZE*3] + dataptr^[DCTSIZE*4];
    tmp4 := dataptr^[DCTSIZE*3] - dataptr^[DCTSIZE*4];

    { Even part per LL&M figure 1 --- note that published figure is faulty;
      rotator "sqrt(2)*c1" should be "sqrt(2)*c6". }

    tmp10 := tmp0 + tmp3;
    tmp13 := tmp0 - tmp3;
    tmp11 := tmp1 + tmp2;
    tmp12 := tmp1 - tmp2;

    dataptr^[DCTSIZE*0] := DCTELEM (DESCALE(tmp10 + tmp11, PASS1_BITS));
    dataptr^[DCTSIZE*4] := DCTELEM (DESCALE(tmp10 - tmp11, PASS1_BITS));

    z1 := MULTIPLY(tmp12 + tmp13, FIX_0_541196100);
    dataptr^[DCTSIZE*2] := DCTELEM (DESCALE(z1 + MULTIPLY(tmp13, FIX_0_765366865),
					   CONST_BITS+PASS1_BITS));
    dataptr^[DCTSIZE*6] := DCTELEM (DESCALE(z1 + MULTIPLY(tmp12, - FIX_1_847759065),
					   CONST_BITS+PASS1_BITS));

    { Odd part per figure 8 --- note paper omits factor of sqrt(2).
      cK represents cos(K*pi/16).
      i0..i3 in the paper are tmp4..tmp7 here. }
    
    z1 := tmp4 + tmp7;
    z2 := tmp5 + tmp6;
    z3 := tmp4 + tmp6;
    z4 := tmp5 + tmp7;
    z5 := MULTIPLY(z3 + z4, FIX_1_175875602); { sqrt(2) * c3 }

    tmp4 := MULTIPLY(tmp4, FIX_0_298631336); { sqrt(2) * (-c1+c3+c5-c7) }
    tmp5 := MULTIPLY(tmp5, FIX_2_053119869); { sqrt(2) * ( c1+c3-c5+c7) }
    tmp6 := MULTIPLY(tmp6, FIX_3_072711026); { sqrt(2) * ( c1+c3+c5-c7) }
    tmp7 := MULTIPLY(tmp7, FIX_1_501321110); { sqrt(2) * ( c1+c3-c5-c7) }
    z1 := MULTIPLY(z1, - FIX_0_899976223); { sqrt(2) * (c7-c3) }
    z2 := MULTIPLY(z2, - FIX_2_562915447); { sqrt(2) * (-c1-c3) }
    z3 := MULTIPLY(z3, - FIX_1_961570560); { sqrt(2) * (-c3-c5) }
    z4 := MULTIPLY(z4, - FIX_0_390180644); { sqrt(2) * (c5-c3) }

    Inc(z3, z5);
    Inc(z4, z5);

    dataptr^[DCTSIZE*7] := DCTELEM (DESCALE(tmp4 + z1 + z3,
					   CONST_BITS+PASS1_BITS));
    dataptr^[DCTSIZE*5] := DCTELEM (DESCALE(tmp5 + z2 + z4,
					   CONST_BITS+PASS1_BITS));
    dataptr^[DCTSIZE*3] := DCTELEM (DESCALE(tmp6 + z2 + z3,
					   CONST_BITS+PASS1_BITS));
    dataptr^[DCTSIZE*1] := DCTELEM (DESCALE(tmp7 + z1 + z4,
					   CONST_BITS+PASS1_BITS));

    Inc(DCTELEMPTR(dataptr));	{ advance pointer to next column }
  end;
end;

end.
