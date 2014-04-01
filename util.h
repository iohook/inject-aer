#ifndef _UTIL_H
#define _UTIL_H

#ifdef	DEBUG
#define LOGIT(x)	printf x

#if (DEBUG >= 2)
#define	LOGITV(x)	printf x
#else
#define LOGITV(x)
#endif

#else
#define LOGIT(x)
#define LOGITV(x)
#endif

#define ARRAY_SIZE(x) (sizeof(x)/sizeof(*(x)))
#define	u64	unsigned long long

#define BIT(x) (1ul << x)

#define E_CORRECTED	1
#define	E_UNCORRECTED	2
#define E_FATAL		3

#define IOHOOK_DIR	"/sys/kernel/debug/iohook"

struct _reserved_words {
	int			tok;
        unsigned long           mask; /* only valid for flags */
        const char              *name;
};

#ifdef DEBUG
#define __print_flags(flag, delim, flag_array...)                       \
        ({                                                              \
                static const struct _reserved_words __flags[] =       \
                        { flag_array, { -1, -1, NULL }};                    \
                print_flags_seq(delim, flag, __flags);        \
        })

#else
#define __print_flags(flag, delim, flag_array...)
#endif

#define aer_correctable_errors          \
        {RECVERR, BIT(0),        "Receiver Error"},              \
        {BADTLP,  BIT(6),        "Bad TLP"},                     \
        {BADDLLP, BIT(7),        "Bad DLLP"},                    \
        {RELAY_N, BIT(8),        "RELAY_NUM Rollover"},          \
        {RELAY_T, BIT(12),       "Replay Timer Timeout"},        \
        {ADVIS_N, BIT(13),       "Advisory Non-Fatal"}
        
#define aer_uncorrectable_errors                \
        {DAVA_L, BIT(4),        "Data Link Protocol"},          \
        {POISON, BIT(12),       "Poisoned TLP"},                \
        {FLOWCP, BIT(13),       "Flow Control Protocol"},       \
        {CMPLTM, BIT(14),       "Completion Timeout"},          \
        {CMPLAB, BIT(15),       "Completer Abort"},             \
        {UNEXPC, BIT(16),       "Unexpected Completion"},       \
        {RECVOR, BIT(17),       "Receiver Overflow"},           \
        {MALFTL, BIT(18),       "Malformed TLP"},               \
        {ECRC,   BIT(19),       "ECRC"},                        \
        {UNSPRQ, BIT(20),       "Unsupported Request"}

void print_flags_seq(const char *delim,
                       unsigned long flags,
                       const struct _reserved_words *flag_array);
void emulate_cor(int domain, int bus, int dev, int func, int flags);
void emulate_uncor(int domain, int bus, int dev, int func, int flags, int sev);

#endif /* _UTIL_H */
