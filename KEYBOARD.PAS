{*************************************************************************
 *
 *		Keyboard Handler for Pascal
 *		Revision 00.01.a
 *		Written by Nicholas Smith (imnes@go.com)
 *		Copyright (C) 1999, 2000; All rights reserved.
 *
 ************************************************************************}

Unit Keyboard;

Interface
	Uses
		Dos;

	Var
		Key : array[0..255] of Boolean;
		BIOS_Keyboard_Handler : Procedure;

	Const
		KEY_A 		: Byte = $1E;
		KEY_B 		: Byte = $30;
		KEY_C     : Byte = $2E;
		KEY_D 		: Byte = $20;
		KEY_E     : Byte = $12;
		KEY_F 		: Byte = $21;
		KEY_G     : Byte = $22;
		KEY_H 		: Byte = $23;
		KEY_I     : Byte = $17;
		KEY_J 		: Byte = $24;
		KEY_K     : Byte = $25;
		KEY_L 		: Byte = $26;
		KEY_M     : Byte = $32;
		KEY_N 		: Byte = $31;
		KEY_O     : Byte = $18;
		KEY_P 		: Byte = $19;
		KEY_Q     : Byte = $10;
		KEY_R 		: Byte = $13;
		KEY_S     : Byte = $1F;
		KEY_T 		: Byte = $14;
		KEY_U     : Byte = $16;
		KEY_V 		: Byte = $2F;
		KEY_W     : Byte = $11;
		KEY_X 		: Byte = $2D;
		KEY_Y     : Byte = $15;
		KEY_Z 		: Byte = $2C;

		KEY_0     : Byte = $0B;
		KEY_1 		: Byte = $02;
		KEY_2     : Byte = $03;
		KEY_3     : Byte = $04;
		KEY_4 		: Byte = $05;
		KEY_5     : Byte = $06;
		KEY_6     : Byte = $07;
		KEY_7 		: Byte = $08;
		KEY_8     : Byte = $09;
		KEY_9     : Byte = $0A;

		KEY_NP0 	: Byte = $2D;
		KEY_NP1 	: Byte = $4F;
		KEY_NP2   : Byte = $50;
		KEY_NP3   : Byte = $51;
		KEY_NP4 	: Byte = $4B;
		KEY_NP5   : Byte = $4C;
		KEY_NP6   : Byte = $4D;
		KEY_NP7 	: Byte = $47;
		KEY_NP8   : Byte = $48;
		KEY_NP9   : Byte = $49;

		KEY_NPPERIOD : Byte = $53;
		KEY_NPMINUS  : Byte = $4A;
		KEY_NPPLUS   : Byte = $4E;
		KEY_NPENTER  : Byte = $1C;

		KEY_TILDE      : Byte = $29;
		KEY_COMA       : Byte = $33;
		KEY_MINUS      : Byte = $0C;
		KEY_PERIOD     : Byte = $34;
		KEY_SLASH      : Byte = $35;
		KEY_COLON      : Byte = $27;
		KEY_EQUALS     : Byte = $0D;
		KEY_LEFTBRACE  : Byte = $1A;
		KEY_RIGHTBRACE : Byte = $1B;
		KEY_BACKSLASH  : Byte = $07;
		KEY_QUOTES     : Byte = $15;

		KEY_ESC        : Byte = $01;
		KEY_BACKSPACE  : Byte = $0E;
		KEY_TAB        : Byte = $0F;
		KEY_RETURN     : Byte = $1C;
		KEY_ENTER      : Byte = $1C;
		KEY_SPACE      : Byte = $39;

		KEY_HOME  : Byte = $47;
		KEY_END   : Byte = $4F;
		KEY_PGUP  : Byte = $49;
		KEY_PGDN  : Byte = $51;
		KEY_INS   : Byte = $52;
		KEY_DEL   : Byte = $53;

		KEY_LCTRL   : Byte = $1D;
		KEY_RCTRL   : Byte = $1D;
		KEY_LSHIFT  : Byte = $2A;
		KEY_RSHIFT  : Byte = $36;
		KEY_LALT    : Byte = $38;
		KEY_RALT    : Byte = $38;

		KEY_CAPSLOCK     : Byte = $3A;
		KEY_NUMLOCK      : Byte = $45;
		KEY_SCROLLLOCK   : Byte = $46;

		KEY_PRTSCRN   : Byte = $37;
		KEY_F1        : Byte = $3B;
		KEY_F2        : Byte = $3C;
		KEY_F3        : Byte = $3D;
		KEY_F4        : Byte = $3E;
		KEY_F5        : Byte = $3F;
		KEY_F6        : Byte = $40;
		KEY_F7        : Byte = $41;
		KEY_F8        : Byte = $42;
		KEY_F9        : Byte = $43;
		KEY_F10       : Byte = $44;
		KEY_F11       : Byte = $57;
		KEY_F12       : Byte = $58;

		KEY_UP		: Byte = $48;
		KEY_DOWN	: Byte = $50;
		KEY_LEFT  : Byte = $4B;
		KEY_RIGHT : Byte = $4D;


	Procedure CreateKeyboard;
	Procedure DestroyKeyboard;
	Procedure KeyboardHandler; Interrupt;

Implementation

{*************************************************************************
 *
 *		Setup our custom keyboard handler.
 *
 ************************************************************************}
Procedure CreateKeyboard;
Begin
	{Save the pointer to the current BIOS keyboard handler.}
		GetIntVec(9, @BIOS_Keyboard_Handler);

	{Replace it with ours.}
		SetIntVec(9, Addr(KeyboardHandler));
End;


{*************************************************************************
 *
 *		Give control back to the BIOS.
 *
 ************************************************************************}
Procedure DestroyKeyboard;
Begin
	{Return keyboard control to the BIOS.}
		SetIntVec(9, @BIOS_Keyboard_Handler);
End;


{*************************************************************************
 *
 *		My custom keyboard handler code.
 *
 ************************************************************************}
{$F+}
Procedure KeyboardHandler;
Var
	KeyCode: Byte;
Begin
	KeyCode:=port[$60];	{ Retrieve the scan code }
	port[$20]:=$20;			{ Send EOI }

	if KeyCode > $80 then	{ Is bit 7 set? }
	 begin
		key[KeyCode-$80] := False;
	 end
	else
	 begin
		key[KeyCode] := True;
	 end;

End;
{$F-}



{*************************************************************************
 *
 *		Main unit init code.
 *
 ************************************************************************}
Begin
	{Tell the operator that we're loading.}
		Write('Adding Module: Keyboard Extensions...');

	{Init code here}
		{...}

	{And we're successful!}
		WriteLn('okay');
End.