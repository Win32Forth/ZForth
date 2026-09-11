#include "kernel_api.h"
#include "zforth_host.h"

#include <stdlib.h>
#include <string.h>
#include <stdio.h>

static volatile int g_running = 0;

static char *g_load_buf = NULL;
static size_t g_load_len = 0;

static void host_emit(int c)
{
    zforth_emit((uint8_t)(c & 0xFF));
}

static void host_emit_buf(const char *buf, size_t n)
{
    zforth_type(buf, n);
}

static void free_load_buf(void)
{
    free(g_load_buf);
    g_load_buf = NULL;
    g_load_len = 0;
}

static int host_load_file(const char *path, size_t path_len,
                          const char **out_ptr, size_t *out_len)
{
    char pathz[1024];
    char filebuf[1 << 16];
    int32_t nread;

    free_load_buf();

    if (path_len == 0) {
        int32_t plen = zforth_open_panel(pathz, (int32_t)sizeof(pathz) - 1);
        if (plen <= 0) return -1;
        pathz[plen] = 0;
    } else {
        if (path_len >= sizeof(pathz)) return -1;
        memcpy(pathz, path, path_len);
        pathz[path_len] = 0;
    }

    nread = zforth_load_file(pathz, filebuf, (int32_t)sizeof(filebuf));
    if (nread < 0) return -1;

    g_load_buf = malloc((size_t)nread);
    if (!g_load_buf) return -1;
    memcpy(g_load_buf, filebuf, (size_t)nread);
    g_load_len = (size_t)nread;

    *out_ptr = g_load_buf;
    *out_len = g_load_len;
    return 0;
}

void zforth_vm_start(void)
{
    g_running = 1;
    zforth_refresh();
    
    char line[256];
    char src[8192];

    kernel_set_emit(host_emit);
    kernel_set_emit_buf(host_emit_buf);
    kernel_set_load_file(host_load_file);
    kernel_cold_start();

    while (g_running) {
        int32_t sn = zforth_take_source(src, (int32_t)sizeof(src));
        if (sn > 0) {
            kernel_eval(src, (size_t)sn);
            free_load_buf();
            continue;
        }

        zforth_type("ok> ", 4);
        zforth_refresh();
        int32_t n = zforth_accept(line, (int32_t)sizeof(line));
        if (n < 0) break;
        if (n == 3 && memcmp(line, "bye", 3) == 0) break;
        int rc = kernel_eval(line, (size_t)n);
        zforth_cr();
        free_load_buf();
    }
}

void zforth_vm_stop(void)
{
    g_running = 0;
}

