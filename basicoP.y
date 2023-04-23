%{

/*
librerias y variables
prototipos
*/
#include<stdlib.h>
#include<stdio.h>
#include<string.h>
#include<ctype.h>
void yyerror(char *s);
int yylex();
char lexema[100];
int localizaSimbolo(char *lexema, int token);

typedef struct {
	char nombre[100];
	int token;
	double valor;
	int tipo;
}TipoTablaDeSimbolos;

int nSim=0;

TipoTablaDeSimbolos tablaDeSimbolos[200];

int genTemp();
void interpretaCodigo();
void generaCodigo(int op,int a1,int a2 , int a3);
int nVarTemp=1;

typedef struct {
	int op;
        int a1;
        int a2;
        int a3;
}TipoTablaCod;

int cx=-1;

TipoTablaCod tablaCod[200];



%}

%token  MIENTRAS ID IGUAL NUMENT SUMA PARIZQ FUEPE DOSPUNT PARDER RESTA MUL DIV ZAFA ENDL PARA HACER MANYA TRAETE VETEA GUARDARMEM IMPRIME LEE MENORQUE MAYORQUE MEVOY A IGUALQUE MAYORIGUALQUE MENORIGUALQUE LIBRERIA TINKA PALTA CRITERIO EXCLAMACION CADENA SALTATE DEFFUN CHECA COMA DEVUELVE VERDURA FEIK CONDSI SINO POSINC PUNTERO MENU ETIQUETA NOHAY DEFINE
%token MULTIPLICAR ASIGNAR DIVIDIR OPMENORIGUALQUE SALTARF SALTAR SALTARV SUMAR LEER OPIGUALQUE NEGACION

%%
/*gramatica*/

programa: preprocesa listInst;

listInst: instr listInst;

listInst: ;

instr: ID {int i= localizaSimbolo(lexema,ID); $$=i;} IGUAL compara ENDL {generaCodigo(ASIGNAR
,$2,$4,'-'); };

instr: ID {localizaSimbolo(lexema,ID);} PUNTERO ENDL;/**/

instr: ZAFA ENDL;

instr: SALTATE ENDL;

expr: TINKA PARIZQ PARDER;

compara: compara MENORQUE expr;

compara: compara MAYORQUE expr;

compara: compara IGUALQUE expr {int i=genTemp();generaCodigo(OPIGUALQUE,i,$1,$3);$$=i;};

compara: expr;

expr: expr SUMA term {int i= genTemp() ;generaCodigo(SUMAR,i,$1,$3);$$=i;};

expr: expr RESTA term;

instr: expr POSINC;

instr: expr POSINC ENDL;

compara: compara MAYORIGUALQUE compara; 

compara: compara MENORIGUALQUE compara {int i=genTemp(); generaCodigo(OPMENORIGUALQUE,i ,$1,$3);$$=i;};

compara: EXCLAMACION compara {int i=genTemp(); generaCodigo(NEGACION,i,$2,'-');$$=i;};

expr: term;

term: term MUL factor;

term: term DIV factor {int i= genTemp() ;generaCodigo(DIVIDIR,i,$1,$3);$$=i;};

term: factor;

factor: PARIZQ expr PARDER;

factor: NUMENT{ int i= localizaSimbolo(lexema,NUMENT);$$=i;};

factor: ID {int i= localizaSimbolo(lexema,ID);$$=i;} ;

factor: VERDURA;

factor: FEIK;

factor: NOHAY;

instr: MIENTRAS PARIZQ compara PARDER HACER bloqinst;

instr: PARA PARIZQ auxPara COMA {$$=cx+1;} compara { generaCodigo(SALTARF,$6,'?','-'); $$=cx; } COMA instr PARDER HACER bloqinst { generaCodigo(SALTAR,$5, '-','-');$$=cx;   }   {tablaCod[$7].a2=cx+1;};

auxPara: ID {localizaSimbolo(lexema,ID);} IGUAL compara; /*Para la inicializacion dentro del for*/

bloqinst : DOSPUNT listInst FUEPE;

instr: CONDSI PARIZQ compara PARDER bloqinst;
instr:  CONDSI PARIZQ compara PARDER DOSPUNT listInst bloqSino;

bloqSino: SINO bloqinst;

incluir: TRAETE LIBRERIA;

define: MANYA ID {localizaSimbolo(lexema,DEFINE);} NUMENT;

instr: MEVOY PARIZQ ID {localizaSimbolo(lexema,ID);} PARDER DOSPUNT listaSwitch FUEPE;

listaSwitch: casoSwitch listaSwitch;
listaSwitch: ;

casoSwitch: A NUMENT {localizaSimbolo(lexema,NUMENT);} DOSPUNT listInst;

instr: IMPRIME PARIZQ CADENA PARDER ENDL; 

instr: IMPRIME PARIZQ ID {localizaSimbolo(lexema,ID);}  PARDER ENDL;

instr: LEE PARIZQ ID {int i=localizaSimbolo(lexema,ID); $$=i;} PARDER ENDL { generaCodigo(LEER,$3,'-','-');};

expr: GUARDARMEM PARIZQ NUMENT  {localizaSimbolo(lexema,NUMENT);} PARDER;

instr: DEFFUN ID {localizaSimbolo(lexema,ID);} PARIZQ listArg PARDER bloqinst;

instr: MENU ID {localizaSimbolo(lexema,ID);} DOSPUNT listArg ENDL; 

instr: VETEA ID {localizaSimbolo(lexema,ID);}  ENDL;

instr: DEVUELVE ENDL;

/*Update, parece mas seguro, pero igual habria que revisar*/

instr: ETIQUETA {localizaSimbolo(lexema,ETIQUETA);} listInst FUEPE;

listArg: arg listArg;

listArg: ;

arg: ID {localizaSimbolo(lexema,ID);} ;

arg: ID {localizaSimbolo(lexema,ID);} COMA;

instr: CHECA compara DOSPUNT CADENA ENDL;

instr: PALTA ENDL;

instr: CRITERIO bloqinst;


preprocesa: define preprocesa;
preprocesa: incluir preprocesa;
preprocesa: ;

%%

/*codigo C*/
/*análisis léxico*/
int localizaSimbolo(char *lexema, int token){
	for(int i=0;i<nSim;i++){
		if(!strcmp(tablaDeSimbolos[i].nombre,lexema)){
			return i;
		}
	}
	strcpy(tablaDeSimbolos[nSim].nombre,lexema);
	tablaDeSimbolos[nSim].token=token;
	tablaDeSimbolos[nSim].tipo=0;
	tablaDeSimbolos[nSim].valor=0.0;

    if (token==NUMENT){ 
                tablaDeSimbolos[nSim].valor=atof(lexema);     
        }
        else {
	        tablaDeSimbolos[nSim].valor=0.0;
        }

	nSim++;
	return nSim-1;
}

int yylex(){
        char c;int i;
		char c2,c3;
		c=getchar();
		while(c==' ' || c=='\n' || c=='\t'){ c=getchar(); if(c!=' ' && c!='\n' && c!='\t') break;} 
               
                
		if(c=='#') return 0;
		if(isalpha(c)){
			i=0;
			do{
				lexema[i++]=c;
				c=getchar();
			}while(isalnum(c));
			
			if(c=='.'){
				c2 = getchar();
				if(c2=='h'){
					lexema[i++] = '.';
					lexema[i++] = c2;
					lexema[i++] = '\0';
					return LIBRERIA;
				} 
				ungetc(c2,stdin);
			}
			ungetc(c,stdin);
			lexema[i++]='\0';
	
			if(!strcmp(lexema,"mientras")) return MIENTRAS; 
			if(!strcmp(lexema,"hazte")) return HACER; 
			if(!strcmp(lexema,"traete")) return TRAETE;
			if(!strcmp(lexema,"zafa")) return ZAFA; 
			if(!strcmp(lexema,"tinka")) return TINKA;
			if(!strcmp(lexema,"lee")) return LEE;
			if(!strcmp(lexema, "micriterio")) return CRITERIO;
			if(!strcmp(lexema, "quePaltaMeVoy")) return PALTA;
			if(!strcmp(lexema, "meVoy")) return MEVOY;
			if(!strcmp(lexema, "fuepe")) return FUEPE;
			if(!strcmp(lexema, "a")) return A;
			if(!strcmp(lexema, "manya")) return MANYA;
			if(!strcmp(lexema, "guardameSitioPorfa")) return GUARDARMEM;
			if(!strcmp(lexema, "imprime")) return IMPRIME;
			if(!strcmp(lexema, "saltate")) return SALTATE;
			if(!strcmp(lexema, "para")) return PARA;
			if(!strcmp(lexema, "checa")) return CHECA;
			if(!strcmp(lexema, "funcion")) return DEFFUN;
			if(!strcmp(lexema, "vetea")) return VETEA;
			if(!strcmp(lexema, "devuelve")) return DEVUELVE;
			if(!strcmp(lexema, "verdura")) return VERDURA;
			if(!strcmp(lexema, "feik")) return FEIK;
			if(!strcmp(lexema, "Si")) return CONDSI;
			if(!strcmp(lexema, "Sino")) return SINO;
			if(!strcmp(lexema, "menu")) return MENU;
			if(!strcmp(lexema, "nohay")) return NOHAY;

			c=getchar();
			if(c==':'){
				c2 = getchar();
				while(c2==' ' || c2=='\t'){ c2=getchar(); if(c2!=' ' &&  c2!='\t') break;} 
				if(c2=='\n'){
					lexema[--i] = ':';
					lexema[++i] = '\0';
					return ETIQUETA;
				} 
				ungetc(c2,stdin);
			}
			ungetc(c, stdin); 
			//localizaSimbolo(lexema,ID);
			return ID;

		}

			if(isdigit(c)){
			i=0;
			do{
				lexema[i++]=c;
				c=getchar();
			}while(isdigit(c));
			ungetc(c,stdin);
			lexema[i++]='\0';
                         
			return NUMENT;
			} 
                 
               if(c=='='){
					c2 = getchar();
					if(c2 == '='){
						return IGUALQUE;
					}
					if(c2 == ')'){
						return MAYORIGUALQUE;
					}
					if(c2 == '('){
						return MENORIGUALQUE; 
					}
					
					ungetc(c2,stdin);
               		return IGUAL;

					
               }
               
               if(c=='+'){
					c=getchar();
					if(c=='+') return POSINC;
					else{
						ungetc(c,stdin);
						return SUMA;
					}

               }
               if(c=='-'){
               		return RESTA;
               }
               if(c=='*'){
               		return MUL;
               }
               if(c=='/'){
               		return DIV;
               }
               if(c=='('){
               		return PARIZQ;
               }
               if(c==')'){
               		return PARDER;
               }
			   if(c==':')
			   {
					c=getchar();
					if(c=='(') return MENORQUE;
					if(c==')') return MAYORQUE;

					ungetc(c, stdin);
					return DOSPUNT;
			   }
			   if(c=='!'){
					return EXCLAMACION;
			   }
			   if(c==','){
					return COMA;
			   }

			   if(c=='"'){
					lexema[0]='"'; 
					i=0;
					do{
						lexema[i++]=c;
						c=getchar();
					}while(c!='"');
					lexema[i]='"';
					lexema[i+1]='\0';
					return CADENA;
			   }
				if(c=='\\'){
					c2 = getchar();
					if(c2 == 'p'){
						c3 = getchar();
						if(c3 == 'e'){
							return ENDL;
						}
						else{
							ungetc(c3,stdin);
						}
					}
					else{
						ungetc(c2,stdin);
					}
               		
               }
			   if(c=='<'){
					c=getchar();
					if(c=='*'){
						c=getchar();
						if(c=='>') return PUNTERO;
					}

			   }

			   
		return c;
	
}
void yyerror(char *s){
	fprintf(stderr,"%s\n",s);
}

void imprimeTablaCodigo(){
        printf("Tabla de codigo\n");
        printf("i\top\ta1\ta2\ta3\n");
        for(int i=0;i<=cx;i++){
        /*if(tablaCod[i].op==SUMAR){
                    printf("SUMAR ");
        }*/
        printf("%d\t%d\t%d\t%d\t%d\n",i,tablaCod[i].op,tablaCod[i].a1,tablaCod[i].a2,tablaCod[i].a3);
            
        }
}

void imprimeTablaSimbolo(){
	/*for(int i=0;i<nSim;i++){
		printf("%s",tablaDeSimbolos[i].nombre);
		printf("\n");
	}*/

    printf("Tabla de simbolo:\n");
        printf("i\tnombre\ttoken\tvalor\n");

	for(int i=0;i<nSim;i++){
		printf("%d\t%s\t%d\t%lf",i,tablaDeSimbolos[i].nombre,tablaDeSimbolos[i].token,tablaDeSimbolos[i].valor);
		printf("\n");
	}
}

void interpretaCodigo(){
        int i,op,a1,a2,a3;
        for (i=0;i<=cx;i=i+1) {
                op=tablaCod[i].op;
                a1=tablaCod[i].a1 ;
                a2=tablaCod[i].a2 ;
                a3=tablaCod[i].a3 ;
              
                
                if(op==ASIGNAR){
                                tablaDeSimbolos[a1].valor=tablaDeSimbolos[a2].valor;
                }  
                if(op==DIVIDIR){
                                tablaDeSimbolos[a1].valor=tablaDeSimbolos[a2].valor/tablaDeSimbolos[a3].valor;
                }
                if(op==OPMENORIGUALQUE){
                        if(tablaDeSimbolos[a2].valor<=tablaDeSimbolos[a3].valor)
                                tablaDeSimbolos[a1].valor=1;
                        else
                                tablaDeSimbolos[a1].valor=0;
                }
                if(op==OPIGUALQUE){
                	if(tablaDeSimbolos[a2].valor==tablaDeSimbolos[a3].valor)
                		tablaDeSimbolos[a1].valor = 1;
                	else
                		tablaDeSimbolos[a1].valor = 0;
                }
                if(op==NEGACION){
                	if(tablaDeSimbolos[a2].valor==0)
                		tablaDeSimbolos[a1].valor = 1;
                	else
                		tablaDeSimbolos[a1].valor = 0;
                }
                if(op==SALTAR){
                        i=a1-1;
                }   
                if(op==SALTARF){
                        if(tablaDeSimbolos[a1].valor==0)
                                i=a2-1;
        
                }   
                if(op==SALTARV){
                        if(tablaDeSimbolos[a1].valor==1)
                                i=a2-1;
                }
                if(op==SUMAR){
                                tablaDeSimbolos[a1].valor=tablaDeSimbolos[a2].valor+tablaDeSimbolos[a3].valor;
                }
                if(op==LEER){
                                scanf("%lf",&tablaDeSimbolos[a1].valor );
                } 
        }

}

void generaCodigo(int op,int a1,int a2 , int a3){
        cx++;        
        tablaCod[cx].op=op;
        tablaCod[cx].a1=a1;
        tablaCod[cx].a2=a2;
        tablaCod[cx].a3=a3;
        /*agrega un código de operación (o instrucción de codigo), se recibe el:
        código de la operación y las posiciones que se usarán en la operación
        */
}

int genTemp(){
        int pos;
        char t[10];
        sprintf(t,"_T%d",nVarTemp++);
        pos=localizaSimbolo(t,ID);
        return pos;        
}

int main(){
        if(!yyparse()){
	         printf("cadena válida\n");
	         imprimeTablaSimbolo();
             imprimeTablaCodigo();
             interpretaCodigo();   
             imprimeTablaSimbolo();
	}
	else{
	         printf("cadena inválida\n");	
	}
        return 0;
}
