# Ian	(idl3)
# Project 1
# ADDED DIFFICULTY SELECTION FOR THE EXTRA CREDIT

# LED colors
.eqv	LED_OFF		0
.eqv	LED_RED		1
.eqv	LED_YELLOW	3
.eqv	LED_GREEN	4
.eqv	LED_BLUE	5


# Board size
# The board is a 64x64 display
# Here you can make pixels larger by increasing LED_SIZE (e.g. 2x2), but reducing resolution!!
#    Both LED_WIDTH*LED_SIZE and LED_HEIGHT*LED_SIZE which must less than 64. Or bad things may happen
.eqv	LED_SIZE	2
.eqv	LED_WIDTH	32
.eqv	LED_HEIGHT	32

.data
	
	# holds the millipede's coordinates and length
	millipedeX: 	 .word -1, -2, -3, -4, -5, -6, -7, -8, -9, -10
	millipedeY:	 .word 	0,  0,  0,  0,  0,  0,  0,  0,  0,   0
	millipedeLength: .word	10
	
	# holds the player's coordinates
	playerX:	.word	15	
	playerY:	.word	21
	
	# holds the projectile's coordinates
	projectileX:	.word 	-1
	projectileY:	.word	-1
	projectileFired:.word	0
	
	# messages to display when the game ends
	strPlayerLost: .asciiz 	"You lost! Better luck next time!\n"
	strPlayerWon:  .asciiz	"Congratulations! You defeated the villainous Millipede!\n"
	
	# Key states
	leftPressed:	.word	0
	rightPressed:	.word	0
	upPressed:	.word	0
	downPressed:	.word	0
	actionPressed:	.word	0
	
	# Frame counting
	frameCounter:	.word	0
	
	#----------------------------- EXTRA CREDIT -----------------------------#
	
	# Allows the user to select up to four different difficulty levels which increase the speed of the millipede
	# Determines difficulty
	difficulty:	.word 	4
	
	# Introduction text ran at the beginning of the game asking for difficulty selection
	welcomeMessage:		.asciiz "Welcome to MIPS: Millipede Infraction Protection Simulator!\n\n"
	selectDifficulty:	.asciiz	"Please choose a difficulty by typing the corresponding number and then pressing enter\n\t 1 (easy), 2 (normal), 3 (hard), 4 (SATANIC)\n--: "
	invalidInput:		.asciiz "\nYou must select a valid difficulty!\n\n"
	
	#------------------------------------------------------------------------#
.text
.globl main
main:
	# initializes the game state
	jal	initialize

	# main loop for the game
	jal	gameStart
	
	# game is over
	lw	t0, millipedeLength
	bne	t0, 0, player_lost
	
	# shows the player a message if they won
	li	v0, 4
	la	a0, strPlayerWon
	syscall
	
	j	exit
	
	# shows the player a message if they lost
	player_lost:
	
	li	v0, 4
	la	a0, strPlayerLost
	syscall
	
	# ends the program
	exit:
	
	li	v0, 10
	syscall


# initializes the game board with 40 to 45 mushrooms
initialize:

	push	ra
	
	li	a0, 1
	jal	displayRedraw
	
		
	# ----------------------------- EXTRA CREDIT ----------------------------- #
	# ************************************************************************ #
	
	# prints the welcome message for the game
	li	v0, 4
	la	a0, welcomeMessage
	syscall
	
	# prompts the user to select the difficulty until a valid option is chosen
	select_difficulty:
	li	v0, 4
	la	a0, selectDifficulty
	syscall

	
	# branches depending on the difficulty selected
	li	v0, 5
	syscall
	move	t0, v0
	beq	t0, 1, difficulty_easy
	beq	t0, 2, difficulty_normal
	beq	t0, 3, difficulty_hard
	beq	t0, 4, difficulty_satanic
	
	# prompts the user to select again if they choose an invalid selection
	li	v0, 4
	la	a0, invalidInput
	syscall
	
	j	select_difficulty
	
	# sets the difficulty to easy; millipede moves 5 pixels per second
	difficulty_easy:
	
	li	t0, 8
	j	set_difficulty
	
	# sets the difficulty to normal; millipede moves 10 pixels per second
	difficulty_normal:
	
	li	t0, 4
	j	set_difficulty
	
	# sets the difficulty to hard; millipede moves 20 pixels per second
	difficulty_hard:
	li	t0, 2
	j	set_difficulty
	
	# sets the difficulty to SATANIC; millipede moves 40 pixels per second
	difficulty_satanic:
	li	t0, 1
	
	set_difficulty:
	sw	t0, difficulty
	
	# ************************************************************************ #
	# ************************************************************************ #
	
	
	# counter for placing mushrooms
	li	t0, 0
	
	li	a1, 6
	jal	rand
	add	t1, v0, 40
	
	# loop used to populate the board
	populate_board:
	
	# stops drawing mushrooms if t0 is greater than t1
	bgt	t0, t1, stop_populating
	
	jal	drawMushroom
	add	t0, t0, 1
	
	j	populate_board
	
	# ends the loop
	stop_populating:
	
	pop	ra
	jr	ra

# main loop for the game; updates on an interval of 100ms or 10fps
gameStart:
	
	push	ra
	push	s0
	push	s1
	push	s2
	
	jal	getSystemTime		
	move	s0, v0			# t0 = last

	# Continues running the game until a lose or win condition is found
	gameLoop:
	jal	getSystemTime
	move	s1, v0			# t1 = time
	
	jal	handleInput
	
	sub	s2, s1, s0		# s0 = elapsed
	
	blt	s2, 25, gameLoop
	
	move	s0, s1
	jal	update
	
	# End the game when it tells us to
	beq	v0, -2, gameEnd
	
	li	a0, 0
	jal	displayRedraw
	
	j	gameLoop

	# game is over
	gameEnd:

	pop	s2
	pop	s1
	pop	s0
	pop	ra
	jr	ra


# updates the game state
# returns v0: -2 when the game should end
update:

	push	ra
	push	s0
	push	s1
	push	s2
	push	s3
	
	# counts the number of frames
	lw	s0, frameCounter
	lw	s1, projectileFired
	# bonus feature: difficulty (changes the speed of the millipede)
	lw	s4, difficulty
	
	
	# updates the millipede and player every 2 frames
	div	s3, s0, s4
	mfhi	s3
	bne	s3, 0, update_player
	
	jal	updateMillipede	
	move	s2, v0
	beq	s2, -2, end_update
	
	# updates the player
	update_player:
	div	s3, s0, 4
	mfhi	s3
	bne	s3, 0, update_projectile
	
	jal	updatePlayer
	move	s2, v0
	beq	s2, -2, end_update
	
	# updates the projectile if there is one
	update_projectile:
	div	s3, s0, 2
	mfhi	s3
	bne	s3, 0, update_mushrooms
	
	jal	updateProjectile
	move	s2, v0
	beq	s2, -2, end_update
	
	# draws one mushroom every 40 frames (~1 second)
	update_mushrooms:
	div	s3, s0, 40
	mfhi	s3
	
	bne	s3, 0, end_update
	
	jal	drawMushroom

	# ends the frame and increments the frame counter
	end_update:
	
	
	add	s0, s0, 1
	sw	s0, frameCounter
	
	move	v0, s2
	
	pop	s3
	pop	s2
	pop	s1
	pop	s0
	pop	ra
	jr	ra

# draws and updates player variables
# returns v0: -2 when the game should end	
updatePlayer:

	push	ra
	push	s0
	push	s1
	push	s2
	push	s3

	
	lw	s0, playerX
	lw	s1, playerY
	
	move	a0, s0
	move	a1, s1
	li	a2, LED_BLUE
	jal	displaySetLED
	
	
	# handles upwards movement
	#-------------------------
	move_up:
	lw	s2, upPressed
	beq	s2, 0, move_down
	
	# erases the previous pixel
	jal	erasePreviousPosition
	
	# checks for collision
	sub	s3, s1, 1
	beq	s3, -1, cancel_up
	
	#checks for collision with mushrooms
	move	a0, s0
	move	a1, s3
	jal	displayGetLED
	beq	v0, LED_GREEN, cancel_up
	
	# updates the player's y position
	move	s1, s3
	sw	s1, playerY
	
	cancel_up:
	
	move	a0, s0
	move	a1, s1
	li	a2, LED_BLUE
	jal	displaySetLED
	
	# handles downwards movement
	#---------------------------
	move_down:
	
	lw	s2, downPressed
	beq	s2, 0, move_left
	
	# erases the previous pixel
	jal	erasePreviousPosition

	# checks for collision
	add	s3, s1, 1
	beq	s3, 32, cancel_down
	
	#checks for collision with mushrooms
	move	a0, s0
	move	a1, s3
	jal	displayGetLED
	beq	v0, LED_GREEN, cancel_down
	
	# updates the player's y position
	move	s1, s3
	sw	s1, playerY
	
	cancel_down:
	
	move	a0, s0
	move	a1, s1
	li	a2, LED_BLUE
	jal	displaySetLED
	
	# handles leftwards movement
	#---------------------------
	move_left:
	
	lw	s2, leftPressed
	beq	s2, 0, move_right
	
	# erases the previous pixel
	jal	erasePreviousPosition
	
	# checks for collision
	sub	s3, s0, 1
	beq	s3, -1, cancel_left
	
	#checks for collision with mushrooms
	move	a0, s3
	move	a1, s1
	jal	displayGetLED
	beq	v0, LED_GREEN, cancel_left
	
	# updates the player's x position
	move	s0, s3
	sw	s0, playerX
	
	cancel_left:
	
	move	a0, s0
	move	a1, s1
	li	a2, LED_BLUE
	jal	displaySetLED
	
	# handles rightwards movement
	#----------------------------
	move_right:
	
	lw	s2, rightPressed
	beq	s2, 0, updatePlayerExit
	
	# erases the previous pixel
	jal	erasePreviousPosition
	
	# checks for collision with boundaries
	add	s3, s0, 1
	beq	s3, 32, cancel_right
	
	#checks for collision with mushrooms
	move	a0, s3
	move	a1, s1
	jal	displayGetLED
	beq	v0, LED_GREEN, cancel_right
	
	# updates the player's x position
	move	s0, s3
	sw	s0, playerX
	
	cancel_right:
	
	move	a0, s0
	move	a1, s1
	li	a2, LED_BLUE
	jal	displaySetLED
	
	# exits the player
	updatePlayerExit:

	pop	s3
	pop	s2
	pop	s1
	pop	s0
	pop	ra
	
	jr	ra
	
# updates the projectiles location and handles collision
updateProjectile:

	push	ra
	push	s0
	push	s1
	push	s2
	push	s3
	push	s4
	push	s5
	push	s6
	
	# handles the projectile (B key)
	#-------------------------------
	shoot_projectile:

	
	# retrieves global variables
	lw	s0, projectileFired
	lw	s1, projectileX
	lw	s2, projectileY

	# if a projectile is still on screen update it
	bne	s0, 0, current_projectile
	
	# fires a new projectile if one isn't on the board
	lw	t0, actionPressed
	beq	t0, 0, exit_update_projectile
	
	lw	s3, playerX
	lw	s4, playerY
	
	li	s0, 1
	sw	s0, projectileFired
	
	move	s1, s3
	sub	s2, s4, 1
	
	# handles projectile collision
	move	a0, s1
	move	a1, s2
	jal	displayGetLED
	beq	v0, LED_GREEN, destroy_projectile
	beq	v0, LED_RED, millipede_collision
	
	# draws the pixel with the projectiles new position
	li	a2, LED_YELLOW
	jal	displaySetLED
	
	j	exit_update_projectile
	
	# handles movement of an already fired projectile
	current_projectile:
	
	move	a0, s1
	move	a1, s2
	li	a2, LED_OFF
	jal	displaySetLED
	
	beq	s2, 0, destroy_projectile
	sub	s2, s2, 1
	
	# handles projectile collision
	move	a0, s1
	move	a1, s2
	jal	displayGetLED
	beq	v0, LED_GREEN, destroy_projectile
	beq	v0, LED_RED, millipede_collision
	
	li	a2, LED_YELLOW
	jal	displaySetLED
	
	j	exit_update_projectile
	
	# handles millipede collision
	millipede_collision:
	lw	s3, millipedeLength
	beq	s3, 0, exit_update_projectile
	
	sub	s3, s3, 1
	
	mul	s4, s3, 4
	la	s5, millipedeX
	la	s6, millipedeY
	add	s5, s5, s4
	add	s6, s6, s4
	lw	s5, (s5)
	lw	s6, (s6)
	
	# erases the destroyed segment
	move	a0, s5
	move	a1, s6
	li	a2, LED_OFF
	jal	displaySetLED
	
	sw	s3, millipedeLength
	
	li	a0, 0
	jal	displayRedraw
	
	bne	s3, 0, destroy_projectile
	
	li	v0, -2
	
	# handles projectile destruction
	destroy_projectile:
	
	move	a0, s1
	move	a1, s2
	li	a2, LED_OFF
	jal	displaySetLED
	
	li	s0, 0
	sw	s0, projectileFired
	
	# exits projectile update handler
	exit_update_projectile:
		
	sw	s1, projectileX
	sw	s2, projectileY
	
	pop	s6
	pop	s5
	pop	s4
	pop	s3
	pop	s2
	pop	s1
	pop	s0
	pop	ra
	jr	ra
	
# clears the last position the player's character occupied
erasePreviousPosition:

	push	ra	
	
	lw	a0, playerX
	lw	a1, playerY
	li	a2, LED_OFF
	jal	displaySetLED
	
	pop	ra
	jr	ra
	

# draws the millipede 
# returns v0: -2 when the game should end
updateMillipede:

	push	ra
	push	s0
	push	s1
	push	s2
	push	s3
	push	s4
	push	s5


	li	s0, 0			# tracks the index of the millipede array
	la	s1, millipedeX		# holds the address of the array holding the x-coordinate for each segment
	la	s2, millipedeY		# holds the address of the array holding the y-coordiante for each segment
	lw	s3, millipedeLength	# holds the length of the millipede
	
	drawLoop:
	
	beq	s0, s3, stopDrawing	# if the index is greater than or equal to the length 
	
	lw	s4, (s1)
	lw	s5, (s2)
	
	# checks for player collision
	lw	t0, playerX
	lw	t1, playerY
	
	bne	s4, t0, collision_check_pass
	bne	s5, t1, collision_check_pass
	
	li	v0, -2

	j	stopDrawing

	collision_check_pass:
	
	# draws the segment with the given coordinates
	move	a0, s4
	move	a1, s5
	move	a2, s1
	move	a3, s2
	jal	drawSegment
	
	# moves to the next segment in the array
	next_segment:
	
	add	s1, s1, 4
	add	s2, s2, 4
	
	add	s0, s0, 1
	
	j	drawLoop
	
	# draws the millipede then exits the function
	stopDrawing:
		
	pop	s5
	pop	s4
	pop	s3
	pop	s2
	pop	s1
	pop	s0
	pop	ra
	jr	ra
	
# draws a single segment of the millipede (a0: x, a1: y, a2: x address, a3: y address)
drawSegment:

	push	ra	
	push	s0
	push	s1
	push	s2
	push	s3
	push	s4

	move	s0, a0
	move	s1, a1
	move	s2, a2
	move	s3, a3

	
	# skips drawing the segment if the x-coordinate is less than the starting position
	# (only used when first drawing the millipede)
	blt	s0, -1, skip_segment
	
	# deletes the old segment
	move	a0, s0
	move	a1, s1
	li	a2, LED_OFF
	jal	displaySetLED
	
	div	s4, s1, 2
	mfhi	s4
	
	beq	s4, 0, is_even		# if y is even forward
	beq	s4, 1, is_odd		# if y is odd reverse
	
	j	draw_segment
	
	# if y-axis is odd move millipede forward
	is_even:
	
	# checks right wall collision
	bne	s0, 31, move_forward
	
	move	a0, s0
	move	a1, s1
	move	a2, s2
	move	a3, s3
	jal	changeDirection
	move	s0, v0
	move	s1, v1
	
	j	draw_segment
	
	# moves the segment forward one space
	move_forward:
	
	add	s0, s0, 1
	
	move	a0, s0
	move	a1, s1
	jal	displayGetLED
	
	beq	v0, LED_GREEN, mushroom_collision_right
	
	sw	s0, (s2)
	
	j	draw_segment
	
	# handles mushroom collision from the right
	mushroom_collision_right:
	
	move	a0, s0
	move	a1, s1
	move	a2, s2
	move	a3, s3
	jal	changeDirection
	sub	s0, v0, 1
	move	s1, v1
	
	j	draw_segment
	
	# if y-axis is odd move millipede in reverse
	is_odd:
	
	# checks left wall collision
	bne	s0, 0, move_back
	
	move	a0, s0
	move	a1, s1
	move	a2, s2
	move	a3, s3
	jal	changeDirection
	move	s0, v0
	move	s1, v1
	
	j	draw_segment
	
	# moves the segment back one space to the left
	move_back:
	
	sub	s0, s0, 1
	
	# checks for collision from the left
	move	a0, s0
	move	a1, s1
	jal	displayGetLED
	
	# collision branch statements
	beq	v0, LED_GREEN, mushroom_collision_left
	
	sw	s0, (s2)
	
	j	draw_segment
	
	# handles mushroom collision from the left
	mushroom_collision_left:
	
	move	a0, s0
	move	a1, s1
	move	a2, s2
	move	a3, s3
	jal	changeDirection
	add	s0, v0, 1
	move	s1, v1
	
	j	draw_segment

	# draws the segment
	draw_segment:
	
	move	a0, s0
	move	a1, s1
	li	a2, LED_RED
	jal	displaySetLED

	
	j	exit_segment
	
	# only used at the beginning
	skip_segment:
	
	add	s0, s0, 1
	sw	s0, (s2)
	
	exit_segment:

	pop	s4
	pop	s3
	pop	s2
	pop	s1
	pop	s0
	pop	ra
	jr	ra
	
# moves the millipede down (a0: x-coordinate, a1: y-coordinate, a2: x-address, a3: y-address)
# return new y coordinate (v0: new x coordinate, v1: new y coordinate)
changeDirection:

	push	ra
	push	s0
	push	s1
	push	s2
	push	s3
	
	move	s0, a0
	move	s1, a1
	move	s2, a2
	move	s3, a3

	# if the millipede is at the bottom corner of the board, branch and reset the position
	beq	s1, 31, reset_position
	
	# otherwise move the millipede down
	add	s1, s1, 1
	sw	s1, (s3)
	
	j	exit_direction
	
	# moves the millipede to the top left if it reaches a bottom corner
	reset_position:
	
	li	s0, -1
	sw	s0, (s2)
	li	s1, 0
	sw	s1, (s3)
	
	# exits the loop and returns the coordinates
	exit_direction:
	
	move	v0, s0
	move	v1, s1
	
	pop	s3
	pop	s2
	pop	s1
	pop	s0
	pop	ra
	jr	ra
	
	
# draws a random mushroom on the board
drawMushroom:

	push	ra
	push	s0
	push	s1
	push	s2
	
	new_mushroom:
	
	# generates random x-coordinate
	li	a1, 32
	jal	rand
	move	s0, v0
	
	# generates random y-coordinate
	li	a1, 32
	jal	rand
	move	s1, v0
	
	bge	s0, 2, continue
	bge	s1, 2, continue
	
	j	new_mushroom
		
	continue:	
	
	move	a0, s0
	move	a1, s1
	jal	displayGetLED
	move	s2, v0
	
	# checks if pixel is already occupied; makes a new one if it is
	bne	s2, 0, new_mushroom
	
	# draws a green mushroom at (s0, s1)
	move	a0, s0
	move	a1, s1
	li	a2, LED_GREEN
	jal	displaySetLED

	pop	s2
	pop	s1
	pop	s0
	pop	ra
	jr	ra
	
# gets the current system time, returns it to v0
getSystemTime:
	
	push	ra
	
	li	v0, 30
	syscall
	move	v0, a0
	
	pop	ra
	jr	ra

# generate a random number with an upperbound of a0 (a0: upper bound)
rand:
	push	ra
	
	# sses service 42 to generate a random number
	li 	v0, 42
	li	a0, 0
	syscall
	
	# returns the random number to register v0
	move	v0, a0
	
	# returns caller
	
	pop	ra
	jr 	ra


# LED Input Handling Function
# -----------------------------------------------------
	
# bool handleInput(elapsed)
#   Handles any button input.
# returns: v0: 1 when the game should end.
handleInput:
	push	ra
	push	s0
	push	s1
	push	s2
	
	# Get the key state memory
	li	s0, 0xffff0004
	lw	s1, (s0)
	
	# Check for key states
	and	s2, s1, 0x1
	sw	s2, upPressed
	
	srl	s1, s1, 1
	and	s2, s1, 0x1
	sw	s2, downPressed
	
	srl	s1, s1, 1
	and	s2, s1, 0x1
	sw	s2, leftPressed
	
	srl	s1, s1, 1
	and	s2, s1, 0x1
	sw	s2, rightPressed
	
	srl	s1, s1, 1
	and	s2, s1, 0x1
	sw	s2, actionPressed
	
	move	v0, s2
	
	pop	s2
	pop	s1
	pop	s0
	pop	ra
	jr	ra

# LED Display Functions
#------------------------------------------



# Board addresses
.eqv    BOARD_CTRL      0xFFFF0000
.eqv    DISPLAY_KEYS    0xFFFF0004
.eqv    BOARD_ADDRESS   0xFFFF0008

.text
# void displayRedraw()
#   Tells the LED screen to refresh.
#
# arguments: $a0: when non-zero, clear the screen
# trashes:   $t0-$t1
# returns:   none
displayRedraw:
	sw	a0, BOARD_CTRL				# *BOARD_CTRL = a0;
	jr	ra					# return;

# void _setLED(int x, int y, int color)
#   sets the LED at (x,y) to color
#   color: 0=off, 1=red, 2=yellow, 3=green
#
# arguments: $a0 is x, $a1 is y, $a2 is color
# returns:   none
#
displaySetLED:
	# Function Prologue
	push	ra
	push	s0
	push	s1
	push	s2
	
	# I am trying not to use t registers to avoid
	#   the common mistakes students make by mistaking them
	#   as saved.

	#   :)

	# Byte offset into display: y * 16 bytes + (x / 4)
	# y * 64 bytes
	sll	s0, a1, 6				# s0 = y << 6;

	# Take LED size into account
	mul	s0, s0, LED_SIZE			# s0 *= LED_SIZE;
	mul	s1, a0, LED_SIZE			# s1 *= x;

	# Add the requested X to the position
	add	s0, s0, s1				# s0 += s1;

	# base address of LED display
	li	s1, BOARD_ADDRESS			# s1 = BOARD_ADDRESS;
	
	# address of byte with the LED
	add	s0, s1, s0				# s0 = BOARD_ADDRESS + s0;

	# s0 is the memory address of the first pixel
	# s1 is the memory address of the last pixel in a row
	# s2 is the current Y position

	li	s2, 0					# s2 = 0;
_displaySetLEDYLoop:					# do {
	# Get last address
	add	s1, s0, LED_SIZE			# 	s1 = s0 + LED_SIZE;

_displaySetLEDXLoop:					# 	do {
	# Set the pixel at this position
	sb	a2, (s0)				# 		a2 = *s0;

	# Go to next pixel
	add	s0, s0, 1				# 		s0++;

	beq	s0, s1, _displaySetLEDXLoopExit		# 	} while(s0 != s1);
	j	_displaySetLEDXLoop

_displaySetLEDXLoopExit:				#
	# Reset to the beginning of this block
	sub	s0, s0, LED_SIZE			# 	s0 = s0 - LED_SIZE;

	# Move to next row
	add	s0, s0, 64				# 	s0 += 64;

	add	s2, s2, 1				# 	s2++;
	beq	s2, LED_SIZE, _displaySetLEDYLoopExit	# } while (s2 != LED_SIZE);

	j	_displaySetLEDYLoop

_displaySetLEDYLoopExit:
	# Function Epilogue
	pop	s2
	pop	s1
	pop	s0
	pop	ra
	jr	ra					# return;

# int displayGetLED(int x, int y)
#   returns the color value of the LED at position (x,y)
#
#  arguments: $a0 holds x, $a1 holds y
#  returns:   $v0 holds the color value of the LED (0 through 7)
#
displayGetLED:
	# Function Prologue
	push	ra
	push	s0
	push	s1

	# Byte offset into display = y * 16 bytes + (x / 4)
	# y * 64 bytes
	sll	s0, a1, 6				# s0 = y << 6;

	# Take LED size into account
	mul	s0, s0, LED_SIZE			# s0 = s0 * LED_SIZE;
	mul	s1, a0, LED_SIZE			# s1 = x  * LED_SIZE;

	# Add the requested X to the position
	add	s0, s0, s1				# s0 += s1;

	# base address of LED display
	li	s1, BOARD_ADDRESS
	
	# address of byte with the LED
	add	s0, s1, s0				# s0 = BOARD_ADDRESS + s0;
	lbu	v0, (s0)				# v0 = *(unsigned char&)s0;

	# Function Epilogue
	pop	s1
	pop	s0
	pop	ra
	jr	ra					# return v0;
