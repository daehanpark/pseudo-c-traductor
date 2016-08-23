/*****************
 * Declaraciones *
 ****************/ 

%{
	#include <stdio.h>
	#include <stdlib.h>
	#include "sintactico.tab.h"	
	
	int linea=0;
	char* formato="";
	char* aux="" ;
%}


obviar " "
letra_ [A-Za-z_]
digito [0-9]
comilla "\""
cadena	{comilla}([ ]*.*[ ]*)*{comilla}
salto "\n"
tab "\t"
identificador {letra_}({letra_}|{digito})*
numero {digito}+(\.{digito}*)?(E[+-]?{digito}+)?

%%

{obviar}		{}
"leer"			{ return LEER; }
"escribir"		{ return ESCRIBIR; }
"para"			{ return PARA; }
"mientras"		{ return MIENTRAS;}
"hacer"			{ return HACER;}
"si"			{ return SI;}
"sino"			{ return SINO;}
"entero"		{ return ENTERO; }
"real"			{ return REAL; }
"caracter"		{ return CARACTER; }
"+"			{ return (SUMA); }
"-"			{ return (RESTA); }
"*"			{ return (MULT); }
"/"			{ return (DIV); }
"("			{ return PAR_IZQ; }
")"			{ return PAR_DER; }
"{"			{ return LLAVE_ABRE; }
"}"			{ return LLAVE_CIERRA; }
","			{ return COMA; }
"<="			{ return (MENOR_I); }
">="			{ return (MAYOR_I); }
"<"			{ return (MENOR); }
">"			{ return (MAYOR); }
"!="			{ return (DIFERENTE); }
"!"			{ return (NOT); }
"=="			{ return (IGUAL_IGUAL); }
"||"			{ return (OR); }
"&&"			{ return (AND); }
"="			{ return IGUAL; }
";"			{ return FININST; }
{identificador}		{ yylval.texto = strdup(yytext); return ID; }
{numero}		{ yylval.texto = strdup(yytext); return NUM;}
{cadena}		{ yylval.texto = strdup(yytext); return CADENA;}
{salto}			{ linea = linea + 1;return SALTO; }
{tab}			{ return TAB; }


%%
