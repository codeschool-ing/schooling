---
title: Quando a montagem falha
version: 1
---

A maioria das falhas nas duas últimas seções é uma destas, e cada uma diz isso na sua última linha:

- **`E: Unable to locate package postgresql-16`.** A máquina não é Ubuntu 24.04, cujo repositório
  traz o PostgreSQL 16. Noutra versão, ou recomece a partir de uma imagem 24.04 — a resposta mais
  simples — ou acrescente o repositório apt do próprio projeto PostgreSQL, que publica o 16 para as
  versões suportadas do Ubuntu e do Debian.
- **O `apt-get` não alcança o repositório.** Um proxy, um firewall ou falta de rede. Nada mais vai
  funcionar até o `sudo apt-get update` funcionar.
- **O `pg_createcluster` diz que o cluster já existe**, porque um passo rodou duas vezes. Apague-o e
  monte de novo: `sudo pg_dropcluster --stop 16 gov`, depois o passo 3.
- **A porta 5433 está em uso.** Outra coisa escuta ali, e `sudo ss -ltnp | grep 5433` diz o quê.
  Numa máquina virtual nova, nada escuta.
- **`psql: error: connection to server on socket … failed: No such file or directory`.** O cluster
  não está rodando. Inicie-o com `sudo pg_ctlcluster 16 gov start`; se isso falhar, as últimas
  linhas de `/var/log/postgresql/postgresql-16-gov.log` dizem por quê, e um erro de digitação nas
  quatro linhas acrescentadas ao `postgresql.conf` é o de costume.
- **`FATAL: database "ipe" does not exist`.** Esperado até a seção 5 criá-lo.
- **`could not open file … for reading: Permission denied`** durante o `\copy`. A linha do `chmod`
  foi pulada, então o `postgres` não consegue ler os arquivos.

## Recomeçando

Tudo no banco pode ser refeito a partir dos dois arquivos em `~/gov`. Se uma aula seguinte deixar o
laboratório num estado que você não consegue explicar, apague o cluster, crie-o de novo com o passo
3 da seção 4, e carregue os dados de novo como a seção 5 faz:

```sh
sudo pg_dropcluster --stop 16 gov
```

Os arquivos em `/var/lib/ipe-data` não precisam ser gerados de novo, porque são os mesmos toda vez.
O que você perde é o que as aulas construíram — papéis, permissões, chaves —, e as aulas se apoiam
umas nas outras em ordem, então você as digita de novo da aula 1 até onde estava.