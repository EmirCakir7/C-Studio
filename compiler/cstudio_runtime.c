#include <stdio.h>

// C-Studio Runtime: Standart cikis akislarini (stdout/stderr) tampondansiz (unbuffered) yapar.
// Boylece printf("Girdi giriniz:"); gibi satirlar scanf oncesinde aninda terminale iletilir.
void __attribute__((constructor)) __cstudio_unbuffer_io(void) {
    setvbuf(stdout, NULL, _IONBF, 0);
    setvbuf(stderr, NULL, _IONBF, 0);
}
