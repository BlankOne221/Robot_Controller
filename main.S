/*
 * main.S
 *
 *  Created on: Apr 4, 2022
 *      Author: jacob
 */

# WARNING: DO NOT HAVE MOTORS DIRECTLY PLUGGED INTO BLACKBOARD
#          WHEN THE BOARD IS POWERED UP AND BEFORE PROGRAMMING THE BOARD.
# 		   THE H-BRIDGE WILL CREATE A SHORT-CIRCUIT AND YOU WILL DAMAGE IT.
#
# 		   YOU CAN CONNECT THE MOTORS AFTER YOU HAVE UPLOADED THE PROGRAM TO YOUR BOARD
#
#		   IF YOU SMELL BURNING, SHUT THE POWER OFF ON YOUR BOARD IMMEDIATELY TO PREVENT DAMAGE.
#
#		   This issue should largely be absent if you are using the DHB1 PMOD.
#
#		   However, still know that if you leave the DHB1 module and the battery connected,
#		   the motors will spin at full speed prior to programming your board.

.include "../src/RobotMotors.S"
.include "../src/robomal.S"
.include "../src/GPIO.S"
.include "../src/esp32.S"
.include "../src/UART.S"

.set SW_BASEADDR, 0x41220000
.set BTN_BASEADDR, 0x41200000

.global main

.data

# jump table for various modes
Mode: .word Nothing, Autonomous, Programmable, RC, line_following

.text

main:

	#PMODB setup code
	@ This example assumes the top pins of PMODB should be inputs
 	@ unsigned int inout == r1, unsigned int row == r2
	MOV r1, #1   	@ r1 == inout = 0
	MOV r2, #0  	@ r2 == row = 0
	BL setupPMODB	@ setupPMODB(0, 0);

	@ This example assumes the bottom pins of PMODB should be outputs
 	@ unsigned int inout == r1, unsigned int row == r2
	MOV r1, #0		@ r1 == inout = 1
	MOV r2, #1		@ r2 == row = 1
	BL setupPMODB 	@ setupPMODB(1, 1);


	# Setup Motor 0 (connected to top row of PMODC)
	LDR r1, =MOTOR_0_BASEADDR
	BL setup_motor

	# Setup Motor 1 (connected to bottom row of PMODC)
	LDR r1, =MOTOR_1_BASEADDR
	BL setup_motor

	# setup station commands
	BL setup_esp32
	BL timer

	BL setupSVNSEG


	whileOne:

	# wait for button press here
	BL button_wait

	# Ready for message
	LDR r5, =sendFromAP
	BL send_string_UART0
	BL timer
	BL read_esp32

	BL keypad_string
	BL read_esp32



		#UART0 is communication to and from the ESP32 chip
		LDR r0, =UART0_BASEADDR
		 # UART1 is communication to and from the PC
		LDR r1, =UART1_BASEADDR

		# Check to see if there is anything in the UART0 RX Buffer
		# Did the ESP32 chip send the Blackboard anything?
		LDR r2, [r0, #0x30]
		CMP r2, #0

		# If there was something on the FIFO RX buffer, send it right
		# back to the user via UART1 TX FIFO
		# PC is going to receive the message, which will help us
		# see the data incoming from the ESP32
		STRNE r2, [r1, #0x30]

		# Check to see if there is anything in the UART1 RX Buffer
		# Did the user send the Blackboard anything from the PC?
		#LDR r3, [r1, #0x30]
		#CMP r3, #0
		#BEQ whileOne

		# If there was something on the FIFO RX buffer, send it right
		# back to the user via UART0 TX FIFO
		# ESP32 is going to receive the message from our PC
		#STR r3, [r0, #0x30]

		# The full message coming from the PC doesn't include a '\n' (LF)
		# character, so we need to add one to the end of my message
		#CMP r3, #'\r'
		#MOVEQ r4, #'\n'
		#STREQ r4, [r0, #0x30]


		#in r0 is the switch state
		BL get_switches
		AND r0, r0, #0xF
		MOV r2, r0

		Modes:

			# branching to correct mode using switch state
			LDR r0, =Mode
			LDR r1, [r0, r2, LSL #2]
			BX r1

			Nothing:

				# Program will wait for a switch to press
				# send keypad string

				B endmode

			Autonomous:

				# Autonomous mode, runs a default program

				default_loop:


				# inputs are switch states

				B endmode

			Programmable:

				# Programmable mode, you send instructions
				# then it excutes all of them
				B endmode

			RC:

				#Send one instruction and it excutes it
				B endmode

			line_following:

				# follows the black lines
				B endmode


			endmode:



	B whileOne


.end

