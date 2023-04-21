%{
  #include <limits.h>
  #include "typesynth.h"
  #include "types.h"
  #include "ex1.tab.h"
  void string_to_int(int *v, const char *s);
%}
%option noyywrap
%%
"\\begin{algo}" return BEGIN_ALGO;
"\\SET" return SET;
"\\DOFORI" return DOFORI;
"\\OD" return OD;
"\\RETURN" return RETURN;
"\\end{algo}" return END_ALGO;
"\\IF" return IF;
"\\FI" return FI;
"\\\ELSE" return ELSE;
"\\DOWHILE" return DOWHILE;
"\\SIPRO" return SIPRO;
"\\CALL" return CALL;
[[:digit:]]+               { string_to_int(&yylval.integer, yytext); return NUMBER;}
[[:blank:]]|\n
"&&"                       {return ET;}
"||"                        {return OU;}
"!"                       {return NON;}
"<"                       {return INF;}
"<="                        {return INFEQ;}
">"                       {return SUP;}
">="                        {return SUPEQ;}
"="                        {return EQ;}
"!="                        {return NEQ;}
"true"                      {return VRAI;}
"false"                     {return FAUX;}
([a-zA-Z][a-zA-Z0-9_]*)|([_][a-zA-Z][a-zA-Z0-9_]*)  {char *buf = malloc(strlen(yytext)+1);
                                                      if(buf == NULL){
                                                        
                                                      }
                                                      strcpy(buf,yytext);
                                                      yylval.chaine = buf;
                                                      return ID;
                                                    }
.                       { return yytext[0]; } /* point (".") toujours en dernier car consomme un caractere */
%%

void string_to_int(int *r, const char *s) {
  char *p;
  long v;
  errno = 0;
  v = strtol(s, &p, 10);
  if ( ( *p != '\0' || ( errno == ERANGE
                     && ( v == LONG_MIN || v == LONG_MAX ) ) )
       || ( v < INT_MIN || v > INT_MAX ) ) {
    fprintf(stderr, "Error converting string to int\n");
    exit(EXIT_FAILURE);
  }
  *r = v;
}