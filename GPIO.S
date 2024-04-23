.ifndef GPIO_S
.set GPIO_S, 1


# This file contains all additonal information needed for our robomal program
# contains both readPMODB and writePMODB, more can be added if needed just a
# included file in our robot program

# Created by Dr. Murray / Artem Labanau

@ Base address for our MIO address space
@ We care about DATA_2, DATA_2_RO, DIR_2, and OE_2
@ Which have offsets #0x48, #0x68, #0x284, #0x288 from the base address respectively
.set MIO_BASE_ADDR, 0xE000A000

@ Our bitmasks for the top and bottom pins of PMODB
.set PMODB_TOP_MASK, 0x0780 	@ top pin information is in bits 7,8,9,10 of the above registers
.set PMODB_BOTTOM_MASK, 0x7800  @ bottom pin information is in bits 11,12,13,14 of the above registers

# LEDS address for the robot control simulation
# addresses for the svn seg, buttons and switches
.set BUTTONS, 0x41200000
.set SWITCHES, 0x41220000
.set SVNSEG, 0x43C10000
.set LEDS, 0x41210000

.data
# jump table for array reference to correct number on keypad
numbers: .byte 0, 7, 4, 1, 0xF, 8, 5, 2, 0xE, 9, 6, 3, 0xD, 0xC, 0xB, 0xA, 0

.text

@ Compare these functions to the examples of the C versions that I did in class...
@ See how we converted / deconstructed the lines of code from C to ARM.

@ row = 0 means PMODB top row, row = 1 means PMODB bottom row
@ inout = 1 means that row is output, inout = 0 means that row is input
@ Our choice of register to use for input parameters is somewhat arbitrary as long as it matches when we call our function.
@ unsigned int inout == r1, unsigned int row == r2
setupPMODB:
	@ if (row == 0)
	LDR r3, =MIO_BASE_ADDR
	CMP r2, #0
	BNE setupRowTrue
	setupRowFalse: @ row = 0
		@ if (inout == 0)
		LDR r5, =PMODB_TOP_MASK
		CMP r1, #0
		BNE setupRowFalseInoutTrue
		setupRowFalseInoutFalse: @ row = 0, inout = 0
			LDR r4, [r3, #0x284]		@ r4 = DIR_2
			MVN r5, r5					@ ~PMODB_TOP_MASK
			AND r6, r4, r5				@ DIR_2 & ~PMODB_TOP_MASK
			STR r6, [r3, #0x284]		@ DIR_2 = DIR_2 & ~PMODB_TOP_MASK
			LDR r4, [r3, #0x288]		@ r4 = OE_2
			AND r6, r4, r5				@ OE_2 & ~PMODB_TOP_MASK
			STR r6, [r3, #0x288]		@ OE_2 = OE_2 & ~PMODB_TOP_MASK
		B endSetupPMOD
		setupRowFalseInoutTrue: @ row = 0, inout = 1
			LDR r4, [r3, #0x284]		@ r4 = DIR_2
			ORR r6, r4, r5				@ DIR_2 | PMODB_TOP_MASK
			STR r6, [r3, #0x284]		@ DIR_2 = DIR_2 | PMODB_TOP_MASK
			LDR r4, [r3, #0x288]		@ r4 = OE_2
			ORR r6, r4, r5				@ OE_2 | PMODB_TOP_MASK
			STR r6, [r3, #0x288]		@ OE_2 = OE_2 | PMODB_TOP_MASK
		B endSetupPMOD
	setupRowTrue: @ row = 1
		// @ (inout == 0)
		LDR r5, =PMODB_BOTTOM_MASK
		CMP r1, #0
		BNE setupRowTrueInoutTrue
		setupRowTrueInoutFalse: @ row = 1, inout = 0
			LDR r4, [r3, #0x284]		@ r4 = DIR_2
			MVN r5, r5					@ ~PMODB_BOTTOM_MASK
			AND r6, r4, r5				@ DIR_2 & ~PMODB_BOTTOM_MASK
			STR r6, [r3, #0x284]		@ DIR_2 = DIR_2 & ~PMODB_BOTTOM_MASK
			LDR r4, [r3, #0x288]		@ r4 = OE_2
			AND r6, r4, r5				@ OE_2 & ~PMODB_BOTTOM_MASK
			STR r6, [r3, #0x288]		@ OE_2 = OE_2 & ~PMODB_BOTTOM_MASK
		B endSetupPMOD
		setupRowTrueInoutTrue: @ row = 1, inout = 1
			LDR r4, [r3, #0x284]		@ r4 = DIR_2
			ORR r6, r4, r5				@ DIR_2 | PMODB_BOTTOM_MASK
			STR r6, [r3, #0x284]		@ DIR_2 = DIR_2 | PMODB_BOTTOM_MASK
			LDR r4, [r3, #0x288]		@ r4 = OE_2
			ORR r6, r4, r5				@ OE_2 | PMODB_BOTTOM_MASK
			STR r6, [r3, #0x288]		@ OE_2 = OE_2 | PMODB_BOTTOM_MASK

		endSetupPMOD:
			BX LR


# row = 0 means PMODB top row, row = 1 means PMODB bottom row
# unsigned int that is returned from the function == r0, unsigned int row == r1
readPMODB:

	PUSH {r3, r4, r5, r6, LR}

	LDR r3, =MIO_BASE_ADDR
	CMP r1, #0
	BNE readRowTrue
	readRowFalse:	@ row = 0
	LDR r4, =PMODB_TOP_MASK	@ r4 = PMODB_TOP_MASK
	LDR r5, [r3, #0x68]		@ r5 = DATA_2_RO
	AND r6, r5, r4			@ r6 = PMODB_TOP_MASK & DATA_2_RO
	LSR r0, r6, #7			@ r0 = (PMODB_TOP_MASK & DATA_2_RO) >> 7

	B endReadPMODB
	readRowTrue: @ row =1
	LDR r4, =PMODB_BOTTOM_MASK	@ r4 = PMODB_BOTTOM_MASK
	LDR r5, [r3, #0x68]			@ r5 = DATA_2_RO
	AND r6, r5, r4				@ r6 = PMODB_BOTTOM_MASK & DATA_2_RO
	LSR r0, r6, #11				@ r0 = (PMODB_BOTTOM_MASK & DATA_2_RO) >> 11

	endReadPMODB:
	POP {r3, r4, r5, r6, LR}
	BX LR


# row = 0 means PMODB top row, row = 1 means PMODB bottom row
# unsigned int value == r1, unsigned int row == r2
writePMODB:

	PUSH {r2-r9, LR}

	LDR r3, =MIO_BASE_ADDR
	CMP r2, #0
	BNE writeRowTrue

	writeRowFalse: @ row = 0
	LDR r4, =PMODB_TOP_MASK
	MVN r5, r4				@ r5 = ~PMODB_TOP_MASK
	LDR r6, [r3, #0x48]		@ r6 = DATA_2
	AND r7, r6, r5			@ r7 = DATA_2 & ~PMODB_TOP_MASK
	AND r8, r4, r1, LSL #7  @ r8 = PMODB_TOP_MASK & (value << 7)
	ORR r9, r7, r8			@ r9 = (DATA_2 & ~PMODB_TOP_MASK) | (PMODB_TOP_MASK & (value << 7))
	STR r9, [r3, #0x48]		@ DATA_2 = r9

	B endWritePMODB
	writeRowTrue: @ row = 1
	LDR r4, =PMODB_BOTTOM_MASK
	MVN r5, r4				@ r5 = ~PMODB_BOTTOM_MASK
	LDR r6, [r3, #0x48]		@ r6 = DATA_2
	AND r7, r6, r5			@ r7 = DATA_2 & ~PMODB_BOTTOM_MASK
	AND r8, r4, r1, LSL #11 @ r8 = PMODB_BOTTOM_MASK & (value << 11)
	ORR r9, r7, r8			@ r9 = (DATA_2 & ~PMODB_BOTTOM_MASK) | (PMODB_BOTTOM_MASK & (value << 11))
	STR r9, [r3, #0x48]		@ DATA_2 = r9


	endWritePMODB:
	POP {r2-r9, LR}
	BX LR


# get_keypad_data takes the input from the the keypad by turning on the columns
# and reading the rows for an input then stores it.
# output is stored in r0
get_keypad_data:

# the preserve these register values and only use them inside the function
PUSH {r1, r2, r3, r5, r6, LR}

# initalizing the registers
	# r5 = i for the for loop
	MOV r5, #0

	# temp variable
	MOV r3, #0

	# needed for line 174 for logic shift immediate issue
	MOV r6, #0b0001


# for loop, 0 to 4 which writes to the columns and reads the rows.
# returns r0
	loop:

		CMP r5, #4
		BGE loopend

		# writing to the columns
		MVN r1, r6, LSL r5
		MOV r2, #0
		BL writePMODB

		# timer for delay
		BL timer_calc

		# reading the rows
		MOV r3, r3, LSL #4
		MOV r1, #1
		BL readPMODB
		ORR r3,r3,r0

		# i++
		ADD r5, r5, #1
		B loop

	 loopend:
	 MOV r0, r3


	end_get_keypad_data:
	POP {r1, r2, r3, r5, r6, LR}
	BX LR


# unsigned int display_keypad();
# Takes the keypad data, then checks for a key to be pressed. Then checks where the
# key is pressed and then references the array to output the correct number to the
# seven segment display.
display_keypad:

	# registers needed to be presereved.
	PUSH {r1, r2, r3, r4, r5, r6, r7, LR}

	MOV r7, #0xFFFF

	# wait for a button press on keypad while loops
	while:
		BL get_keypad_data
		CMP r0, r7
		BGE while

		MOV r1, r0

	while2:
		BL get_keypad_data
		CMP r0, r7
		BLT while2

	MOV r0, r1

	# loop iteriator
	MOV r4, #0

	# counter
	MOV r5, #0

	MVN r0, r0
	AND r0, r0, r7

	# This for loop checks which bit inside the r0 register has the button press
	# by counting the bits and right shifting though r0 register
	loop2:

		CMP r4, #16
		BGE loop2end


		CMP r0, #1
		BEQ loop2end
		MOV r0, r0, LSR #1

		ADD r4, r4, #1
		ADD r5, r5, #1

		B loop2

	loop2end:

	# Here the array is refereneced and the output is pushed to the writeSVNSEG for output
	LDR r6, =numbers
	LDRB r1, [r6, r5]
	BL writeSVNSEG
	MOV r0, r1

	end_display_keypad:
	POP {r1, r2, r3, r4, r5, r6, r7, LR}
	BX LR


# Turns on seven segment display
setupSVNSEG:

	PUSH {r0, r1}

	LDR r0, =SVNSEG
	MOV r1, #0b01

	STR r1, [r0]

	POP {r0, r1}
	BX LR


# display to seven segment display function
# assume data is in r1
# Essentially we want to output our command to the seven segment screen
writeSVNSEG:
	# *(unsigned int *SVNSEG +1) = data;

	# IN ANY FUNCTION THAT CALLS ANOTHER FUNCTION
	# WE MUST PRESERVE THE LR
	PUSH {r1, LR}

	BL formatSVNSEGdata
	MOV r1, r0

	# r0 = 0x43C10000
	LDR r0, =SVNSEG

	# Writing data to address 0x43C10000
	STR r1, [r0, #0x04]

	POP {r1, LR}

	BX LR


# Creating a function to format a raw 16-bit number
# wwwwxxxxyyyyzzzz
# to 0b????wwww????xxxx????yyyy????zzzz
# unsigned int formatSVNSEGdata(unsigned int data)
# This takes a raw number and outputs a 4 digit number to the seven segment display
# By masking and shifiting it to the correct place
# assume that we return the formatted value in r0
formatSVNSEGdata:

	# r0 = ????????????zzzz
	# r0 = r1 & 0xF
	AND r0, r1, #0xF

	# r0 = ????????yyyyzzzz
	# r0 = r0 | ((r1 & 0xF0) << 4)

	#((r1 & 0xF0) << 4)
	AND r2, r1, #0xF0
	ORR r0, r0, r2, LSL #4

	#((r1 & 0xF0) << 8)
	AND r2, r1, #0xF00
	ORR r0, r0, r2, LSL #8

	#((r1 & 0xF0) << 12)
	AND r2, r1, #0xF000
	ORR r0, r0, r2, LSL #12

	BX LR


# Switches Button
# returns r0
get_switches:
	LDR r0, =SWITCHES
	LDR r1, [r0]
	MOV r2, #0xFFF
	AND r0, r1, r2
	BX lr

# Buttons function
# returns r0
get_buttons:
	LDR r0, =BUTTONS
	LDR r1, [r0]
	AND r0, r1, #0xF
	BX lr


	# Basically usleep() function that gives an artifical delay between writing and reading.
timer:
	PUSH {r7}
	LDR r7, =#0xFFFFFFF

	innertimerloop:

	CMP r7, #0
	BEQ timer_end

	SUB r7, r7, #1
	B innertimerloop

	timer_end:
	POP {r7}
	BX LR

timer_calc:
	PUSH {r7}
	LDR r7, =#0xFFFF

	timerloop:

	CMP r7, #0
	BEQ timerend

	SUB r7, r7, #1
	B timerloop

	timerend:
	POP {r7}
	BX LR

# converts hex input to ascii ouput, hex input is in r0, output in r1
convert_ascii:
	#input is in r0

	CMP r0, #0x9
	BLE Hex
	ADD r0, r0, #0x37
	B end_ascii

	Hex:
	ADD r0, r0, #0x30

	end_ascii:
	# the ascii character is in r0

BX lr

convert_hex:
	#input is in r0

	CMP r0, #'9'
	BLE convert1
	SUB r0, r0, #0x37
	B end_convert

	convert1:
	SUB r0, r0, #0x30

	end_convert:
	# the ascii character is in r0

BX lr


button_wait:
PUSH {LR}

	# in r0
	check_button:
	BL get_buttons
	CMP r0, #0
	BNE end_button
	B check_button

	end_button:
	POP {LR}

BX LR


	#keypad_char:
	#PUSH {r1,r2,r4,LR}

		# Getting the keypad data from the keypad
		# setting up seven segment display
		#BL setupSVNSEG

		#MOV r4, #0
		#MOV r2, #0

		#number:
		#CMP r4, #4
		#BEQ end_number

		#LSL r2, #4

		# This displays the first digit pressed and moves it to correct register for calculator
		#BL display_keypad
		#ADD r2, r2, r0

		#ADD r4, r4, #1
		#B number

		#end_number:

		# r3 has the keypad code
		#MOV r3, r2
		#MOV r1, #0
	    #BL writeSVNSEG
	    #POP {r1,r2,r4,LR}
	   # BX LR


.endif
