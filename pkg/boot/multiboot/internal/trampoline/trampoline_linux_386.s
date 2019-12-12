// Copyright 2018 the u-root Authors. All rights reserved
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// We want all the trampoline's assembly code to be located
// in a contiguous byte range in a compiled binary.
// Go compiler does not guarantee that. Still, current version
// of compiler puts all pieces together.
//
// This code is adapted version of "trampoline_linux_amd64.s"

#include "textflag.h"

#define MSR_EFER	0xC0000080
#define EFER_LME	0xFFFFFEFF
#define CR0_PG		0x0FFFFFFF

#define DATA_SEGMENT	0x00CF92000000FFFF
#define CODE_SEGMENT	0x00CF9A000000FFFF

#define MAGIC	0x2BADB002

// See https://www.gnu.org/software/grub/manual/multiboot/multiboot.html#Machine-state

TEXT ·start(SB),NOSPLIT,$0
	// Create GDT pointer on stack.
	LEAL	gdt(SB), CX
	SHLL	$16, CX
	ORL	$(4*8 - 1), CX
	PUSHL	CX

	LGDT	(SP)

	// Store value of multiboot info addr in BX.
	// Don't modify BX.
	MOVL	info(SB), BX

	JMP	boot(SB)

TEXT boot(SB),NOSPLIT,$0
	// Disable paging.
	MOVL	CR0, AX
	ANDL	$CR0_PG, AX
	MOVL	AX, CR0

	// Disable long mode.
	// TODO: do we still need this if we already use 386 architecture here?
	MOVL	$MSR_EFER, CX
	RDMSR
	ANDL	$EFER_LME, AX
	WRMSR

	// Disable PAE.
	XORL	AX, AX
	MOVL	AX, CR4

	// Load data segments.
	MOVL	$0x10, AX // GDT 0x10 data segment
	// Go's assembler does not allow instructions like "MOVL AX, DS" or "MOVL $0x10, DS", so:
	BYTE	$0x8e; BYTE $0xd8 // MOVL AX, DS
	BYTE	$0x8e; BYTE $0xc0 // MOVL AX, ES
	BYTE	$0x8e; BYTE $0xd0 // MOVL AX, SS
	BYTE	$0x8e; BYTE $0xe0 // MOVL AX, FS
	BYTE	$0x8e; BYTE $0xe8 // MOVL AX, GS

	MOVL	$MAGIC, AX
	JMP	entry(SB)

	// Unreachable code.
	// Need reference text labels for compiler to
	// include them to a binary.
	JMP	infotext(SB)
	JMP	entrytext(SB)


TEXT gdt(SB),NOSPLIT,$0
	QUAD	$0x0		// 0x0 null entry
	QUAD	$CODE_SEGMENT	// 0x8
	QUAD	$DATA_SEGMENT	// 0x10
	QUAD	$CODE_SEGMENT	// 0x18

TEXT infotext(SB),NOSPLIT,$0
	// u-root-info-long
	BYTE $'u'; BYTE $'-'; BYTE $'r'; BYTE $'o'; BYTE $'o';
	BYTE $'t'; BYTE $'-'; BYTE $'i'; BYTE $'n'; BYTE $'f';
	BYTE $'o'; BYTE $'-'; BYTE $'l'; BYTE $'o'; BYTE $'n';
	BYTE $'g';
TEXT info(SB),NOSPLIT,$0
	LONG	$0x0

TEXT entrytext(SB),NOSPLIT,$0
	// u-root-entry-long
	BYTE $'u'; BYTE $'-'; BYTE $'r'; BYTE $'o'; BYTE $'o';
	BYTE $'t'; BYTE $'-'; BYTE $'e'; BYTE $'n'; BYTE $'t';
	BYTE $'r'; BYTE $'y'; BYTE $'-'; BYTE $'l'; BYTE $'o';
	BYTE $'n'; BYTE $'g';
TEXT entry(SB),NOSPLIT,$0
	LONG	$0x0

TEXT ·end(SB),NOSPLIT,$0
