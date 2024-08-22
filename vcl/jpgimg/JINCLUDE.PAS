Unit jinclude;

{ This file exists to provide a single place to fix any problems with
  including the wrong system include files.  (Common problems are taken
  care of by the standard jconfig symbols, but on really weird systems
  you may have to edit this file.)

  NOTE: this file is NOT intended to be included by applications using the
  JPEG library.  Most applications need only include jpeglib.h. }

{ Original: jinclude.h Copyright (C) 1991-1994, Thomas G. Lane. }

(*@/// interface *)
interface

{$I jconfig.inc}

{ Include auto-config file to find out which system include files we need. }

(*@/// uses *)
uses
  Classes, jmorecfg;
(*@\\\*)

{ We need the NULL macro and size_t typedef.
  On an ANSI-conforming system it is sufficient to include <stddef.h>.
  Otherwise, we get them from <stdlib.h> or <stdio.h>; we may have to
  pull in <sys/types.h> as well.
  Note that the core JPEG library does not require <stdio.h>;
  only the default error handler and data source/destination modules do.
  But we must pull it in because of the references to FILE in jpeglib.h.
  You can remove those references if you want to compile without <stdio.h>.}



{ We need memory copying and zeroing functions, plus strncpy().
  ANSI and System V implementations declare these in <string.h>.
  BSD doesn't have the mem() functions, but it does have bcopy()/bzero().
  Some systems may declare memset and memcpy in <memory.h>.

  NOTE: we assume the size parameters to these functions are of type size_t.
  Change the casts in these macros if not! }

procedure MEMZERO(target : pointer; size : size_t);
procedure MEMCOPY(dest, src : pointer; size : size_t);
{function SIZEOF(object) : size_t;}
function JFREAD(stream:TStream; buf : pointer; sizeofbuf : size_t) : size_t;
function JFMWRITE(var f : TStream; buf : pointer; sizeofbuf : size_t) : size_t;
(*@\\\003200200A002012002001002001*)
(*@/// implementation *)
implementation

(*@/// procedure MEMZERO(target : pointer; size : size_t); *)
procedure MEMZERO(target : pointer; size : size_t);
begin
  FillChar(target^, size, 0);
end;
(*@\\\*)
(*@/// procedure MEMCOPY(dest, src : pointer; size : size_t); *)
procedure MEMCOPY(dest, src : pointer; size : size_t);
begin
  Move(src^, dest^, size);
end;
(*@\\\*)

{ In ANSI C, and indeed any rational implementation, size_t is also the
  type returned by sizeof().  However, it seems there are some irrational
  implementations out there, in which sizeof() returns an int even though
  size_t is defined as long or unsigned long.  To ensure consistent results
  we always use this SIZEOF() macro in place of using sizeof() directly. }

{#define
  SIZEOF(object)  (size_t(sizeof(object))}

{ The modules that use fread() and fwrite() always invoke them through
  these macros.  On some systems you may need to twiddle the argument casts.
  CAUTION: argument order is different from underlying functions! }


(*@/// function JFREAD(stream:TStream; buf : pointer; sizeofbuf : size_t) : size_t; *)
function JFREAD(stream:TStream; buf : pointer; sizeofbuf : size_t) : size_t;
var
  count : uint;
begin
  count:=stream.Read(buf^, sizeofbuf);
{   blockread(f, buf^, sizeofbuf, count); }
  JFREAD := size_t(count);
end;
(*@\\\*)
(*@/// function JFMWRITE(var f : TStream; buf : pointer; sizeofbuf : size_t) : size_t; *)
function JFMWRITE(var f : TStream; buf : pointer; sizeofbuf : size_t) : size_t;
var
  count : uint;
begin
  count := f.Write(buf^, sizeofbuf);
  JFMWRITE := size_t(count);
end;
(*@\\\000000011C*)
(*@\\\000000151C*)
end.


(*@\\\000D001101001101000011000D01*)
