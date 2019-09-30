/*
Simon Game

Name: Naomi Venasquez
Student ID:
Email:
Lab Section: L1A
*/

#define _CRT_SECURE_NO_WARNINGS
#include <stdio.h>
#include <stdlib.h>
#include <DAQlib.h>
#include <Windows.h>
#include <time.h>

#define TRUE 1
#define FALSE 0
#define ON 1
#define OFF 0
#define PRESSED 1
#define LOWER 0			/* Lower bound = 0 for push button numbers. */
#define UPPER 3			/* Upper bound = 3 for push button numbers. */
#define MAX_LEVEL 5
#define ONE_SEC 1000
#define WIN 0
#define LOSS 1
#define IN_PROGRESS 2
#define GBT 0			/* Green, red, blue, yellow buttons and their corresponding button numbers. */
#define RBT 1
#define YBT 2
#define BBT 3
#define GLED 0			/* Green, red, blue, yellow LEDs and their corresponding LED channels. */
#define RLED 1
#define YLED 2
#define BLED 3

void runSimon(void);
int randInt(int a, int b);
void win(void);
void lose(void);

int main(void)
{
	int setupNum;

	printf("Enter setup number (0 for the device, 6 for the simulator): ");
	scanf("%d", &setupNum);

	if (setupDAQ(setupNum) == TRUE)
		runSimon();
	else
		printf("ERROR: Cannot initialize system.\n");

	system("PAUSE");
	return 0;
}


/* This function contains the main algorithm for executing the game. */
void runSimon(void)
{
	unsigned int seed = time(NULL);
	int flash[MAX_LEVEL];			/* An array of random LED channel numbers to flash on the screen */
	int input[MAX_LEVEL];			/* An array of the user's inputs */
	int current_level;				/* Current level, from level 1 to MAX_LEVEL */
	int i;							/* Index of array */
	int status;						/* Status of the game */

	/* The srand function call uses the clock as a seed to generate random numbers */
	srand(seed);

	while (continueSuperLoop())
	{
		/* This loop assigns (MAX_LEVEL = 5) random numbers to the flash array. */
		for (i = 0; i < MAX_LEVEL; i++)
		{
			flash[i] = randInt(LOWER, UPPER);

			// SOLUTIONS: printf("Push Button %d\n", flash[i]);
		}

		current_level = 1;
		/* This loop continues until the current level reached the maximum level. */
		while (current_level <= MAX_LEVEL)
		{
			Sleep(2 * ONE_SEC);

			/* Displays random LED flashes on the screen. The higher the level, the more flashes
			are displayed. */
			for (i = 0; i < current_level; i++)
			{
				digitalWrite(flash[i], ON);
				Sleep(ONE_SEC);
				digitalWrite(flash[i], OFF);
				Sleep(ONE_SEC / 2);

				if (continueSuperLoop() == FALSE)
					break;
			}

			if (continueSuperLoop() == FALSE)
				break;

			/* Gets the input from the user by calling the function getInput. */
			i = 0;
			while (i < current_level)
			{
				input[i] = getInput();

				if (input[i] == flash[i])			/* In this case the user's input(s) are correct. */
				{
					if (i == MAX_LEVEL - 1)			/* The user wins after completing the final level. */
					{
						win();
						status = WIN;
						break;
					}
					else
					{								/* Increments the index by 1 to assign the next input
													to the input array. */
						i++;
						status = IN_PROGRESS;
					}
				}
				else
				{									/* The user loses after pressing a wrong button. */
					lose();
					status = LOSS;
					break;
				}

				if (continueSuperLoop() == FALSE)
					break;
			}

			if (status == IN_PROGRESS)
				current_level++;
			else
				break;

			if (continueSuperLoop() == FALSE)
				break;
		}

		if (continueSuperLoop() == FALSE)
			break;
	}
}


/* This function returns a random integer between integers a and b. */
int randInt(int a, int b)
{
	return (rand() % (b - a + 1) + a);
}


/* This function reads the button(s) that the user click on. */
int getInput(void)
{
	int green, red, yellow, blue;		/* Status of the buttons (ON/OFF) */
	int input;							/* Return value */

	/* This loop will keep reading the buttons via digitalRead until the user clicks on a button. */
	while (TRUE)
	{
		green = digitalRead(GBT);
		red = digitalRead(RBT);
		yellow = digitalRead(YBT);
		blue = digitalRead(BBT);

		if (green == ON)
		{
			input = GBT;		/* The clicked button will be assigned to the user's (int) input. */
			break;
		}
		else if (red == ON)
		{
			input = RBT;
			break;
		}
		else if (yellow == ON)
		{
			input = YBT;
			break;
		}
		else if (blue == ON)
		{
			input = BBT;
			break;
		}

		if (continueSuperLoop() == FALSE)
			return 0;
	}

	/* This loop will allow the user to hold the button down for as long as they want, without
	affecting (overwriting) their next input values. */
	while (digitalRead(input) == PRESSED)
		Sleep(ONE_SEC / 50);		/* Delay time must be quick, so it will break out of the loop
									immediately after the user releases the button. Therefore the
									user does not accidentally assign buttons to the wrong inputs
									in an untimely manner when they click briefly or quickly in
									between buttons. */

	return input;
}


/* This function makes the green LED flash three times after the user wins. */
void win(void)
{
	int i;

	for (i = 1; i <= 3; i++)
	{
		digitalWrite(GLED, ON);
		Sleep(ONE_SEC / 4);
		digitalWrite(GLED, OFF);
		Sleep(ONE_SEC / 4);
	}
}


/* This function makes the red LED flash three times whenever the user presses a wrong button. */
void lose(void)
{
	int i;

	for (i = 1; i <= 3; i++)
	{
		digitalWrite(RLED, ON);
		Sleep(ONE_SEC / 4);
		digitalWrite(RLED, OFF);
		Sleep(ONE_SEC / 4);
	}
}