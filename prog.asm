; -----------------------------------------------------------------------------------
;       __     _____ ____  _____ ___      __  __ _____ __  __  ___  ______   __
;       \ \   / /_ _|  _ \| ____/ _ \    |  \/  | ____|  \/  |/ _ \|  _ \ \ / /
;        \ \ / / | || | | |  _|| | | |   | |\/| |  _| | |\/| | | | | |_) \ V / 
;         \ V /  | || |_| | |__| |_| |   | |  | | |___| |  | | |_| |  _ < | |  
;          \_/  |___|____/|_____\___/    |_|  |_|_____|_|  |_|\___/|_| \_\|_|
; 
; -----------------------------------------------------------------------------------
; DESCRIPTION:	This PROTECTED MODE PROG is designed to demonstrate how graphics are
;		 drawn to the screen in REAL MODE.  An array of BYTES called 
;		 video_memory simulates the VIDEO MEMORY SEGMENT in REAL MODE that
;		 corresponds to each pixel on the screen.
;
; AUTHOR:	@kaethis

                                                                     
INCLUDE Irvine32.inc
INCLUDE Macros.inc


  _UpdateOffset MACRO sprite

	mov AH, sprite.y
	mov AL, sprite.x
	call XYtoOffset
	mov sprite.offs, EBX

  ENDM

  _SetSheet MACRO sprite, sheet

	lea ESI, sheet

	mov AL, [ESI]
	mov sprite.len, AL
	inc ESI

	mov AL, [ESI]
	mov sprite.wid, AL
	inc ESI

	mov sprite.pixels, ESI
  ENDM

  _InitSprite MACRO sprite, sheet, xCoor, yCoor

	_SetSheet sprite, sheet

	mov AL, xCoor
	mov sprite.x, AL

	mov AL, yCoor
	mov sprite.y, AL

	_UpdateOffset sprite
  ENDM


  Sprite STRUCT

	x		BYTE	?
	y		BYTE	?
	
	offs		DWORD	?

	len		BYTE	?
	wid		BYTE	?

	pixels		DWORD	?

  Sprite ENDS


.data ; _____________________________________________________________________________

  video_memory		BYTE	80 DUP (25 DUP(0))

  alien			Sprite	<>

  alien_sheet0		BYTE	8, 11
			BYTE	0,0,1,0,0,0,0,0,1,0,0
			BYTE	0,0,0,1,0,0,0,1,0,0,0
			BYTE	0,0,1,1,1,1,1,1,1,0,0 
			BYTE	0,1,1,0,1,1,1,0,1,1,0
			BYTE	1,1,1,1,1,1,1,1,1,1,1
			BYTE	1,0,1,1,1,1,1,1,1,0,1
			BYTE	1,0,1,0,0,0,0,0,1,0,1
			BYTE	0,0,0,1,1,0,1,1,0,0,0

  alien_sheet1		BYTE	8, 11
			BYTE	0,0,1,0,0,0,0,0,1,0,0
			BYTE	1,0,0,1,0,0,0,1,0,0,1
			BYTE	1,0,1,1,1,1,1,1,1,0,1
			BYTE	1,1,1,0,1,1,1,0,1,1,1
			BYTE	1,1,1,1,1,1,1,1,1,1,1
			BYTE	0,1,1,1,1,1,1,1,1,1,0
			BYTE	0,0,1,0,0,0,0,0,1,0,0
			BYTE	0,1,0,0,0,0,0,0,0,1,0

  SCREEN_MIN		=  0
  SCREENX_MAX		= 79
  SCREENY_MAX		= 24
  LINE			= 80

  KEY_UP		= 077h	; i.e, w
  KEY_DOWN		= 073h	;      s
  KEY_LEFT		= 061h  ;      a
  KEY_RIGHT		= 064h  ;      d

.code ; -----------------------------------------------------------------------------


  main PROC

    Init:
	_InitSprite alien, alien_sheet0, 3, 10


    Start:

	call CheckFrame			; Update alien Sprite sheet.

	lea ESI, alien 
	call DrawSprite			; Write alien to video_memory array.


	call DrawMem			; (Re)write contents of video_memory to
					;  console window.


	mov EAX, 100
	call Delay


	lea ESI, alien
	call ClearSprite		; Clear alien from video_memory array.


	call KeyHandler			; CALL keyboard handler for alien Sprite.

	
	jmp Start

	exit
  main ENDP


  KeyHandler PROC
  ; ---------------------------------------------------------------------------------
  ; CALL this PROC to check if a key has been pressed.  If it has, the alien Sprite
  ;  will be moved in that direction by manipulating its x- and y-coordinates.
  ; ---------------------------------------------------------------------------------

    Input:
	call ReadKey

	cmp AL, KEY_UP
	je Move_Alien_Up

	cmp AL, KEY_DOWN
	je Move_Alien_Down

	cmp AL, KEY_LEFT
	je Move_Alien_Left

	cmp AL, KEY_RIGHT
	je Move_Alien_Right

	jne Input_End			; IF no key has been pressed (or the key
					;  pressed is invalid), skip over input.

	  Move_Alien_Up:
		sub alien.y, 1
		jmp Move_Alien_End

	  Move_Alien_Down:
		add alien.y, 1
		jmp Move_Alien_End

	  Move_Alien_Left:
		sub alien.x, 1
		jmp Move_Alien_End

	  Move_Alien_Right:
		add alien.x, 1


	  Move_Alien_End:
		_UpdateOffset alien	; Since the x- or y-coodinate of the Sprite
					;  had been updated, recalculate the value
					;  of the offset.

    Input_End:

	ret
  KeyHandler ENDP


  CheckFrame PROC
  ; ---------------------------------------------------------------------------------
  ; CALL this PROC to update the sheet to use for the alien Sprite.  IF the x-coor
  ;  is EVEN, the Sprite uses alien_sheet0.  ELSE, the Sprite uses alien_sheet1.
  ; ---------------------------------------------------------------------------------

	mov AL, alien.x
	and AL, 00000001b		; Check the least-significant BIT of the
					;  x-coordinate value of the alien Sprite.

	cmp AL, 00b			;
	je Alien_Frame0			; IF 0, the x-coordinate value is EVEN.
	jne Alien_Frame1		; ELSE, the x-coor value is ODD.

	  Alien_Frame0:
		_SetSheet alien, alien_sheet0
		jmp Alien_Frame_End

	  Alien_Frame1:
		_SetSheet alien, alien_sheet1


	  Alien_Frame_End:

	ret
  CheckFrame ENDP


  DrawSprite PROC uses EDI EAX EBX ECX
  ; ---------------------------------------------------------------------------------
  ; CALL this PROC to draw a Sprite STRUCT in the video_memory array.
  ; ---------------------------------------------------------------------------------
    LOCAL address:DWORD		; The address of the location being written to in the
				;  video_memory array.
  ; ---------------------------------------------------------------------------------
  ; [RECEIVES]	- ESI : Effective address of Sprite STRUCT.

	mov EAX, (Sprite PTR [ESI]).offs
	mov address, EAX

	; Point EDI to the first BYTE in Sprite sheet.
	mov EDI, (Sprite PTR[ESI]).pixels

	movzx ECX, (Sprite PTR [ESI]).len
	  Column_Loop:

		push ECX			; Store outer-loop count.

		movzx ECX, (Sprite PTR [ESI]).wid
		  Row_Loop:

			mov AL, BYTE PTR[EDI]
			cmp AL, 0
			jz Write_End		; IF NOT 0, proceed to write.

		    Write:

			push ESI

			mov ESI,  address
			mov video_memory[ESI], AL

			pop ESI

		    Write_End:

			inc EDI
			inc address

			loop Row_Loop		

		; When reached the end of the row, proceed to next line in
		;  video_memory array:
		mov EAX, LINE
		movzx EBX, (Sprite PTR [ESI]).wid
		sub EAX, EBX
		add address, EAX

		pop ECX				; Restore outer-loop count.
		loop Column_Loop

	ret
  DrawSprite ENDP


  ClearSprite PROC uses EDI EAX EBX ECX
  ; ---------------------------------------------------------------------------------
  ; CALL this PROC to draw a Sprite STRUCT in the video_memory array.
  ; ---------------------------------------------------------------------------------
    LOCAL address:DWORD
  ; ---------------------------------------------------------------------------------
  ; [RECEIVES]	- ESI : Effective address of Sprite STRUCT.

	mov EAX, (Sprite PTR [ESI]).offs
	mov address, EAX

	mov EDI, (Sprite PTR[ESI]).pixels

	movzx ECX, (Sprite PTR [ESI]).len
	  Column_Loop:

		push ECX

		movzx ECX, (Sprite PTR [ESI]).wid
		  Row_Loop:

			mov AL, [EDI]
			cmp AL, 0
			jz Write_End

		    Write:

			push ESI

			mov ESI, address 
			mov video_memory[ESI], 0

			pop ESI

		    Write_End:

			inc EDI

			inc address 
			loop Row_Loop		

		mov EAX, LINE
		movzx EBX, (Sprite PTR [ESI]).wid
		sub EAX, EBX
		add address, EAX

		pop ECX
		loop Column_Loop

	ret
  ClearSprite ENDP


  DrawMem PROC uses ESI EAX ECX EDX
  ; ---------------------------------------------------------------------------------
  ; CALL this PROC to write the entire contents of the video_memory array to screen.
  ; ---------------------------------------------------------------------------------

	mov DH, 0
	mov DL, 0
	call GotoXY

	lea ESI, video_memory

	mov ECX, LENGTHOF video_memory
	dec ECX					; NOTE: Omit the very last BYTE in
						;	 video_memory array in order
						;	 to prevent the cursor from
						;	 proceeding beyond the last
						;	 line, causing the screen to
						;	 scroll up.
	  Write_Loop:

		movzx EAX, BYTE PTR [ESI]
		call WriteDec

		inc ESI

		loop Write_Loop

	ret
  DrawMem ENDP
  
  ClearMem PROC uses EDI ECX
  ; ---------------------------------------------------------------------------------
  ; CALL this PROC to write the entire video_memory array with zeroes, effectively
  ;  clearing the array.
  ; ---------------------------------------------------------------------------------

	mov EDI, 0

	mov ECX, LENGTHOF video_memory
	  Clear_Loop:

		cmp video_memory[EDI], 0
		jz Write_End			; IF already zero, don't overwrite.

	    Write:

		mov video_memory[ESI], 0

	    Write_End:

		inc EDI

	ret
  ClearMem ENDP


  XYtoOffset PROC uses ECX
  ; ---------------------------------------------------------------------------------
  ; CALL this PROC to calculate the offset address into the video_memory array of a
  ;  corresponding location you want to you want to draw to on the 80x25 window.
  ; ---------------------------------------------------------------------------------
  ; [RECEIVES]	-  AH: 	X-coordinate of location.
  ;		-  AL:  Y-coordinate of location.
  ; [RETURNS]	- EBX = Corresponding offset of location into video_memory array.

	mov EBX, 0

	movzx ECX, AH
	  Y_Loop:
		add EBX, LINE
		loop Y_Loop;

	movzx EAX, AL
	add EBX, EAX

	ret
  XYtoOffset ENDP


END main
