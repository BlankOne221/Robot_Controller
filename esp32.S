.ifndef ESP32_S
.set ESP32_S, 1



/*
 * esp32.S
 *
 *  Created on: Apr 23, 2020
 *      Author: jacob
 */

 .include "../src/GPIO.S"
 .include "../src/UART.S"

 .set UART0_BASEADDR, 0xE0000000
 .set UART1_BASEADDR, 0xE0001000

 .set GPIO_BASEADDR, 0xE000A000

 .data
 # these are purely examples for now, but note to send commands to the ESP32,
 # it doesn't have to come from the COM terminal like my example code does...
 # You could also directly send string messages to the ESP32 like examples below...

	setModeAP:   .ascii "AT+CWMODE=2\r\n\0"
	setCWSAP:    .ascii "AT+CWSAP=\"ESP32\",\"\",1,0,4,0\r\n\0"      // Change your ssid and pw to make them unique!
	setAPIP:     .ascii "AT+CIPAP=\"192.168.4.1\",\"192.168.4.1\"\r\n\0"
	setMux:      .ascii "AT+CIPMUX=1\r\n\0"
	setServer:     .ascii "AT+CIPSERVER=1,80\r\n\0"
	sendFromAP:  .ascii "AT+CIPSEND=0,4\r\n\0"             // Change N to number of bytes

	# keypad string
	command: .ascii "0000\r\n\0"


 # Station Commands
 # Use the STA Commands below (setModeSta to startSend in order) to automate the setup process for the STA.
 # Use the STA Commands below (sendFromSta to sendDataSta in order) to send data to the AP.
 #setModeSta:  .ascii "AT+CWMODE=1\r\n\0"
 #setCWJAP:    .ascii "AT+CWJAP=\"ESP32\",\"\"\r\n\0"                // ssid and pw need to match AP to connect
 #startSend:     .ascii "AT+CIPSTART=\"TCP\",\"192.168.4.1\",80\r\n\0"
 #sendFromSta: .ascii "AT+CIPSEND=4\r\n\0"                                    // Change N to number of bytes

 # Do we want to send directional commands? Could do something like this...
 # Can send default commands
 sendForward:  .ascii "4200\0"
 sendBackward: .ascii "4300\0"
 sendRight:       .ascii "4100\0"
 sendLeft:     .ascii "4000\0"
 sendBrake:    .ascii "4400\0"

 # this will be the format of a message you receive from WiFi sources into your ESP32
 # where, 0 is the user who sent it, 4 is the number of bytes in the message, and "1234" is the 4-byte message in this example
 # you are interested in extracting the message "1234" from this data array.
 messageReceived: .ascii "+IPD,0,4:1234"

 .text

 setup_esp32:

 PUSH {lr}

 # setting up UART0, which is the connection between ARM and ESP32
 LDR r0, =UART0_BASEADDR
 BL setup_UART

 # setting up UART1, which is the connection between ARM and PC
 LDR r0, =UART1_BASEADDR
 BL setup_UART

 # set MIO26 (ESP32_EN) as output, enable its output, drive the pin high
 LDR r0, =GPIO_BASEADDR
 LDR r1, =0x4000000 @ 0b1 << 26
 STR r1, [r0, #0x204] @ GPIO_DIRM_0; set the pin as an output
 STR r1, [r0, #0x208] @ GPIO_OUTE_0; enable the output pin
 STR r1, [r0, #0x40]  @ GPIO_MASK_DATA_0_MSW; drive the output pin high

 # Now the ESP32_EN should be driven high and the radio should be turned on

	BL timer
	BL timer
	BL read_esp32

 	LDR r5, =setModeAP
    BL send_string_UART0
    BL timer
    BL read_esp32

	LDR r5, =setCWSAP
	BL send_string_UART0
	BL timer
	BL read_esp32

	LDR r5, =setAPIP
	BL send_string_UART0
	BL timer
	BL read_esp32

	LDR r5, =setMux
	BL send_string_UART0
	BL timer
	BL read_esp32

    LDR r5, =setServer
	BL send_string_UART0
	BL timer
	BL read_esp32

 POP {lr}
 MOV pc, lr

 # sets up the UART with base address stored in r0
 setup_UART:
    # Reset the UART Controller (Control Register)
    MOV r1, #0b1101011
    STR r1, [r0]

    # Set the BAUDGEN clock divider (115200 baud works well; 124 divider value)
    # 100MHz/124 = 806.451kHz
    MOV r1, #124
    STR r1, [r0, #0x18]

    # Set the Baud_Rate_Divider for bit-clock (again for 115200, 0x6 works)
    # 806.451kHz / (6 + 1) = 115.207kHz, 115207 kbps
    MOV r1, #6
    STR r1, [r0, #0x34]

    # Enable software resets, transmitter & receiver, stop transmitter break (Control Register)
    MOV r1, #0b100010111
    STR r1, [r0]

    # Channel mode to normal, 1 stop bit, no parity, character length 8-bit, clock source to UART reference clock (Mode Register)
    MOV r1, #0b0000100000
    STR r1, [r0, #0x04]

    # Set timeout to 1 (RXTOUT register)
    MOV r1, #1
    STR r1, [r0, #0x1C]

    # Disable all interrupts (IDR register)
    MOV r1, #0xFFF
    STR r1, [r0, #0x0C]

    MOV pc, lr

read_esp32:

		read_loop:

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
		BNE read_loop
BX lr


.endif
