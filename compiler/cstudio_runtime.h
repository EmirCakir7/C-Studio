#ifndef _CSTUDIO_RUNTIME_H
#define _CSTUDIO_RUNTIME_H

#include <stdio.h>

#undef printf
#undef scanf
#undef getchar
#undef gets

#define printf(...) ({ int _cstudio_r = printf(__VA_ARGS__); fflush(stdout); _cstudio_r; })
#define scanf(...) ({ fflush(stdout); scanf(__VA_ARGS__); })
#define getchar() ({ fflush(stdout); getchar(); })
#define gets(s) ({ fflush(stdout); gets(s); })

#endif
