%{

/********************** 
 * Declaraciones en C *
 **********************/


	#include <stdio.h>
	#include <stdlib.h>
	#include <math.h>
	#include "string.h"
	#include "ts.h"
	#define YYDEBUG 1
	extern int yylex(void);
	extern char *yytext;
	extern int linea;
	extern FILE *yyin;
	extern FILE *yyout;
	void yyerror(char *);
	char* report_syntax_error();
	void report_coma();
	int syntax_error_flag;
	int semantic_error_flag;
	void define_variable(char *, char *);
	void report_not_declared_variable(char*);
	void report_declared_variable(char*);
	void ts_op_insert(char* nombre);
	void report_conflicting_types();
	void report_conflicting_asignment();

/* Tabla de símbolos: Lista de nodos tipo token. */
	token *ts;
	token *ts_op;
%}

/*************************
  Declaraciones de Bison *
 *************************/


%union
{
	float real;
	int numero;
	char* texto;
}


//Estructuras
%token <texto> PARA
%token <texto> MIENTRAS
%token <texto> HACER
%token <texto> SI
%token <texto> SINO

//Delimitadores
%token <texto> LLAVE_ABRE
%token <texto> LLAVE_CIERRA
%token <texto> PAR_IZQ
%token <texto> PAR_DER
%token <texto> FININST
%token <texto> COMA
%token <texto> SALTO
%token <texto> TAB

//OPERADORES ARITMETICOS
%token <texto> SUMA
%token <texto> RESTA
%token <texto> MULT
%token <texto> DIV
%token <texto> IGUAL

//OPERADORES LOGICOS
%token <texto> MENOR
%token <texto> MENOR_I
%token <texto> MAYOR
%token <texto> MAYOR_I
%token <texto> IGUAL_IGUAL
%token <texto> NOT
%token <texto> DIFERENTE
%token <texto> OR
%token <texto> AND

//TIPOS
%token <texto> ENTERO
%token <texto> REAL
%token <texto> CARACTER

//VARIABLES CONSTANTES
%token <texto> NUM
%token <texto> ID
%token <texto> CADENA

//IO
%token <texto> ESCRIBIR
%token <texto> LEER

//VARIABLES
%type <texto> sentencias
%type <texto> sentencia
%type <texto> formatos
%type <texto> formato
%type <texto> tipo
%type <texto> escribir
%type <texto> leer
%type <texto> operacion
%type <texto> op_arit
%type <texto> op_log
%type <texto> asignacion
%type <texto> operador_a
%type <texto> operador_log
%type <texto> var_const
%type <texto> declaracion
%type <texto> repeticion
%type <texto> decision
%type <texto> sino
%type <texto> repita_para
%type <texto> repita_mientras
%type <texto> hacer_mientras

%left RESTA

/*Reglas de la gramatica*/

%start programa

%%


programa 	: sentencias {	fprintf (yyout, "/*Traductor a Lenguaje C*/\n");
				if(semantic_error_flag){
					fprintf (yyout, "/*Se detectaron %d errores semanticos en la traducción.\n",semantic_error_flag);
					fprintf (yyout, "Ponga atencion a las advertencias mostradas en la terminal*/\n");
				}else if(syntax_error_flag){
					fprintf (yyout, "/*Se detectaron %d errores sintacticos en la traducción.\n",syntax_error_flag);
					fprintf (yyout, "Se recomienda solucionarlos*/\n");
					fprintf (yyout, "#include <stdio.h>\n\nint main(){\n%s\n\treturn 0;\n}",$1); free($1);
				}else if(semantic_error_flag == 0){
					fprintf (yyout, "/*Traduccion correcta*/\n");
					fprintf (yyout, "#include <stdio.h>\n\nint main(){\n%s\n\treturn 0;\n}",$1); free($1);
				} 
		};

sentencias	: sentencias sentencia 	{ $$ = malloc(strlen($1) + strlen($2) + 1); strcpy($$,$1); strcat($$,$2); }
		| sentencia 		{ $$ = malloc(strlen($1) + 1); strcpy($$,$1);  } ;

sentencia 	: declaracion FININST 	{ $$ = malloc(strlen($1) + 2); strcpy($$,$1); strcat($$,";"); }
		| escribir		{ $$ = malloc(strlen($1) + 1); strcpy($$,$1); }
		| leer			{ $$ = malloc(strlen($1) + 1); strcpy($$,$1); }
		| decision 		{ $$ = malloc(strlen($1) + 1); strcpy($$,$1); }
		| repeticion 		{ $$ = malloc(strlen($1) + 1); strcpy($$,$1); }
		| operacion FININST 	{
						$$ = malloc(strlen($1) + 2); strcpy($$,$1); strcat($$,";");deleteTS(ts_op); ts_op=NULL;
					}
		| operacion COMA 	{ $$ = malloc(strlen($1) + 2); strcpy($$,$1); strcat($$,";"); report_coma();}
		| formatos		{ $$ = malloc(strlen($1) + 1); strcpy($$,$1);}	
		| error FININST		{ $$ = report_syntax_error();}
		| error SALTO		{ $$ = report_syntax_error();};

formatos	: formatos formato	{ $$ = malloc(strlen($1) + strlen($2) + 1); strcpy($$,$1); strcat($$,$2); }
		| formato		{ $$ = malloc(strlen($1) + 1); strcpy($$,$1); };

formato		: SALTO			{ $$ = malloc(strlen("\n") + 1); strcpy($$,"\n");}
		| TAB			{ $$ = malloc(strlen("\t") + 1); strcpy($$,"\t");}
		| /**/			{ $$ = malloc(strlen("") + 1); strcpy($$,"");};

declaracion 	: tipo ID 		{ 
						$$ = malloc(strlen($1) + strlen($2) + 2);
						strcpy($$,$1); strcat($$," "); strcat($$,$2);
						define_variable($1,$2);
					};

tipo		: ENTERO 		{ $$ = malloc(strlen("int") + 1); strcpy($$,"int");}
		| REAL			{ $$ = malloc(strlen("float") + 1); strcpy($$,"float"); }
		| CARACTER		{ $$ = malloc(strlen("char") + 1); strcpy($$,"char"); };

operacion 	: op_arit 	{	$$ = malloc(strlen($1) + 1); strcpy($$,$1); 
					if(check_equal_types(ts_op) == 0){ //si hay tipos distintos en la operacion
							report_conflicting_types();
					} 
				}
		| op_log 	{	$$ = malloc(strlen($1) + 1); strcpy($$,$1); 
					if(check_equal_types(ts_op) == 0){ //si hay tipos distintos en la operacion
							report_conflicting_types();
					} 
				}
		| asignacion 	{	$$ = malloc(strlen($1) + 1); strcpy($$,$1); 
					if(check_equal_types(ts_op) == 0){ //si hay tipos distintos en la operacion
							report_conflicting_asignment();
					} 
				};

op_arit		: var_const			{ $$ = malloc(strlen($1) + 1); strcpy($$,$1);}
		| op_arit operador_a op_arit 	{ $$ = malloc(strlen($1) + strlen($2) + strlen($3) + 1);
							strcpy($$,$1); strcat($$,$2); strcat($$,$3); }
		| PAR_IZQ op_arit PAR_DER 	{ $$ = malloc(strlen("(") + strlen($2) + strlen(")") + 1); 
							strcpy($$,"("); strcat($$,$2); strcat($$,")"); }
		| RESTA op_arit 		{ $$ = malloc(strlen("-") + strlen($2) + 1); 
							strcpy($$,"-"); strcat($$,$2); };

operador_a	: SUMA 			{ $$ = malloc(strlen(" + ") + 1); strcpy($$," + "); }
		| RESTA 		{ $$ = malloc(strlen(" - ") + 1); strcpy($$," - "); }
		| MULT 			{ $$ = malloc(strlen(" * ") + 1); strcpy($$," * "); }
		| DIV 			{ $$ = malloc(strlen(" / ") + 1); strcpy($$," / "); };			

var_const	: ID 		{
					int type = get_type(ts, $1);
					if( type != 0){/*Si si existe el token*/
						ts_op = putToken(ts_op,$1, type);
						$$ = malloc(strlen($1) + 1); strcpy($$,$1);
					}else{
						report_not_declared_variable($1);
						$$ = "";			
					}
				}
		| NUM 			{
						ts_op_insert($1);
						$$ = malloc(strlen($1) + 1); strcpy($$,$1);
					};

op_log		: op_log operador_log op_log	{ $$ = malloc(strlen($1) + strlen($2) + strlen($3) + 1); //op_log
							strcpy($$,$1); strcat($$,$2); strcat($$,$3); }
		| var_const			{ $$ = malloc(strlen($1) + 1); strcpy($$,$1); }
		| PAR_IZQ op_log PAR_DER	{ $$ = malloc(strlen("(") + strlen($2) + strlen(")") + 1);
							strcpy($$,"("); strcat($$,$2); strcat($$,")"); }
		| NOT op_log 			{ $$ = malloc(strlen("!") + strlen($2) + 1);
							strcpy($$,"!"); strcat($$,$2); };

operador_log	: MENOR			{ $$ = malloc(strlen(" < ") + 1); strcpy($$," < "); }
		| MENOR_I		{ $$ = malloc(strlen(" <= ") + 1); strcpy($$," <= "); }
		| MAYOR			{ $$ = malloc(strlen(" > ") + 1); strcpy($$," > "); }
		| MAYOR_I		{ $$ = malloc(strlen(" >= ") + 1); strcpy($$," >= "); }
		| IGUAL_IGUAL		{ $$ = malloc(strlen(" == ") + 1); strcpy($$," == "); }
		| DIFERENTE		{ $$ = malloc(strlen(" != ") + 1); strcpy($$," != "); }
		| AND			{ $$ = malloc(strlen(" && ") + 1); strcpy($$," && "); }
		| OR			{ $$ = malloc(strlen(" || ") + 1); strcpy($$," || "); };

asignacion	: ID IGUAL operacion 	{	int type = get_type(ts, $1);
						if( type != 0){
							$$ = malloc(strlen($1) + strlen(" = ") + strlen($3) + 1);
							strcpy($$,$1); strcat($$," = "); strcat($$,$3);
							ts_op = putToken(ts_op,$1, type);
						}else{
							report_not_declared_variable($1);
							$$ = "";			
						}
					};

decision	: SI PAR_IZQ operacion PAR_DER formatos LLAVE_ABRE sentencias LLAVE_CIERRA formatos sino
			{ $$ = malloc(strlen("if(") + strlen($3) + strlen("){") + strlen($7)+ strlen("}") + strlen($9) + strlen($10) + 1);
			strcpy($$,"if("); strcat($$,$3); strcat($$,"){"); strcat($$,$7); strcat($$,"}"); strcat($$,$9); strcat($$,$10);}

		| SI PAR_IZQ operacion PAR_DER formatos LLAVE_ABRE sentencias LLAVE_CIERRA
			{ $$ = malloc(strlen("if(") + strlen($3) + strlen("){") + strlen($7)+ strlen("}")  + 1);
				strcpy($$,"if("); strcat($$,$3); strcat($$,"){"); strcat($$,$7); strcat($$,"}");}; 


sino		: SINO formatos LLAVE_ABRE sentencias LLAVE_CIERRA 
			{ $$ = malloc(strlen("else{") + strlen($4) + strlen("}") + 1);
				strcpy($$,"else{"); strcat($$,$4); strcat($$,"}"); };


repeticion	: repita_para		{ $$ = malloc(strlen($1) + 1); strcpy($$,$1); }
		| repita_mientras	{ $$ = malloc(strlen($1) + 1); strcpy($$,$1); }
		| hacer_mientras	{ $$ = malloc(strlen($1) + 1); strcpy($$,$1); };
	

repita_para	: PARA PAR_IZQ operacion FININST operacion FININST operacion PAR_DER formatos LLAVE_ABRE sentencias LLAVE_CIERRA
			{ $$ = malloc(strlen("for(") +							
				strlen($3) + strlen(";") + strlen($5) + strlen(";") + strlen($7) + 	
				strlen("){") + strlen($11)+ strlen("}") + 1);				
				strcpy($$,"for(");
				strcat($$,$3); strcat($$,";"); strcat($$,$5); strcat($$,";"); strcat($$,$7); 
				strcat($$,"){"); strcat($$,$11); strcat($$,"}");};


repita_mientras : MIENTRAS PAR_IZQ operacion PAR_DER formatos LLAVE_ABRE sentencias LLAVE_CIERRA
			{ $$ = malloc(strlen("while(") + strlen($3) + strlen("){") + strlen($7) + strlen("}") + 1);
				strcpy($$,"while("); strcat($$,$3); strcat($$,"){"); strcat($$,$7); strcat($$,"}");};


hacer_mientras	: HACER formatos LLAVE_ABRE sentencias LLAVE_CIERRA formatos MIENTRAS PAR_IZQ operacion PAR_DER FININST
			{ $$ = malloc(strlen("do{") + strlen($4) + strlen("}while(") + strlen($9) + strlen(");") + 1);
				strcpy($$,"do{"); strcat($$,$4); strcat($$,"}while("); strcat($$,$9); strcat($$,");");};

escribir	: ESCRIBIR PAR_IZQ CADENA PAR_DER FININST	
			{$$ = malloc(strlen("printf(") + strlen($3) + strlen(");") + 1); strcpy($$,"printf(");
				strcat($$,$3);strcat($$,");");}
		| ESCRIBIR PAR_IZQ ID PAR_DER FININST
			{	int type = get_type(ts, $3);
				if( type != 0){
					$$ = malloc(strlen("printf(\"%d\",") + strlen($3) + strlen(");") + 1); strcpy($$,"printf(\"");
					strcat($$,get_identifier_by_type(type));strcat($$,"\",");strcat($$,$3);strcat($$,");");
				}else{
					report_not_declared_variable($3);
					$$ = "";			
				}
			};

leer		: LEER PAR_IZQ ID PAR_DER FININST
			{	int type = get_type(ts, $3);
				if( type != 0){
					$$ = malloc(strlen("scanf(\"%d\",&") + strlen($3) + strlen(");") + 1); strcpy($$,"scanf(\"");
					strcat($$,get_identifier_by_type(type));strcat($$,"\",&");strcat($$,$3);strcat($$,");");
				}else{
					report_not_declared_variable($3);
					$$ = "";			
				}
			};
%%
/**********************
 * Codigo C Adicional *
 **********************/
void yyerror(char *s){
	printf("\n\nError sintactico %s \n\nEn la linea: %d \n\n",s,linea);
	//fclose(yyin);
	//fclose(yyout);
	
}

void report_coma(){
	printf("\n\nAdvertencia: Sustituida una coma por un punto y coma\n\nEn la linea: %d \n\n",linea);
}

char* report_syntax_error(){
	char l[33];(char)( ((int) '0') + linea );
	char* aux = malloc(strlen("//Error sintáctico en la linea del archivo de entrada ")+strlen(l)+2); 
	sprintf(aux, "//Error sintáctico en la linea %d del archivo de entrada\n", linea);
	syntax_error_flag = syntax_error_flag + 1;
	return aux;
}

void report_declared_variable(char* var){
	printf("\nDetectado un error semantico en la linea %d, la variable <%s>ya fue declarada previamente\n", linea, var);
	semantic_error_flag = semantic_error_flag + 1;
}

void report_not_declared_variable(char* var){
	printf("\nDetectado un error semantico en la linea %d, la variable <%s> no fue declarada\n", linea, var);
	semantic_error_flag = semantic_error_flag + 1;
}

void report_conflicting_types(){
	printf("\nAdvertencia un error semantico en la linea %d",linea);
	printf(", está haciendo una operacion con tipos de datos diferentes\n");
}

void report_conflicting_asignment(){
	printf("\nAdvertencia un error semantico en la linea %d",linea);
	printf(", está haciendo una asignacion con tipos de datos diferentes\n");
}

void ts_op_insert(char* nombre){
	if(getToken(ts_op,nombre) == NULL){
		if(strchr(nombre, '.') != NULL){
			ts_op = putToken(ts_op,nombre,FLOAT);
		}
		else{
			ts_op = putToken(ts_op,nombre,INT);
		}
	}
}

void define_variable(char* tipo, char* nombre){
	if(getToken(ts,nombre) == NULL){
		if(strcmp(tipo,"int") == 0){
			ts = putToken(ts,nombre,INT);
		}
		if(strcmp(tipo,"float") == 0){
			ts = putToken(ts,nombre,FLOAT);
		}
		if(strcmp(tipo,"char") == 0){
			ts = putToken(ts,nombre,CHAR);
		}
	}
	else{
		report_declared_variable(nombre);
	}
}

int main(int argc,char **argv){
	yydebug = 0;
	linea = 1;
	syntax_error_flag = semantic_error_flag = 0;
	if (argc>1)
		yyin=fopen(argv[1],"rt");
	else
		yyin=fopen("entrada.txt","rt");
		
	yyout = fopen("salida.c","w");
	yyparse();
	deleteTS(ts);

	return 0;
}
