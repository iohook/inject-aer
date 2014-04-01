#include <stdio.h>
#include "util.h"

void print_flags_seq(const char *delim,
                       unsigned long flags,
                       const struct _reserved_words *flag_array)
{
        unsigned long mask;                                      
        const char *str;
        int i, first = 1;

        for (i = 0;  flag_array[i].name && flags; i++) {

                mask = flag_array[i].mask;
                if ((flags & mask) != mask)
                        continue;

                str = flag_array[i].name;
                flags &= ~mask;
                if (!first && delim)
                        fputs(delim, stdout);
                else
                        first = 0;
                fputs(str, stdout);
        }

        /* check for left over flags */
        if (flags) {
                if (!first && delim)
                        fputs(delim, stdout);
                printf("0x%lx(unknown)", flags);
        }
	printf("\n");

}

