/* Copyright (c) 2013 by Intel Corp.
   Scanner for the PCI AER grammar.

   inject-aer is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public
   License as published by the Free Software Foundation; version
   2.

   inject-aer is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   General Public License for more details.

   You should find a copy of v2 of the GNU General Public License somewhere
   on your Linux system; if not, write to the Free Software Foundation,
   Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

   Authors:
	Rui Wang
*/
%{
#define _GNU_SOURCE 1
#include <stdlib.h>
#include <string.h>

#include "util.h"
#include "aer.tab.h"

int yylineno;
int yyparse(void);

static struct _reserved_words *IsReserved(const char *);
int found_aer = 0;

%}

%option noinput
%option nounput
%option stack
%x AER_STATE

%%

<AER_STATE>{
0x[0-9a-fA-F]+ 		yylval.string = strdup(yytext); return HEXNUM;
[0-9]+			yylval.string = strdup(yytext); return NUMBER;
[_a-zA-Z][ \t_a-zA-Z-]*	{
				struct _reserved_words *p;

				p = IsReserved(yytext);
				if (p) {
					yylval.ival = p->mask;
					return p->tok;
				} else
					return 0;
			}
[:,\.=\|]		return yytext[0];
[ \t]+			; /* ignored */
.			; /* ignored */
\n			{
				++yylineno;
				yy_pop_state();
				LOGITV(("exiting from AER_STATEn\n"));
			}
}

"aer_event:"		found_aer = 1; LOGITV(("Found aer event\n")); yy_push_state(AER_STATE); return AER;
\n			++yylineno; //LOGIT(("newline\n"));
.			;/* ignored */
<<EOF>>			return ENDOFFILE;

%%

/* reserved words handling */

struct _reserved_words reserv_words[] = {
	{SEVERITY, SEVERITY, "severity" },
	{CORRECTED, CORRECTED, "Corrected" },
	{UNCORRECTED, UNCORRECTED, "Uncorrected" },
	{FATAL, FATAL, "Fatal" },
	{NONFATAL, NONFATAL, "non-fatal" },
	{PCIEBE, PCIEBE, "PCIe Bus Error" },
	/* flags follow here */
	aer_correctable_errors,
	aer_uncorrectable_errors
};

static struct _reserved_words *IsReserved(const char *s)
{
	int i;
	while (*s == ' ' || *s == '\t') /* skip any preceeding space */
		s++;
	for (i=0; i<sizeof(reserv_words)/sizeof(struct _reserved_words); i++) {
		if (!strncmp(s, reserv_words[i].name, strlen(reserv_words[i].name))) {
			LOGITV(("\t\tkeyword  :%s\n", s));
			return &reserv_words[i];
		}
	}
	return NULL;
}

static int init_iohook(void)
{
	if (system("ls " IOHOOK_DIR "> /dev/null"))
		return -EEXIST;

	return 0;

}

static void init_lex(void)
{
}

int do_dump;
static char **argv;
char *filename = "<stdin>";

int yywrap(void)
{
	if (*argv == NULL)
		return 1;
	filename = *argv;
	yyin = fopen(filename, "r");
	if (!yyin)
		perror(filename);
	argv++;
	LOGITV(("parsing %s\n", filename));
	return 0;
}

int main(int ac, char **av)
{
	int rc = 0;

	if (init_iohook()) {
		printf("error: IO Hook not available\n");
		return rc;
	}

	init_lex();
	argv = ++av;
	if (*argv && !strcmp(*argv, "--dump")) {
		do_dump = 1;
		argv++;
	}
	if (*argv)
		yywrap();
	rc = yyparse();

	return rc;
}

void yyerror(const char *str)
{
	printf("%s on line:%d\n", str, yylineno);
}
