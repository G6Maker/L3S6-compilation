%{
  #include <ctype.h>
  #include <stdlib.h>
  #include <stdio.h>
  #include "typesynth.h"
  #include <stdarg.h>
  #include <limits.h>
  #include <string.h>
  #include "types.h"
  #include "stable.h"
  #define MAXBUF 50
  int yydebug=0;
  int yylex(void);
  void yyerror(char const *);
  static unsigned int new_label_number();
  static void create_label(char *buf, size_t buf_size, const char *format, ...);
  void fail_with(const char *format, ...);
  //#define STACK_CAPACITY 50
  //static int stack[STACK_CAPACITY];
  //static size_t stack_size = 0;
%}
%union {
int integer;
type_synth type;
symbol_type st;
char *chaine;
unsigned int uinteger;
}
%token ID L_INT L_BOOL END_ALGO RETURN OD DOFORI SET BEGIN_ALGO IF FI ELSE DOWHILE SIPRO CALL
%token <integer> NUMBER
%type<type> expr
//%type<type> ligne
//%type<type> decl
//%type<st> type
%type<chaine> ID
%type<uinteger> fixif
%type<uinteger> fix
%token ET OU NON INF INFEQ SUP SUPEQ EQ NEQ VRAI FAUX
%left OU
%left ET
%left '+' '-'
%left '*' '/'
%left INF INFEQ SUP SUPEQ EQ NEQ
%precedence END_ALGO
//%precedence NON_ELSE
//%precedence ELSE
%precedence NON
%start starter
%%
starter: SIPRO '{' ID '}' '{' {//debut du programme
                              // @TODO : verfier que le nom de la fonction est pas deja defini
                              printf("\tconst ax,debut\n");
                              printf("\tjmp ax\n");
                              char filename[strlen($3)+5];
                              strcpy(filename,$3);
                              strcpy(filename+strlen($3),".asm");
                              //ecrit sur la sortie standard tout ce qui est lu dans le fichier filename
                              FILE *f = fopen(filename, "r");
                              if (f == NULL) {
                                  perror("Impossible d'ouvrir le fichier\n");
                                  exit(1);
                              }
                              char buf[MAXBUF];
                              while(fgets(buf, MAXBUF, f)){
                                 printf("%s", buf);
                               }
                              fclose(f);
                              printf(":debut\n");
                              printf("\tconst bp,pile\n");
                              printf("\tconst sp,pile\n");
                              printf("\tconst ax,2\n");
                              printf("\tsub sp,ax\n");
                              } numbers '}' {
                                    printf("\tconst ax,fonc:%s:debut\n", $3);
                                    printf("\tcall ax\n");
                                    //fin du programme
                                    printf("\tconst dx,decl:after:retour:1\n");
                                    printf("\tjmp dx\n");
                                    printf(":var:retour\n");
                                    printf("@int 1\n");
                                    printf(":decl:after:retour:1\n");
                                    printf("\tpop ax\n"); //valeur du ret normalement
                                    printf("\tconst dx,var:retour\n");
                                    printf("\tstorew ax,dx\n");
                                    printf("\tcallprintfd dx\n");
                                    printf("\tend\n");
                                    printf(":pile\n");
                                    printf("@int 0\n");
                                   }
| function
;
numbers:
  numbers ',' NUMBER { printf("\tconst ax,%d\n", $3);
                       printf("\tpush ax\n");
                     }
| NUMBER { printf("\tconst ax,%d\n", $1);
           printf("\tpush ax\n");
         }
| %empty
;
//permet d'avoir plusieurs fonction definie
function: function BEGIN_ALGO '{' ID {printf("\tconst dx,fonc:%s:fin\n",$4); //attention à ne pas tomber dans la fonction sans demander
                                      printf("\tjmp dx\n"); //attention a la chute !
                                      printf(":fonc:%s:debut\n",$4);
                                      } '}' '{' ids '}' function END_ALGO { printf("\tret\n");//ret de toute fonction
                                                                            printf(":fonc:%s:fin\n",$4);}
| instrs
;
ids: //peut etre un probleme ici
  ID ',' ids {symbol_table_entry *ste;
                              if((ste = search_symbol_table($1)) == NULL) {
                                ste = new_symbol_table_entry($1);
                                unsigned int n = new_label_number();
                                ste->desc[0] = INT_T;
                                printf(";variable %s non declaree\n",$1);
                                printf("\tconst dx,decl:after:%s:%d\n",$1, n);
                                printf("\tjmp dx\n");
                                printf(":var:%s\n",$1);
                                printf("@int 1\n");
                                printf(":decl:after:%s:%d\n",$1, n);
                                printf("\tpop bx\n"); //valeur du call
                                printf("\tpop ax\n"); //valeur entrée avec le SIPRO
                                printf("\tpush bx\n"); //valeur du call
                                printf("\tconst dx,var:%s\n",$1);
                                printf("\tstorew ax,dx\n"); //peut etre pas le bon sens ax,dx
                              } else {
                                if (ste->desc[0] == BOOL_T) {
                                  fail_with("%s is not of type", $1);
                                } else {
                                  printf(";variable %s declaree\n",$1);
                                  printf("\tpop bx\n"); //valeur du call
                                  printf("\tpop ax\n"); //valeur entrée avec le SIPRO
                                  printf("\tpush bx\n"); //valeur du call
                                  printf("\tconst dx,var:%s\n",$1);
                                  printf("\tstorew ax,dx\n"); // peut etre pas le bon sens ax,dx
                                }
                              }
              }
| ID {symbol_table_entry *ste;
                              if((ste = search_symbol_table($1)) == NULL) {
                                ste = new_symbol_table_entry($1);
                                unsigned int n = new_label_number();
                                ste->desc[0] = INT_T;
                                printf(";variable %s non declaree\n",$1);
                                printf("\tconst dx,decl:after:%s:%d\n",$1, n);
                                printf("\tjmp dx\n");
                                printf(":var:%s\n",$1);
                                printf("@int 1\n");
                                printf(":decl:after:%s:%d\n",$1, n);
                                printf("\tpop bx\n"); //valeur du call
                                printf("\tpop ax\n"); //valeur entrée avec le SIPRO
                                printf("\tpush bx\n"); //valeur du call
                                printf("\tconst dx,var:%s\n",$1);
                                printf("\tstorew ax,dx\n"); //peut etre pas le bon sens ax,dx
                              } else {
                                if (ste->desc[0] == BOOL_T) {
                                  fail_with("%s is not of type", $1);
                                } else {
                                  printf(";variable %s declaree\n",$1);
                                  printf("\tpop bx\n"); //valeur du call
                                  printf("\tpop ax\n"); //valeur entrée avec le SIPRO
                                  printf("\tpush bx\n"); //valeur du call
                                  printf("\tconst dx,var:%s\n",$1);
                                  printf("\tstorew ax,dx\n"); // peut etre pas le bon sens ax,dx
                                }
                              }
      }
;
instrs: 
instr instrs
| %empty
;
instr:
SET {
    printf(";set\n");
    }'{' ID '}' '{' expr '}' { symbol_table_entry *ste;
                              if((ste = search_symbol_table($4)) == NULL) {
                                ste = new_symbol_table_entry($4);
                                unsigned int n = new_label_number();
                                ste->desc[0] = (T_BOOL==$7?BOOL_T:INT_T);
                                printf(";variable %s non declaree\n",$4);
                                printf("\tconst dx,decl:after:%s:%d\n",$4, n);
                                printf("\tjmp dx\n");
                                printf(":var:%s\n",$4);
                                printf("@int 1\n");
                                printf(":decl:after:%s:%d\n",$4, n);
                                printf("\tpop ax\n"); //valeur de expr $7
                                printf("\tconst dx,var:%s\n",$4);
                                printf("\tstorew ax,dx\n"); //peut etre pas le bon sens ax,dx
                              } else {
                                if ((ste->desc[0] == BOOL_T && $7 == T_INT) || (ste->desc[0] == INT_T && $7 == T_BOOL)) {
                                  fail_with("%s is not of type", $4);
                                } else {
                                  printf(";variable %s declaree\n",$4);
                                  printf("\tpop ax\n"); //valeur de expr $7 
                                  printf("\tconst dx,var:%s\n",$4);
                                  printf("\tstorew ax,dx\n"); // peut etre pas le bon sens ax,dx
                                }
                              }
                              printf(";set fin\n");
                            }
| DOFORI {
    printf(";dofori\n");
    } '{' fix ID '}' '{' expr { unsigned int n = new_label_number();
                                  printf("\tconst ax,decl:after:%d\n" //on imagine que l'id existe pas
                                  "\tjmp ax\n"
                                  ":fonc:loop:%s:%d\n" //verifier son existance si oui juste affecter la valuer sinon la creer comme fait (avec un nom de variable like SET)
                                  "@int 1\n"
                                  ":decl:after:%d\n", n, $5, $4, n); //2 doit etre un id uniquement
                                  printf("\tpop ax\n"); //valeur de expr $8
                                  printf("\tconst dx,fonc:loop:%s:%d\n",$5,$4);
                                  printf("\tstorew ax,dx\n");
                              } 
                              '}' '{' expr { unsigned int n = new_label_number();
                                            printf("\tconst dx,decl:after:%d\n", n);
                                            printf("\tjmp dx\n");
                                            printf(":fonc:loop:var:%d\n",$4); //ajouter un id unique
                                            printf("@int 1\n"); //type de l'expr a verifier
                                            printf(":decl:after:%d\n", n);//3 doit etre un id unique
                                            printf("\tpop ax\n"); //valeur de l'expr $9
                                            printf("\tconst dx,fonc:loop:var:%d\n",$4);
                                            printf("\tstorew ax,dx\n");
                                            printf(":loop:begin:%d\n",$4);//1 id unique
                                            printf("\tconst dx,fonc:loop:%s:%u\n",$5,$4);
                                            printf("\tloadw ax,dx\n");
                                            printf("\tconst dx,fonc:loop:var:%u\n",$4);
                                            printf("\tloadw bx,dx\n");
                                            printf("\tconst dx,loop:for:end:%u\n",$4);
                                            printf("\tsless bx,ax\n");
                                            printf("\tjmpc dx\n");
                                      } '}' instrs OD { 
                                                        printf("\tconst dx,fonc:loop:%s:%d\n", $5, $4);
                                                        printf("\tloadw ax,dx\n");
                                                        printf("\tconst bx,1\n");
                                                        printf("\tadd ax,bx\n");
                                                        printf("\tstorew ax,dx\n");
                                                        printf("\tconst dx,loop:begin:%d\n",$4);//id unique
                                                        printf("\tjmp dx\n");
                                                        printf(":loop:for:end:%d\n", $4);
                                                        printf(";dofori fin\n");
                                                      }
| IF '{' expr fixif '}' instrs FI { //regarder le fixif il y a le code
                                    printf(":if:%d:else\n", $4);
                                    /*if ($3 != T_BOOL){
                                      fail_with("Error: Wrong type\n");
                                    }*/
                                    printf(";if fin\n");
                                  }
| IF '{' expr fixif '}' instrs ELSE { printf("\tconst cx,if:%d:fin\n", $4);
                                printf("\tjmp cx\n");
                                printf(":if:%d:else\n", $4);
                              } instrs FI{
                                  printf(":if:%d:fin\n", $4);
                                  /*if ($3 != T_BOOL){
                                     fail_with("Error: Wrong type\n");
                                  }//*/
                                  printf(";if fin\n");
                                  }
| RETURN '{' expr '}' {printf(";retour\n");
                       printf("\tpop bx\n"); //valeur de expr $3
                       printf("\tpop ax\n"); //valeur normalement du call empilé
                       printf("\tpush bx\n"); //valeur de expr $3
                       printf("\tpush ax\n"); //valeur normalement du call empilé*/
                       printf("\tret\n");
                       printf(";retour fin\n");
                      }
| DOWHILE {
          printf(";dowhile\n");
          }'{' fix { printf(":do:while:%d\n", $4);
                  } expr '}'{//ajouter des printf
                            if($6 == T_BOOL){ //$6 parce que le code compte !
                              printf("\tconst dx,do:while:fin:%d\n", $4);
                              printf("\tpop ax\n"); //si pas initile alors cx
                              //printf("\tcp ax,cx\n"); //inutile normalement ?
                              //printf("\tpush cx\n");
                              printf("\tconst bx,0\n");
                              printf("\tcmp ax,bx\n");
                              printf("\tjmpc dx\n"); //si ax=bx alors ca saute
                              printf(";vrai\n");
                            } else {
                            //end
                            //yyerror ?
                            }
                          } instrs OD {printf("\tconst dx,do:while:%d\n", $4);
                                                printf("\tjmp dx\n");
                                                printf(":do:while:fin:%d\n", $4);
                                                printf(";dowhile fin\n");
                                              }
| CALL '{' ID '}' '{' exprs '}' { //dans le cas ou la fonction appeler ne renvoie rien
                                printf(";call\n");
                                printf("\tconst ax,fonc:%s:debut\n", $3);
                                printf("\tcall ax\n");
                                printf(";call fin\n");
                                }
;
fix: //est de type uinteger comme fixif
%empty { unsigned int n = new_label_number();
       $$ = n;
      }
;

fixif: 
  %empty  {
                unsigned int n = new_label_number();
                printf("\tpop ax\n");
                printf("\tconst bx,0\n");
                printf("\tconst cx,if:%d:else\n", n);
                printf("\tcmp ax,bx\n");
                printf("\tjmpc cx\n");
                $$ = n;
          }
;
exprs: expr ',' exprs
| expr
|%empty
;
expr: //une expression met la valeur obtenue dans la pile
  NUMBER                { printf("\tconst ax,%d\n", $1);
                          printf("\tpush ax\n");
                          $$=T_INT; 
                        }
| '(' expr ')'         { $$ = $2; /* on fait rien car les paratheses ne font que depiler et rempiler */ }
| expr '+' expr        { if ($1 == T_INT && $3 == T_INT) { 
                          printf("\tpop bx\n"); //valeur de expr $3
                          printf("\tpop ax\n"); //valeur de expr $1
                          printf("\tadd ax,bx\n");
                          printf("\tpush ax\n"); //valeur de la somme $1+$3
                          $$ = T_INT;
                         } else { 
                           printf("\tend\n");
                           printf("\t;expr + expr\n");
                           $$ = ERR_ARITH;
                         }//*/
                       }
| expr '-' expr        { if ($1 == T_INT && $3 == T_INT) {
                           printf("\tpop bx\n"); //valeur de expr $3
                          printf("\tpop ax\n"); //valeur de expr $1
                          printf("\tsub ax,bx\n");
                          printf("\tpush ax\n"); //valeur de soustraction $1-$3
                           $$ = T_INT; 
                         } else {
                           printf("\tend\n");
                           printf("\t;expr - expr\n");
                           $$ = ERR_ARITH;
                         }//*/
                        }
| expr '*' expr        {  if ($1 == T_INT && $3 == T_INT) {
                           printf("\tpop bx\n"); //valeur de expr $3
                            printf("\tpop ax\n"); //valeur de expr $1
                            printf("\tmul ax,bx\n");
                            printf("\tpush ax\n"); //valeur de la multiplication $1*$3
                           $$ = T_INT; 
                          } else {
                            printf("\tend\n");
                            printf("\t;expr * expr\n");
                            $$ = ERR_ARITH;
                          }//*/
                        }
| expr '/' expr        {  if ($1 == T_INT && $3 == T_INT) {
                            printf("\tpop bx\n"); //valeur de expr $3
                            printf("\tpop ax\n"); //valeur de expr $1
                            printf("\tconst cx,error\n");
                            printf("\tdiv ax,bx\n");
                            printf("\tjmpe cx\n");
                            printf("\tconst cx,continue\n");
                            printf("\tjmp cx\n");
                            printf("\tconst cx,error\n");
                            printf("\tjmp cx\n");
                            printf(":errorstring\n");
                            printf("@string \"erreur\\n\"\n");
                            printf(":error\n");
                            printf("\tconst ax,errorstring\n");
                            printf("\tcallprintfs ax\n");
                            printf("\tend\n");
                            printf(":continue\n");
                            printf("\tpush ax\n"); //valeur de la division $1/$3
                            $$ = T_INT;
                          } else {
                            printf("\tend\n");
                            printf("\t;expr / expr\n");
                            $$ = ERR_ARITH;
                          }
                        }
| VRAI                  {  printf("\tconst ax,1\n"); 
                          printf("\tpush ax\n");
                          $$=T_BOOL;
                        }
| FAUX                  {  printf("\tconst ax,0\n");
                          printf("\tpush ax\n");
                          $$=T_BOOL;
                        }
| ID                    { symbol_table_entry *ste;
                          if((ste = search_symbol_table($1)) == NULL) {
                            //error
                          } else {
                            printf("\tconst dx,var:%s\n", $1);
                            printf("\tloadw ax,dx\n");
                            printf("\tpush ax\n");
                            $$ = (ste->desc[0] == BOOL_T)?T_BOOL:T_INT; //T_INT || T_BOOL */
                          }
                        }
| expr OU expr          { if ($1 == T_BOOL && $3 == T_BOOL) {
                            printf("\tpop bx\n"); //valeur de expr $3
                            printf("\tpop ax\n"); //valeur de expr $1
                            printf("\tadd ax,bx\n");
                            printf("\tpush ax\n"); //valeur du OU $1||$3
                            $$ = T_BOOL;
                          } else {
                            printf("\tend\n");
                            printf("\t;expr OU expr\n");
                            $$=ERR_TYPAGE;
                          }
                        }
| expr ET expr          { if ($1 == T_BOOL && $3 == T_BOOL) {
                            printf("\tpop bx\n"); //valeur de expr $3
                            printf("\tpop ax\n"); //valeur de expr $1
                            printf("\tmul ax,bx\n");
                            printf("\tpush ax\n"); //valeur du ET $1&&$3
                            $$ = T_BOOL;
                          } else {
                            printf("\tend\n");
                            printf("\t;expr ET expr\n");
                            $$=ERR_TYPAGE;
                          }
                        }
| expr EQ expr          { if (($1 == T_INT && $3 == T_INT) || ($1 == T_BOOL && $3 == T_BOOL)) {
                            int n = new_label_number();
                            printf("\tpop bx\n"); //valeur de expr $3
                            printf("\tpop ax\n"); //valeur de expr $1
                            printf("\tsub ax,bx\n");
                            printf("\tconst dx,vrai:%d\n", n);
                            printf("\tconst bx,0\n");
                            printf("\tcmp ax,bx\n");
                            printf("\tjmpc dx\n");
                            printf("\tpush bx\n"); //valeur de la comparaison $1==$3
                            printf("\tconst dx,fin:%d\n", n);
                            printf("\tjmp dx\n");
                            printf(":vrai:%d\n", n);
                            printf("\tconst ax,1\n");
                            printf("\tpush ax\n"); //valeur de la comparaison $1==$3
                            printf("\tconst dx,fin:%d\n", n);
                            printf("\tjmp dx\n");
                            printf(":fin:%d\n", n);
                            $$ = T_BOOL;
                          } else {
                            $$=ERR_ARITH;
                           printf("\tend\n");
                           printf("\t;expr = expr\n");
                          }
                        }
| expr NEQ expr          { if ($1 == ERR_TYPAGE || $1 == ERR_ARITH || $3 == ERR_TYPAGE || $3 == ERR_ARITH) {
                           $$=ERR_ARITH;
                           printf("\tend\n");
                           printf("\t;expr != expr\n");
                          } else {
                            int n = new_label_number();
                            printf("\tpop bx\n"); //valeur de expr $3
                            printf("\tpop ax\n"); //valeur de expr $1
                            printf("\tsub ax,bx\n");
                            printf("\tconst dx,faux:%d\n", n);
                            printf("\tconst bx,0\n");
                            printf("\tcmp ax,bx\n");
                            printf("\tjmpc dx\n");
                            printf("\tconst ax,1\n");
                            printf("\tpush ax\n"); // vrai, et ax != 0
                            printf("\tconst dx,fin:%d\n", n);
                            printf("\tjmp dx\n");
                            printf(":faux:%d\n", n); //faux
                            printf("\tconst ax,0\n");
                            printf("\tpush ax\n"); //valuer de la comparaison $1!=$3
                            printf("\tconst dx,fin:%d\n", n);
                            printf("\tjmp dx\n");
                            printf(":fin:%d\n", n);
                            $$ = T_BOOL;
                          }
                        }
| NON expr {
            if ($2 == T_BOOL) {
              int n = new_label_number();
              printf("\tpop ax\n");
              printf("\tconst bx,0\n");
              printf("\tconst dx,faux:%d\n",n);
              printf("\tcmp ax,bx\n");
              printf("\tjmpc dx\n");
              printf("\tpush bx\n"); //push 0
              printf("\tconst dx,fin:%d\n", n);
              printf("\tjmp dx\n");
              printf(":faux:%d\n",n);
              printf("\tconst ax,1\n");
              printf("\tpush ax\n");
              printf(":fin:%d\n", n);
              $$ = T_BOOL;
            }
            }
| expr SUP expr { // expr > expr
                if ($1 == T_INT && $3 == T_INT) {
                  int n = new_label_number();
                  printf("\tpop bx\n");
                  printf("\tpop ax\n");
                  printf("\tconst dx,vrai:%d\n",n);
                  printf("\tsless bx,ax\n");
                  printf("\tjmpc dx\n");
                  printf("\tconst bx,0\n");
                  printf("\tpush bx\n"); //push 0
                  printf("\tconst dx,fin:%d\n", n);
                  printf("\tjmp dx\n");
                  printf(":vrai:%d\n",n);
                  printf("\tconst ax,1\n");
                  printf("\tpush ax\n");
                  printf(":fin:%d\n", n);
                  $$= T_BOOL;
                }
                }
| expr SUPEQ expr { // expr >= expr
                if ($1 == T_INT && $3 == T_INT) {
                  int n = new_label_number();
                  printf("\tpop bx\n");
                  printf("\tpop ax\n");
                  printf("\tconst dx,faux:%d\n",n);
                  printf("\tsless ax,bx\n");
                  printf("\tjmpc dx\n");
                  printf("\tconst bx,1\n");
                  printf("\tpush bx\n"); //push 1
                  printf("\tconst dx,fin:%d\n", n);
                  printf("\tjmp dx\n");
                  printf(":faux:%d\n",n);
                  printf("\tconst ax,0\n");
                  printf("\tpush ax\n");
                  printf(":fin:%d\n", n);
                  $$= T_BOOL;
                }
                }
| expr INFEQ expr { // expr <= expr
                if ($1 == T_INT && $3 == T_INT) {
                  int n = new_label_number();
                  printf("\tpop bx\n");
                  printf("\tpop ax\n");
                  printf("\tconst dx,faux:%d\n",n);
                  printf("\tsless bx,ax\n");
                  printf("\tjmpc dx\n");
                  printf("\tconst bx,1\n");
                  printf("\tpush bx\n"); //push 1
                  printf("\tconst dx,fin:%d\n", n);
                  printf("\tjmp dx\n");
                  printf(":faux:%d\n",n);
                  printf("\tconst ax,0\n");
                  printf("\tpush ax\n");
                  printf(":fin:%d\n", n);
                  $$= T_BOOL;
                }
                }
| expr INF expr { // expr < expr
                if ($1 == T_INT && $3 == T_INT) {
                  int n = new_label_number();
                  printf("\tpop bx\n");
                  printf("\tpop ax\n");
                  printf("\tconst dx,vrai:%d\n",n);
                  printf("\tsless ax,bx\n");
                  printf("\tjmpc dx\n");
                  printf("\tconst bx,0\n");
                  printf("\tpush bx\n"); //push 0
                  printf("\tconst dx,fin:%d\n", n);
                  printf("\tjmp dx\n");
                  printf(":vrai:%d\n",n);
                  printf("\tconst ax,1\n");
                  printf("\tpush ax\n");
                  printf(":fin:%d\n", n);
                  $$= T_BOOL;
                }
                }
| CALL '{' ID '}' '{' exprs '}' { //peut etre doit aussi etre dans les instr ?
                                printf(";call\n");
                                printf("\tconst ax,fonc:%s:debut\n", $3);
                                printf("\tcall ax\n");
                                printf(";call fin\n");
                                $$ = T_INT;
                                }
;
%%

void yyerror(char const *s) {
  fprintf(stderr, "%s\n", s);
}

int main() {
  yyparse();
  //printf("\tcp ax,sp\n");
	//printf("\tcallprintfd ax\n");
  return EXIT_SUCCESS;
}

static unsigned int new_label_number() {
  static unsigned int current_label_number = 0u;
  if ( current_label_number == UINT_MAX ) {
    fail_with("Error: maximum label number reached!\n");
  }
  return current_label_number++;
}
/*
* char buf1[MAXBUF], char buf2[MAXBUF];
* unsigned ln = new_label_number();
* create_label(buf1, MAXBUF, "%s:%u:%s", "loop", ln, "begin"); // "loop:10:begin"
* create_label(buf2, MAXBUF, "%s:%u:%s", "loop", ln, "end"); // "loop:10:end"
*/
static void create_label(char *buf, size_t buf_size, const char *format, ...) {
  va_list ap;
  va_start(ap, format);
  if ( vsnprintf(buf, buf_size, format, ap) >= buf_size ) {
    va_end(ap);
    fail_with("Error in label generation: size of label exceeds maximum size!\n");
  }
  va_end(ap);
}
void fail_with(const char *format, ...) {
va_list ap;
va_start(ap, format);
vfprintf(stderr, format, ap);
va_end(ap);
exit(EXIT_FAILURE);
}
