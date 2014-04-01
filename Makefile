prefix := /usr
manprefix := ${prefix}/share
CFLAGS := -Os -g -Wall -DDEBUG=1
LDFLAGS += -pthread

OBJ := aer.tab.o lex.yy.o inject-aer.o util.o
GENSRC := aer.tab.c lex.yy.c
SRC := inject-aer.c util.c
CLEAN := ${OBJ} ${GENSRC} aer.tab.h inject-aer .depend
DISTCLEAN := .depend .gdb_history

.PHONY: clean depend install

inject-aer: ${OBJ}

lex.yy.c: aer.lex aer.tab.h
	flex aer.lex
	
aer.tab.c aer.tab.h: aer.y
	bison -d aer.y

#install: inject-aer inject-aer.8
#	install -d $(destdir)$(prefix)/sbin
#	install -m 755 inject-aer $(destdir)$(prefix)/sbin/inject-aer
#	install -d $(destdir)$(manprefix)/man/man8
#	install -m 644 inject-aer.8 $(destdir)$(manprefix)/man/man8/inject-aer.8

clean:
	rm -f ${CLEAN}

distclean: clean
	rm -f ${DISTCLEAN} *~

depend: .depend

.depend: ${SRC} ${GENSRC}
	${CC} -MM -DDEPS_RUN -I. ${SRC} ${GENSRC} > .depend.X && \
		mv .depend.X .depend

Makefile: .depend

include .depend
