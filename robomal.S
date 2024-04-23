/*
* robomal.S
*
* Created on: Apr 1, 2022
* Author: jacob murray / Artem Labanau
*/

.ifndef ROBOMAL_S
.set ROBOMAL_S, 1

.include "../src/RobotMotors.S"
.include "../src/GPIO.S"


.data

# ROBOMAL Architecture: 16-bit architecture

# Spoofing Harvard Architecture
ROBO_Instructions: .hword 0x42CF, 0x42FC, 0x4400, 0x43FF, 0x43C0, 0x4400
ROBO_Data: .hword 0x0080, 0x0000

# All the different excutable operations we can do in the robomal
operations: .word Data_Transfer_Instructions, Arithmetic_Instructions, Branch_Instructions, Robot_Control_Instructions
Data_Transfer_Instructions: .word Read, Write, Load, Store
Arithmetic_Instructions: .word Add, Subtract, Multiply
Branch_Instructions: .word Branch, BranchEQ, BranchNE, Halt
Robot_Control_Instructions: .word Left, Right, Forward, Backward, Brake

# ROBOMAL Register File
# r5 = accumulator register
# r6 = program counter register
# r7 = instruction register
# r8 = opcode register
# r9 = operand register
# r10 = multiply top half solution register
.text

# tells the robot to run a program
runROBO_Program:
	PUSH {lr}
	# Initialize PC to the "start" of my program
	MOV r6, #0

	ROBO_Loop:
		BL simulateClockCycle
		CMP r8, #0x33
		BNE ROBO_Loop

	POP {lr}
	MOV pc, lr

# simulate 1 fetch, decode, and execute instuction cycle
simulateClockCycle:
	PUSH {lr}

	BL fetch
	BL decode
	BL execute

	POP {lr}
	MOV pc, lr


# go grab an instruction (from instruction memory) located at the program counter
# register
# r6 = PC
# r7 = instruction register
fetch:
	# get a pointer to the beginning of instruction memory
	LDR r0, =ROBO_Instructions

	# fetching the instruction located at ROBO_Program + offset (PC)
	LDRH r7, [r0, r6]

	# increment PC to point to next instruction
	ADD r6, r6, #0x2
	MOV pc, lr


# break the instruction register up into opcode and operand
# r7 = instruction register
# r8 = opcode register
# r9 = operand register
decode:
	# get opcode
	LSR r8, r7, #8
	# get operand
	AND r9, r7, #0xFF
	MOV pc, lr


# r5 = accumulator register
# r6 = program counter register (if we are doing a branch)
# r8 = opcode register
# r9 = operand register
# r10 = multiply top half solution register

# execute function for the execute stage
execute:
	PUSH {LR}

	# Helps us find the right family and operation to do inside using the op code register
	# by shifting and checking both bits
	operation:

	# shift r8 right and move to r0
	# subtract by 1 to get
	MOV r0, r8, LSR #4
	SUB r0, r0, #1

	# Finding the correct operation by checking the first bit
	# take opcode and perform the correct operation
	LDR r1, =operations
	LDR r2, [r1, r0, LSL #2]


	# Find the correct operation by checking the second bit
	AND r4, r8, #0x0F
	LDR r3, [r2, r4, LSL #2]

	# Go to correct location
	BX r3


	# Various data transfer instructions
	Data_Transfer_INSTRUCTIONS:


		# Read PMODB 7:4 and store it into a specific data memory cell indicated by
		# ROBO_Data
		Read:
		LDR r3, =ROBO_Data
		B endcase

		# Writes PMODB 3:0 from a specific data memory cell indicated by ROBO_Data
		Write:
		LDR r3, =ROBO_Data
		LDRH r1, [r3, r9]
		MOV r2, #0
		BL writePMODB
		B endcase

		# loads a word from specific data memory indicated by ROBO_Data into r5
		Load:
		LDR r3, =ROBO_Data
		LDRH r5, [r3, r9]
		B endcase

		# stores a word from r5 into specific data memory indicated by ROBO_Data
		Store:
		LDR r3, =ROBO_Data
		STRH r5, [r3, r9]
		B endcase


	# r5 is the "first operand" , r9 is the "Second operand"
	# Arithmetic instructions
	Arithmetic_INSTRUCTIONS:

		# Adds a word from a cell in data memory inidicated by offset to r5.
		# Result stored in r5
		Add:
		ADD r5, r5, r9
		B endcase

		# Subtracts a word from a cell in data memory indiciated by offset, to r5.
		# Result is stored in r5
		Subtract:
		SUB r5, r5, r9
		B endcase

		# Multiplies the the word in r5 by a word in a specific data memory cell.
		# The result is stored in r10:r5
		Multiply:
		MUL r4, r5, r9
		AND r5, r4, #0xFF
		MOV r10, r5, LSR #0x2
		B endcase


	# Branch Instructions
	Branch_INSTRUCTIONS:

		# Branch to a specific address in instruction memory
		Branch:
		MOV r6, r9
		B endcase

		# Branch to a specific address in instruction memory if r5 is zero
		BranchEQ:
		CMP r5, #0
		MOVEQ r6, r9
		B endcase

		# Branch to a specific address in instruction memory if r5 is not zero
		BranchNE:
		CMP r5, #0
		MOVGT r6, r9
		B endcase

		# End of the program, robot stops
		Halt:
		MOV r1, #1
		LDR r3, =LEDS
		STR r1, [r3]
		B endcase


	# Robot COntrol instructions (RCI)
	Robot_Control_INSTRUCTIONS:

		# Turn the robot left some specified number of degrees
		Left:

		# Servo control turn left

		B endcase

		# Turn the robot right some specified numbe of degrees
		Right:

		# Servo control turn right

		B endcase

		# Move the robot forward at slow (00), medium (01), or fast speed (10)
		Forward:

		# Various inputs from the keypad

		LSL r9, #4
		ADD r9, r9, #0xF

		# Setting the motor to the correct speed and direction
		# of motor 0
		MOV r2, r9
		MOV r3, #0
		LDR r1, =MOTOR_0_BASEADDR
		BL change_motor_speed
		BL change_motor_dir

		# Setting the motor to the correct speed and direction
		# of motor 1
		MOV r2, r9
		MOV r3, #0
		LDR r1, =MOTOR_1_BASEADDR
		BL change_motor_speed
		BL change_motor_dir

		B endcase

		# Move the robot backward at slow, medium or fast same as forward
		Backward:

		# Various inputs from the keypad

		LSL r9, #4
		AND r9, r9, #0xF

		# Setting the motor to the correct speed and direction
		# of motor 0
		MOV r2, r9
		MOV r3, #1
		LDR r1, =MOTOR_0_BASEADDR
		BL change_motor_speed
		BL change_motor_dir

		# Setting the motor to the correct speed and direction
		# of motor 1
		MOV r2, r9
		MOV r3, #1
		LDR r1, =MOTOR_1_BASEADDR
		BL change_motor_speed
		BL change_motor_dir

		B endcase

		# Stop the robotos movment after some number of seconds
		Brake:

		MOV r2, r9
		LDR r1, =MOTOR_0_BASEADDR
		BL change_motor_speed

		LDR r1, =MOTOR_1_BASEADDR
		BL change_motor_speed

		B endcase

		Wait:

		# instruction will wait for new input

		B endcase

	endcase:
	POP {LR}
	BX LR

.endif
