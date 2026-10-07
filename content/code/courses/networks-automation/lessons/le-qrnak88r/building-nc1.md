---
title: Building nc1
version: 1
---

This lesson talks to `nc1`, a device with no routing at all: its configuration is a document,
checked against YANG models and served over NETCONF on port 830 and RESTCONF on port 443. The
software behind it is **Clixon**, an open-source management plane that real products are built on.
Ubuntu does not package it, so it is built from source once, on the virtual machine, from the two
commits this course was recorded with.

The compiler and the libraries Clixon builds against:

```sh
sudo apt-get install -y build-essential flex bison libnghttp2-dev libssl-dev libcurl4-openssl-dev
```

CLIgen, the library Clixon's CLI is made with, then Clixon itself. Each is cloned into `~/src`,
pinned to its commit, built and installed into `/usr/local`:

```sh
git clone https://github.com/clicon/cligen.git ~/src/cligen
git -C ~/src/cligen checkout 9fd27a8
cd ~/src/cligen && ./configure && make -j2 && sudo make install && sudo ldconfig
```

```sh
git clone https://github.com/clicon/clixon.git ~/src/clixon
git -C ~/src/clixon checkout 9817840
cd ~/src/clixon && ./configure --with-restconf=native && make -j2 && sudo make install && sudo ldconfig
```

`--with-restconf=native` builds Clixon's own HTTPS server for RESTCONF, so nothing else needs
installing in front of it.

**Clixon leaves one thing to the product built on it: deciding who a RESTCONF client is.** A
product checks a password against its own user database, so Clixon calls a plugin and accepts its
answer. The lab's plugin is the smallest that works, written for this course after the example
Clixon ships: it decodes the HTTP Basic header and looks for that user and password, as one
`user:password` line, in `/etc/clixon/users` on `nc1`. Save it as `~/netlab/lab_restconf.c`:

```
/* lab_restconf: HTTP basic authentication for nc1's RESTCONF, written for the lab.
 *
 * Clixon leaves "who is this" to a plugin, because a product decides it against
 * its own user database. This one reads user:password lines from
 * /etc/clixon/users and nothing else. The shape follows Clixon's own
 * example/main/example_restconf.c.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <openssl/evp.h>
#include <cligen/cligen.h>
#include <clixon/clixon.h>
#include <clixon/clixon_restconf.h>

static int
lab_auth(clixon_handle h, void *req, clixon_auth_type_t auth_type, char **authp)
{
    char *auth, *colon, line[256];
    unsigned char dec[256];
    int n;
    FILE *f;

    if (auth_type != CLIXON_AUTH_USER)
        return 0;
    *authp = NULL;
    if ((auth = restconf_param_get(h, "HTTP_AUTHORIZATION")) == NULL ||
        strncmp(auth, "Basic ", 6) != 0 || strlen(auth + 6) > 160)
        return 1;
    if ((n = EVP_DecodeBlock(dec, (unsigned char *)auth + 6, strlen(auth + 6))) < 0)
        return 1;
    dec[n] = '\0';
    if ((colon = strchr((char *)dec, ':')) == NULL)
        return 1;
    if ((f = fopen("/etc/clixon/users", "r")) == NULL)
        return 1;
    while (fgets(line, sizeof(line), f)) {
        line[strcspn(line, "\n")] = '\0';
        if (strcmp(line, (char *)dec) == 0) {
            *colon = '\0';
            *authp = strdup((char *)dec);
            break;
        }
    }
    fclose(f);
    return 1;
}

clixon_plugin_api *clixon_plugin_init(clixon_handle h);

static clixon_plugin_api api = {
    "lab",
    clixon_plugin_init,
    NULL,
    NULL,
    .ca_auth = lab_auth,
};

clixon_plugin_api *
clixon_plugin_init(clixon_handle h)
{
    return &api;
}
```

`netlab.sh` compiles it, gives `nc1` its configuration file, its three models and a starting
configuration, and starts Clixon's backend, its RESTCONF server and an SSH server whose NETCONF
subsystem is Clixon's. The whole of that is `build_nc1` in the script from lesson 1. Rebuild:

```sh
sudo ~/netlab/netlab.sh reset
```

and look for `netlab: nc1: started` in what it prints.
