
element zr16.reg
element r0? : zr16.reg + 0
element r1? : zr16.reg + 1
element r2? : zr16.reg + 2
element r3? : zr16.reg + 3
element r4? : zr16.reg + 4
element r5? : zr16.reg + 5
element r6? : zr16.reg + 6
element r7? : zr16.reg + 7
element r8? : zr16.reg + 8
element r9? : zr16.reg + 9
element r10? : zr16.reg + 10
element r11? : zr16.reg + 11
element r12? : zr16.reg + 12
element r13? : zr16.reg + 13
element r14? : zr16.reg + 14
element r15? : zr16.reg + 15

element zr16.part
element p0? : zr16.part + 0
element p1? : zr16.part + 1
element p2? : zr16.part + 2
element p3? : zr16.part + 3

element io?

; JMP par regi -> 0000|00|pa|regi|0000
; JMP par (regi) -> 0000|01|pa|regi|0001
; JMP endereco10 -> 0000|10|endereco10
; Jcc endereco10 -> 0001|cc|endereco10
; CALL par regi -> 0010|00|pa|regi|0000
; CALL par (regi) -> 0010|01|pa|regi|0001
; CALL endereco10 -> 0010|10|endereco10
; RET -> 0011|0000100000|00
; RETC -> 0011|0000100000|01
; RETS -> 0011|0000100000|11
; RETZ -> 0011|0000100000|10
; MVS regi, imediato -> 0011|regi|0|imediat
; xxx = mov, add, sub, cmp, and, or, xor, rot, shl, sha
; yyy = mov, add, sub, cmp, and, or, xor
; xxx reg1, reg2 -> xxxx|0000|reg1|reg2
; xxx reg1, (reg2) -> xxxx|0001|reg1|reg2
; xxx (reg1), reg2 -> xxxx|0010|reg1|reg2
; yyy r0, imediato -> yyyy|0011|imediato
; xxx r0, (endereco) -> xxxx|0100|endereco
; xxx (reg1), (reg2) -> xxxx|0101|reg1|reg2
; xxx (r0), (endereco) -> xxxx|0110|endereco
; yyy (r0), imediato -> yyyy|0111|imediato
; xxx (endereco), r0 -> xxxx|1000|endereco
; xxx (endereco), (r0) -> xxxx|1001|endereco
; xxx io (endereco), r0 -> xxxx|1100|endereco
; xxx io r0, (endereco) -> xxxx|1101|endereco
; xxx io (reg1), reg2 -> xxxx|1110|reg1|reg2
; xxx io reg1, (reg2) -> xxxx|1111|reg1|reg2
; djnz r1234, endereco10 -> 0000|nn|endereco10 (nn=r1234-1)
; zzz = inc, dec
; zzz regi -> 1111|000z|regi|0000
; zzz (regi) -> 1111|010z|regi|0000
; zzz (endereco) -> 1111|100z|endereco
; zzz io (endereco) -> 1111|110z|endereco
; zzz io (regi) -> 1111|111z|regi|0000

macro define_jmp name, opcode
	macro name? target
		match p (register), target
			if 1 metadataof p relativeto zr16.part & 0 scaleof p = 0 & 1 metadataof register relativeto zr16.reg & 0 scaleof register = 0
				dw (opcode shl 12 + 1 shl 10 + (0 scaleof (1 metadataof p)) shl 8 + (0 scaleof (1 metadataof register)) shl 4) bswap 2
			else
				err 'argumento inválido'
			end if
		else match p register, target
			if 1 metadataof p relativeto zr16.part & 0 scaleof p = 0 & 1 metadataof register relativeto zr16.reg & 0 scaleof register = 0
				dw (opcode shl 12 + 0 shl 10 + (0 scaleof (1 metadataof p)) shl 8 + (0 scaleof (1 metadataof register)) shl 4) bswap 2
			else
				err 'argumento inválido'
			end if
		else if target relativeto 0
			assert target >= 0 & target <= 0x3ff
			dw (opcode shl 12 + 2 shl 10 + target) bswap 2
		else
			err 'argumento inválido'
		end if
	end macro
end macro

define_jmp jmp, 0000b
define_jmp call, 0010b
purge define_jcc

macro define_jcc name, code
	macro name? target
		if target relativeto 0
			assert target >= 0 & target <= 0x3ff
			dw (0001b shl 12 + code shl 10 + target) bswap 2
		else
			err 'argumento inválido'
		end if
	end macro
end macro

define_jcc jz, 0
define_jcc jnz, 1
define_jcc jc, 2
define_jcc jvp, 3
purge define_jcc

macro define_retc name, code
	macro name?
		dw (0011b shl 12 + 1 shl 7 + code) bswap 2
	end macro
end macro

define_retc ret, 0
define_retc retc, 1
define_retc rets, 3
define_retc retz, 2
purge define_retc

macro mvs? target, immediate
	if (1 metadataof target relativeto zr16.reg) & (immediate relativeto 0)
		assert immediate >= 0 & immediate <= 0x7f
		dw (0011b shl 12 + (0 scaleof (1 metadataof target)) shl 8 + immediate) bswap 2
	else
		err 'argumento inválido'
	end if
end macro

macro define_mov name, opcode
	macro name? dest, src
		match =io? dest_, dest
			match (a) (b), dest_ src
				err 'argumento inválido'
			else match (dest__), dest_
				if dest_ relativeto 0 & src relativeto r0 & 0 scaleof src = 0
					dw (opcode shl 12 + 12 shl 8 + dest_) bswap 2
				else if 1 metadataof dest__ relativeto zr16.reg & 0 scaleof dest__ = 0 & 1 metadataof src relativeto zr16.reg & 0 scaleof src = 0
					dw (opcode shl 12 + 14 shl 8 + 0 scaleof 1 metadataof dest__ shl 4 + 0 scaleof 1 metadataof src) bswap 2
				end if
			else match (src__), src
				if dest_ relativeto r0 & 0 scaleof dest_ = 0 & src__ relativeto 0
					dw (opcode shl 12 + 13 shl 8 + src__) bswap 2
				else if 1 metadataof dest_ relativeto zr16.reg & 0 scaleof dest_ = 0 & 1 metadataof src__ relativeto zr16.reg & 0 scaleof src__ = 0
					dw (opcode shl 12 + 15 shl 8 + 0 scaleof 1 metadataof dest_ shl 4 + 0 scaleof 1 metadataof src__) bswap 2
				end if
			else
				err 'argumento inválido'
			end match
		else match (dest_) (src_), dest src
			if 1 metadataof dest_ relativeto zr16.reg & 0 scaleof dest_ = 0 & 1 metadataof src_ relativeto zr16.reg & 0 scaleof src_ = 0
				dw (opcode shl 12 + 5 shl 8 + (0 scaleof (1 metadataof dest_)) shl 4 + 0 scaleof (1 metadataof src_)) bswap 2
			else if dest relativeto r0 & 0 scaleof dest = 0 & src_ relativeto 0
				assert src_ >= 0 & src_ <= 0xff
				dw (opcode shl 12 + 6 shl 8 + src_) bswap 2
			else if 1 metadataof dest_ relativeto 0 & src relativeto r0 & 0 scaleof src = 0
				assert dest_ >= 0 & dest_ <= 0xff
				dw (opcode shl 12 + 9 shl 8 + dest_) bswap 2
			else
				err 'argumento inválido'
			end if
		else match (src_), src
			if 1 metadataof dest relativeto zr16.reg & 0 scaleof dest = 0 & 1 metadataof src_ relativeto zr16.reg & 0 scaleof src_ = 0
				dw (opcode shl 12 + 1 shl 8 + (0 scaleof (1 metadataof dest)) shl 4 + 0 scaleof (1 metadataof src_)) bswap 2
			else if dest relativeto r0 & 0 scaleof dest = 0 & src_ relativeto 0
				assert src_ >= 0 & src_ <= 0xff
				dw (opcode shl 12 + 4 shl 8 + src_) bswap 2
			else
				err 'argumento inválido'
			end if
		else match (dest_), dest
			if 1 metadataof dest_ relativeto zr16.reg & 0 scaleof dest_ = 0 & 1 metadataof src relativeto zr16.reg & 0 scaleof src = 0
				dw (opcode shl 12 + 2 shl 8 + (0 scaleof (1 metadataof dest_)) shl 4 + 0 scaleof (1 metadataof src)) bswap 2
			else if dest_ relativeto r0 & 0 scaleof dest_ = 0 & 1 metadataof src relativeto 0
				assert src >= 0 & src <= 0xff
				dw (opcode shl 12 + 7 shl 8 + src) bswap 2
			else if 1 metadataof dest_ relativeto 0 & src relativeto r0 & 0 scaleof src = 0
				assert dest_ >= 0 & dest_ <= 0xff
				dw (opcode shl 12 + 8 shl 8 + dest_) bswap 2
			else
				err 'argumento inválido'
			end if
		else if 1 metadataof dest relativeto zr16.reg & 0 scaleof dest = 0 & 1 metadataof src relativeto zr16.reg & 0 scaleof src = 0
			dw (opcode shl 12 + 0 shl 8 + (0 scaleof (1 metadataof dest)) shl 4 + 0 scaleof (1 metadataof src)) bswap 2
		else if dest relativeto r0 & 0 scaleof dest = 0 & src relativeto 0
			assert src >= 0 & src <= 0xff
			dw (opcode shl 12 + 3 shl 8 + src) bswap 2
		else
			err 'argumento inválido'
		end if
	end macro
end macro

define_mov and, 0100b
define_mov or, 0101b
define_mov xor, 0110b
define_mov cmp, 0111b
define_mov add, 1000b
define_mov sub, 1001b
define_mov mov, 1101b
purge define_mov

; mesma coisa que define_mov, mas sem imediatos
macro define_shift name, opcode
	macro name? dest, src
		match =io? dest_, dest
			match (a) (b), dest_ src
				err 'argumento inválido'
			else match (dest__), dest_
				if dest_ relativeto 0 & src relativeto r0 & 0 scaleof src = 0
					dw (opcode shl 12 + 12 shl 8 + dest_) bswap 2
				else if 1 metadataof dest__ relativeto zr16.reg & 0 scaleof dest__ = 0 & 1 metadataof src relativeto zr16.reg & 0 scaleof src = 0
					dw (opcode shl 12 + 14 shl 8 + 0 scaleof 1 metadataof dest__ shl 4 + 0 scaleof 1 metadataof src) bswap 2
				end if
			else match (src__), src
				if dest_ relativeto r0 & 0 scaleof dest_ = 0 & src__ relativeto 0
					dw (opcode shl 12 + 13 shl 8 + src__) bswap 2
				else if 1 metadataof dest_ relativeto zr16.reg & 0 scaleof dest_ = 0 & 1 metadataof src__ relativeto zr16.reg & 0 scaleof src__ = 0
					dw (opcode shl 12 + 15 shl 8 + 0 scaleof 1 metadataof dest_ shl 4 + 0 scaleof 1 metadataof src__) bswap 2
				end if
			else
				err 'argumento inválido'
			end match
		else match (dest_) (src_), dest src
			if 1 metadataof dest_ relativeto zr16.reg & 0 scaleof dest_ = 0 & 1 metadataof src_ relativeto zr16.reg & 0 scaleof src_ = 0
				dw (opcode shl 12 + 5 shl 8 + (0 scaleof (1 metadataof dest_)) shl 4 + 0 scaleof (1 metadataof src_)) bswap 2
			else if dest relativeto r0 & 0 scaleof dest = 0 & src_ relativeto 0
				assert src_ >= 0 & src_ <= 0xff
				dw (opcode shl 12 + 6 shl 8 + src_) bswap 2
			else if 1 metadataof dest_ relativeto 0 & src relativeto r0 & 0 scaleof src = 0
				assert dest_ >= 0 & dest_ <= 0xff
				dw (opcode shl 12 + 9 shl 8 + dest_) bswap 2
			else
				err 'argumento inválido'
			end if
		else match (src_), src
			if 1 metadataof dest relativeto zr16.reg & 0 scaleof dest = 0 & 1 metadataof src_ relativeto zr16.reg & 0 scaleof src_ = 0
				dw (opcode shl 12 + 1 shl 8 + (0 scaleof (1 metadataof dest)) shl 4 + 0 scaleof (1 metadataof src_)) bswap 2
			else if dest relativeto r0 & 0 scaleof dest = 0 & src_ relativeto 0
				assert src_ >= 0 & src_ <= 0xff
				dw (opcode shl 12 + 4 shl 8 + src_) bswap 2
			else
				err 'argumento inválido'
			end if
		else match (dest_), dest
			if 1 metadataof dest_ relativeto zr16.reg & 0 scaleof dest_ = 0 & 1 metadataof src relativeto zr16.reg & 0 scaleof src = 0
				dw (opcode shl 12 + 2 shl 8 + (0 scaleof (1 metadataof dest_)) shl 4 + 0 scaleof (1 metadataof src)) bswap 2
			else if 1 metadataof dest_ relativeto 0 & src relativeto r0 & 0 scaleof src = 0
				assert dest_ >= 0 & dest_ <= 0xff
				dw (opcode shl 12 + 8 shl 8 + dest_) bswap 2
			else
				err 'argumento inválido'
			end if
		else if 1 metadataof dest relativeto zr16.reg & 0 scaleof dest = 0 & 1 metadataof src relativeto zr16.reg & 0 scaleof src = 0
			dw (opcode shl 12 + 0 shl 8 + (0 scaleof (1 metadataof dest)) shl 4 + 0 scaleof (1 metadataof src)) bswap 2
		else
			err 'argumento inválido'
		end if
	end macro
end macro

define_shift rot, 1010b
define_shift shl, 1011b
define_shift sha, 1100b
purge define_shift

macro djnz? reg, target
	if (reg relativeto r1 | reg relativeto r2 | reg relativeto r3 | reg relativeto r4) & 0 scaleof reg = 0 & target relativeto 0
		assert target >= 0 & target <= 0x3ff
		dw (1110b shl 12 + (0 scaleof (1 metadataof reg) - 1) shl 10 + target) bswap 2
	else
		err 'argumento inválido'
	end if
end macro

macro define_inc name, bit8
	macro name? op
		match =io? (op_), op
			if op_ relativeto 0
				assert op_ >= 0 & op_ <= 0xff
				dw (1111b shl 12 + 6 shl 9 + bit8 shl 8 + op_) bswap 2
			else if 1 metadataof op_ relativeto zr16.reg & 0 scaleof op_ = 0
				dw (1111b shl 12 + 7 shl 9 + bit8 shl 8 + (0 scaleof (1 metadataof op_)) shl 4) bswap 2
			else
				err 'argumento inválido'
			end if
		else match (op_), op
			if 1 metadataof op relativeto zr16.reg & 0 scaleof op = 0
				dw (1111b shl 12 + 2 shl 9 + bit8 shl 8 + (0 scaleof (1 metadataof op)) shl 4) bswap 2
			else if op_ relativeto 0
				assert op_ >= 0 & op_ <= 0xff
				dw (1111b shl 12 + 4 shl 9 + bit8 shl 8 + op_) bswap 2
			else
				err 'argumento inválido'
			end if
		else if 1 metadataof op relativeto zr16.reg & 0 scaleof op = 0
			dw (1111b shl 12 + 0 shl 9 + bit8 shl 8 + (0 scaleof (1 metadataof op)) shl 4) bswap 2
		else
			err 'argumento inválido'
		end if
	end macro
end macro

define_inc inc, 0
define_inc dec, 1
purge define_inc

macro org address
	db address * 2 - $ dup 0xFF
end macro
