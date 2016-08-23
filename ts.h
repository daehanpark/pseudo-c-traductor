/* Tipo de Datos para los nodos en la cadena de símbolos. */

#define INT 1
#define FLOAT 2
#define CHAR 3

struct token {
   char *nombre; // nombre del símbolo 
   int tipo; // Tipos de token: INT CHAR FLOAT
   union    {
      double numero; // Valor de una variable
   } valor;
   struct token *next; /* campo de enlace */
};

typedef struct token token;

/* Tabla de símbolos: una cadena de estructuras token. */
extern token *ts;
token *putToken (token*,char *, int);
token *getToken (token*,char *);
void deleteTS(token*);
void showTS(token*);
int get_type(token*, char *);
char* get_identifier_by_type(int);
int check_equal_types(token*);

int check_equal_types(token* ts){
	token *ptr;
	int type;
	if(ts != NULL){type = ts->tipo;} //si la tabla de simbolos no esta vacia
	for (ptr = ts; ptr != NULL; ptr = ptr->next){
	if (type != ptr->tipo)		//si tipo inicial es diferente de tipo actual
		return 0; 
	}
	return 1;	//si son de igual tipo todos los tokens, si ts es NULL tambien entonces retorna 0
}

char* get_identifier_by_type(int type){
	switch(type){
		case INT:
			return "%d";
		case FLOAT:
			return "%f";
		case CHAR:
			return "%c";
		default:
			return "--";
	}
}

int get_type(token* ts, char * var){
	token* ptr = getToken(ts,var);
	if(ptr != NULL){
		return ptr->tipo;
	}
	else{
		return 0;
	}
}

void showTS(token* ts) {
   token *ptr = ts;
   
   printf("\nTokens almacenados en la tabla de símbolos <TIPO, NOMBRE>:\n");
   
   while(ptr != NULL) {

	if(ptr->tipo == INT)
		printf("<  ENTERO , %s >", ptr->nombre);
	if(ptr->tipo == FLOAT)
		printf("<  REAL , %s >", ptr->nombre);
	if(ptr->tipo == CHAR)
		printf("<  CARACTER , %s >", ptr->nombre);
	ptr = ptr->next;
	printf("\n");
   }
   printf("\n");
}


/* 
   Inicialización de la tabla de símbolos:
   1.- Copiado de las palabras reservadas del lenguaje.
*/

token* init_table (token* ts) {
   return putToken(ts,"variable", INT);
}

token * putToken (token* ts, char *name, int type) {
   token *ptr;
   ptr = (token *) malloc (sizeof (token));
   
   ptr->nombre = (char *) malloc (strlen (name) + 1);
   strcpy (ptr->nombre, name);
   ptr->tipo = type;
   //ptr->valor.numero = value;

   ptr->next = ts;
   ts = ptr;
   return ptr;
}

token * getToken (token* ts, char *name) {
   token *ptr;
   for (ptr = ts; ptr != NULL; ptr = ptr->next){
      if (strcmp (ptr->nombre, name) == 0)
         return ptr;
   }
   return 0;
}

void deleteTS(token* ts) {
	token *ptr = ts;
	
	while(ptr != NULL) {
		ptr = ptr->next;
		ts->next=NULL;
		free(ts);
		ts = ptr;
   	}
	ts=NULL;
}
