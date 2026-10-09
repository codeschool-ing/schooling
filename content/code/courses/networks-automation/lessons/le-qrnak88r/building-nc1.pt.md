---
title: Construindo o nc1
version: 1
---

Esta aula conversa com o `nc1`, um equipamento sem roteamento nenhum: a configuração dele é um
documento, conferido contra modelos YANG e servido por NETCONF na porta 830 e por RESTCONF na porta
443. O software por trás dele é o **Clixon**, um plano de gerência livre sobre o qual produtos reais
são construídos. O Ubuntu não o empacota, então ele é compilado do código-fonte uma vez, na máquina
virtual, a partir dos dois commits com que este curso foi gravado.

O compilador e as bibliotecas contra as quais o Clixon compila:

```sh
sudo apt-get install -y build-essential flex bison libnghttp2-dev libssl-dev libcurl4-openssl-dev
```

O CLIgen, a biblioteca com que o CLI do Clixon é feito, e depois o próprio Clixon. Cada um é
clonado em `~/src`, fixado no seu commit, compilado e instalado em `/usr/local`:

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

O `--with-restconf=native` compila o próprio servidor HTTPS do Clixon para o RESTCONF, então nada
mais precisa ser instalado na frente dele.

**O Clixon deixa uma coisa para o produto construído sobre ele: decidir quem é um cliente
RESTCONF.** Um produto confere uma senha contra o próprio banco de usuários, então o Clixon chama um
plugin e aceita a resposta dele. O plugin do laboratório é o menor que funciona, escrito para este
curso a partir do exemplo que o Clixon traz: ele decodifica o cabeçalho HTTP Basic e procura esse
usuário e essa senha, como uma linha `usuário:senha`, em `/etc/clixon/users` no `nc1`. Salve-o como
`~/netlab/lab_restconf.c`:

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

O `netlab.sh` o compila, dá ao `nc1` o arquivo de configuração, os três modelos e uma configuração
inicial, e liga o backend do Clixon, o servidor RESTCONF dele e um servidor SSH cujo subsystem
NETCONF é o do Clixon. Tudo isso é o `build_nc1` do script da aula 1. Reconstrua:

```sh
sudo ~/netlab/netlab.sh reset
```

e procure `netlab: nc1: started` no que ele imprime.
