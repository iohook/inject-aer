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
#include <string.h>
#include <stdarg.h>
#include <stdlib.h>
#include <stdio.h>
#include "util.h"

int yylex(void);
int yyerror(const char *);
extern int found_aer;

%}

%union {
	int ival;
	char *string;
}

%token AER PCIEBE ENDOFFILE
%token <ival> SEVERITY CORRECTED UNCORRECTED NONFATAL FATAL RECVERR BADTLP BADDLLP RELAY_N RELAY_T ADVIS_N DAVA_L POISON FLOWCP CMPLTM CMPLAB UNEXPC RECVOR MALFTL ECRC UNSPRQ
%token SYMBOL
%token <string> NUMBER HEXNUM
%type <ival> sev_cor sev_unc cor_flags unc_flags cor_flag unc_flag

%%

rules:	/* empty string */
	| rules rule
	;

rule:	AER aer_body { LOGITV(("Rule end\n")); }
	| ENDOFFILE 	{
		if (found_aer) {
			LOGITV(("Endded good\n"));
			YYACCEPT;
		}
		else {
			LOGITV(("Ended without finding anything to do\n"));
			YYERROR;
		}
	}

aer_body:	NUMBER ':' NUMBER ':' NUMBER '.' NUMBER PCIEBE ':' SEVERITY '=' sev_cor ',' cor_flags {
			int domain, bus, dev, func, flags;

			domain = strtol($1, NULL, 16);
			bus = strtol($3, NULL, 16);
			dev = strtol($5, NULL, 16);
			func = strtol($7, NULL, 16);
			flags = $14;

			LOGIT(("%04lx:%02lx:%02lx.%lx severity=Corrected, ", strtol($1, NULL, 16), strtol($3, NULL, 16), strtol($5, NULL, 16), strtol($7, NULL, 16)));
			__print_flags($14, "|", aer_correctable_errors);

			emulate_cor(domain, bus, dev, func, flags);
		}
		| NUMBER ':' NUMBER ':' NUMBER '.' NUMBER PCIEBE ':' SEVERITY '=' sev_unc ',' unc_flags {
			int domain, bus, dev, func, flags;

			domain = strtol($1, NULL, 16);
			bus = strtol($3, NULL, 16);
			dev = strtol($5, NULL, 16);
			func = strtol($7, NULL, 16);
			flags = $14;

			LOGIT(("%04lx:%02lx:%02lx.%lx severity=%s, ", strtol($1, NULL, 16), strtol($3, NULL, 16), strtol($5, NULL, 16), strtol($7, NULL, 16),
				$12 == NONFATAL?"Uncorrected, non-fatal":"Fatal"));
			__print_flags($14, "|", aer_uncorrectable_errors);

			emulate_uncor(domain, bus, dev, func, flags, $12 == NONFATAL ? E_UNCORRECTED : E_FATAL);

		}
		;

sev_cor: 	CORRECTED { $$ = $1; }

sev_unc:	UNCORRECTED ',' NONFATAL { $$ = $3; }
		| FATAL { $$ = $1; }
		;

cor_flags:	cor_flag { $$ = $1; }
		| cor_flags '|' cor_flag { $$ = $1 | $3; }
		;

unc_flags:	unc_flag { $$ = $1; }
		| unc_flags '|' unc_flag { $$ = $1 | $3; }
		;

cor_flag:	RECVERR { $$ = $1; }
		| BADTLP { $$ = $1; }
		| BADDLLP { $$ = $1; }
		| RELAY_N { $$ = $1; }
		| RELAY_T { $$ = $1; }
		| ADVIS_N { $$ = $1; }
		;

unc_flag:	DAVA_L { $$ = $1; }
		| POISON { $$ = $1; }
		| FLOWCP { $$ = $1; }
		| CMPLTM { $$ = $1; }
		| CMPLAB { $$ = $1; }
		| UNEXPC { $$ = $1; }
		| RECVOR { $$ = $1; }
		| MALFTL { $$ = $1; }
		| ECRC   { $$ = $1; }
		| UNSPRQ { $$ = $1; }
		;
%% 
