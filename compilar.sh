#!/bin/bash
bison -d -v sintactico.y
flex lexico.l
cc lex.yy.c sintactico.tab.c -o analizador -lfl -lm

