#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "engine.h"


#define BUFSIZE 256
#define MATRIX "matrix.txt"
#define BUFFER 128

/* Function prototypes */
char** parse_matrix(FILE * matrix_file, int dimension);
int          get_matrix_dimension(FILE * matrix_file);
double* convertMatrix(char ** matrix, int dimension);


int main(){
	   /* Variables */
	int error = 0, row = 0, column = 0, dimension=0;
	//int i;
	FILE * matrix_file = NULL;
	char ** matrix = NULL;
	double* myMatrix;
	Engine *ep = NULL; // A pointer to a MATLAB engine object
    mxArray *testArray1 = NULL, *PageRank=NULL, *result = NULL; // mxArray is the fundamental type underlying MATLAB data
	char buffer[BUFSIZE + 1];
	
	double MATLABMatrix[BUFSIZE][BUFSIZE]; 

	error = fopen_s(&matrix_file, MATRIX, "r");
	if (error) {
		fprintf(stderr, "Unable to open file: %s\n", MATRIX);
		system("pause");
		return 1;
	}

	if (matrix_file) {
		dimension = get_matrix_dimension(matrix_file);	//gets maze dimension
		matrix = parse_matrix(matrix_file, dimension);	//copies maze to memory (calloc)

		//printf("dimension is: %d\n", dimension);

		 //for(i = 0; i < dimension*dimension; i++){
			//	  printf("%f ", myMatrix[i]);
			//  printf("\n");
		 // }
	}

	else {
		fprintf(stderr, "Unable to parse matrix file: %s\n", MATRIX);
		system("pause");
		return 1;
	}

	myMatrix = convertMatrix(matrix, dimension);

//for(i = 0; i < dimension*dimension; i++)
//			printf("%f ", myMatrix[i]);

   /* Starts a MATLAB process */
        if ( !(ep = engOpen(NULL)) ) {
          fprintf(stderr, "\nCan't start MATLAB engine\n");
          system("pause");
          return 1;
        }

		 testArray1 = mxCreateDoubleMatrix(dimension, dimension, mxREAL);
		 PageRank = mxCreateDoubleMatrix(dimension, dimension, mxREAL);

		  memcpy((void*) mxGetPr(testArray1), (void *)myMatrix, dimension*dimension * sizeof(double));

		  if ( engPutVariable(ep, "testArray1", testArray1) ) {
          fprintf(stderr, "\nCannot write test array to MATLAB \n");
          system("pause");
          exit(1); // Same as return 1;
        }

		 engEvalString(ep, "[rows, columns] = size(testArray1)");
		 engEvalString(ep, "dimension = size(testArray1, 1)");
		 engEvalString(ep, "columnsums = sum(testArray1, 1)");
		 engEvalString(ep, "p = 0.85");
		 engEvalString(ep, "zerocolumns = find(columnsums~=0)");
		 engEvalString(ep, "D = sparse( zerocolumns, zerocolumns, 1./columnsums(zerocolumns), dimension, dimension)");
		 engEvalString(ep, "StochasticMatrix = testArray1 * D");
		 engEvalString(ep, "[row, column] = find(columnsums==0)");
		 engEvalString(ep, "StochasticMatrix(:, column) = 1./dimension");
		 engEvalString(ep, "Q = ones(dimension, dimension)");
		 engEvalString(ep, "TransitionMatrix = p * StochasticMatrix + (1 - p) * (Q/dimension)");
		 engEvalString(ep, "PageRank = ones(dimension, 1)");
		 engEvalString(ep, "for i = 1:100 PageRank = TransitionMatrix * PageRank; end");
		 engEvalString(ep, "PageRank = PageRank / sum(PageRank)");
	

		 
		printf("\nRetrieving PageRank\n");
        if ((result = engGetVariable(ep,"PageRank")) == NULL) {
          fprintf(stderr, "\nFailed to retrieve PageRank\n");
          system("pause");
          exit(1);
        } 
        else {
          size_t sizeOfResult = mxGetNumberOfElements(result);
          size_t i = 0;
          printf("The PageRank is:\n");
		  printf("Node   Rank \n");
          for (i = 0; i < sizeOfResult; ++i) {
            printf("%d   %f ", (i+1),*(mxGetPr(result) + i) );
				printf("\n");
          }
		  printf("\n");
        }

		if ( engOutputBuffer(ep, buffer, BUFSIZE) ) {
          fprintf(stderr, "\nCan't create buffer for MATLAB output\n");
          system("pause");
          return 1;
        }
        buffer[BUFSIZE] = '\0';

		engEvalString(ep, "whos"); // whos is a handy MATLAB command that generates a list of all current variables
        printf("%s\n", buffer);

		mxDestroyArray(testArray1);
        mxDestroyArray(result);
        testArray1 = NULL;

        result = NULL;
        if ( engClose(ep) ) {
          fprintf(stderr, "\nFailed to close MATLAB engine\n");
        }


		free(matrix);
		free(myMatrix);
		matrix=NULL;
		myMatrix=NULL;

		system("pause"); // So the terminal window remains open long enough for you to read it
        return 0; // Because main returns 0 for successful completion

	
} 


int get_matrix_dimension(FILE* matrix_file)  {

	int dimension = 0;
	char line_buffer[BUFFER];

	dimension = strlen(fgets(line_buffer, BUFFER, matrix_file));

	fseek(matrix_file, 0, SEEK_SET);

	return (dimension/2);
}

// Allocates memory for matrix, and copies contents of text file into the matrix.
char** parse_matrix(FILE * matrix_file, int dimension)
{
	/* Variables */
	char         line_buffer[BUFFER];
	int          row = 0,
		column = 0;
	char ** matrix = NULL;


	matrix = (char **)calloc(dimension, sizeof(char*));				// Allocate memory for rows. Matrix points to the rows, each row points to an array

	for (row = 0; row < dimension; ++row) {
		matrix[row] = (char*)calloc(dimension*2, sizeof(char));		// Allocate memory for each row
	}

	row = 0;
	while (fgets(line_buffer, BUFFER, matrix_file)) {               // Reads contents of matrix_file and copies to line_buffer, then copies to matrix
		for (column = 0; column < dimension*2; column++) {
			matrix[row][column] = line_buffer[column];
		}
		row++;
	}
	return matrix;
}

double* convertMatrix(char ** matrix, int dimension)
{
	double* myMatrix=NULL ;
	int i=0, row = 0, column=0;

	myMatrix = (double*)calloc(dimension*dimension, sizeof(double));		// Allocate memory for a 1D array

		//myMatrix[row] = (double*)calloc(dimension, sizeof(double));
	
		for(row=0;row<dimension;row++){                                  // Store contents of matrix into a 1D array, myMatrix
			for (column=0; column <dimension*2; column+=2){
				myMatrix[i] = (double)(matrix[row][column] - '0');			// Subtract offset of char to find the equivalent number
				i++;
				}
		}

	return myMatrix;
}