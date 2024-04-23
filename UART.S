.ifndef UART_S
.set UART_S, 1

/*
 * UART.S
 *
 *  Created on: Mar 30, 2022
 *      Author: jacob
 */
 .include "../src/GPIO.S"
 .include "../src/esp32.S"

.set UART1_BASEADDR, 0xE0001000
.set UART0_BASEADDR, 0xE0000000

.text

setup_UART1:
	# Reset the UART Controller
	LDR r0, =UART1_BASEADDR
	MOV r1, #0b1101011
	STR r1, [r0]

	# Set the BAUDGEN clock divider (115200 baud rate, 124 divider value)
	# 100MHz / 124 = 806.451kHz
	MOV r1, #124
	STR r1, [r0, #0x18]

	# Set the Baud_Rate_Divider for bit-clock (115200 baud rate, 6 divider value)
	# 806.451kHz / (6 + 1) = 115.207kHz, 115207 baud rate
	MOV r1, #6
	STR r1, [r0, #0x34]

	# Enable software resets, transmitter & receiver, stop transmitter break
	MOV r1, #0b100010111
	STR r1, [r0]

	# Channel mode to normal, 1 stop bit, no parity, character length 8-bit, clock source ref. clk
	MOV r1, #0b0000100000
	STR r1, [r0, #0x4]

	# Set timeout to 1 (RXTOUT register)
	MOV r1, #1
	STR r1, [r0, #0x1C]

	# Disable all interrupts (IDR register)
	MOV r1, #0xFFF
	STR r1, [r0, #0xC]

	BX lr

# This function will send a single character to the UART1 TX buffer
# Assume that the character to send is stored in r1 prior to calling the function
send_char_UART0:
	PUSH {r0}

	LDR r0, =UART0_BASEADDR
	STR r1, [r0, #0x30]

	POP {r0}
	BX lr

# This function will receive a single character from the UART1 RX buffer
# Character received is stored in r1
receive_char_UART1:
	LDR r0, =UART1_BASEADDR

	waitForRX:
		LDR r2, [r0, #0x2C]
		AND r2, r2, #0b10
		CMP r2, #0
		BNE waitForRX

	LDR r1, [r0, #0x30]

	BX lr

# This function will send a null terminated string to the UART1 TX buffer
# Assume that a pointer to the start of the string to send is stored in r5 prior to calling the function
send_string_UART0:
	PUSH {lr}

	LDR r0, =UART0_BASEADDR
	# Counter to keep track of which character I am on in the string
	MOV r2, #0

	send_string:
		# Grab our next character in the string
		LDRB r3, [r5, r2]

		# Check to see if we have hit the null character
		CMP r3, #0
		BEQ end_send_string

		waitForTX:
			LDR r4, [r0, #0x2C]
			AND r4, r4, #0b10000
			CMP r4, #0
			BNE waitForTX

		# If not at end of string, send via UART1 to PC
		PUSH {r1}
		MOV r1, r3
		BL send_char_UART0
		POP {r1}

		# Move to next character
		ADD r2, r2, #1

	B send_string

	end_send_string:

	POP {lr}
	BX lr


#recieve_string_UART0:
	#PUSH {lr}

	#LDR r0, =UART0_BASEADDR
	# Counter to keep track of which character I am on in the string
	#MOV r2, #0
	#MOV r1, #0

	#recieve_string:
		# Grab our next character in the string
		#LDR r3, [r0, #0x30]
		#CMP r3, #0x3A
		#BNE recieve_string
		#BEQ recieve_info

	#recieve_info:
		#CMP r2, #4
		#BEQ recieve_string_end
		#LSL r1, #4
		#LDR r3, [r0, #0x30]
		#BL convert_hex
		#ADD r1, r1, r3

		#ADD r2, r2, #1
		#B recieve_info

	#recieve_string_end:
	# r1 should have the information
	#POP {lr}
	#BX lr


	keypad_string:
	PUSH {LR}

	BL display_keypad
	BL convert_ascii
	LDR r2, =command
	STR r0, [r2, #0]

	BL display_keypad
	BL convert_ascii
	LDR r2, =command
	STR r0, [r2, #1]

	BL display_keypad
	BL convert_ascii
	LDR r2, =command
	STR r0, [r2, #2]

	BL display_keypad
	BL convert_ascii
	LDR r2, =command
	STR r0, [r2, #3]

	LDR r5, =command
	BL send_string_UART0
	BL timer

	POP {LR}
	MOV pc, lr


.endif
