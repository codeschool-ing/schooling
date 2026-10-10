---
title: Um upgrade menor com o apt
version: 1
---

O seu servidor já está na versão menor mais nova, porque a lição 3 o instalou pelas atualizações do
Ubuntu. **A sessão desta seção foi gravada num servidor instalado no 16.2**, a versão com que o
Ubuntu 24.04 foi lançado, com o mesmo papel e o mesmo banco `shop` que o seu. No seu servidor os
comandos abaixo não encontram nada para fazer, e esse é o resultado certo.

## O que está esperando

Atualize as listas do apt e pergunte quais pacotes do PostgreSQL têm versão mais nova:

@@1@@

@@2@@

Dois pacotes, o servidor e o cliente, e a origem de onde vêm: `noble-security`. Essa palavra importa
mais do que parece, como explica a última parte desta seção. Antes de instalar, pergunte ao servidor
o que ele é e quando subiu:

@@3@@

## O upgrade

Instale o pacote mais novo do servidor. O apt traz junto o cliente e a `libpq5`, a biblioteca de
cliente, na mesma versão:

@@4@@

Depois faça as mesmas duas perguntas de novo:

@@5@@

**A versão mudou, e a hora de início também.** Os scripts do pacote pararam o cluster, trocaram os
programas em `/usr/lib/postgresql/16` e subiram tudo de novo. Nada em `/var/lib/postgresql/16/main`
foi convertido, porque nada precisava ser. O log do próprio servidor diz a mesma coisa por dentro:

@@6@@

Leia as quatro linhas do meio. **`received fast shutdown request`** é o pacote parando o servidor:
um desligamento rápido desfaz toda transação aberta e desconecta todo cliente. Entre `database
system is shut down` e `ready to accept connections` o servidor não existiu, e na máquina da gravação
esse intervalo foi de poucos segundos — o tempo que o apt levou para desempacotar três pacotes. É
esse o custo inteiro de um upgrade menor, e toda aplicação conectada naquele momento vê a conexão
cair e precisa reconectar.

## Antes de rodar num servidor que importa

**Leia as notas de versão**, de cada versão menor entre a sua e a nova. Cada uma tem uma seção
chamada *Migration*, e quase sempre ela diz que nenhuma ação é necessária. De vez em quando ela pede
alguma coisa: o PostgreSQL 14.4 corrigiu um bug que podia corromper índices criados com `CREATE INDEX
CONCURRENTLY`, e as notas pediam a todos que reconstruíssem esses índices depois de atualizar. Pular
direto do 16.2 para o 16.15 significa ler treze conjuntos de notas, e isso ainda é mais rápido do que
descobrir depois qual delas importava.

**Escolha o momento.** O reinício é curto, mas é um reinício: escolha uma hora em que conexões
derrubadas doam menos, e avise quem cuida da aplicação.

**Saiba quem mais pode escolher por você.** Um servidor Ubuntu padrão roda o **unattended-upgrades**,
que instala sozinho, uma vez por dia, os pacotes que vêm das atualizações de segurança. As versões
menores do PostgreSQL chegam por ali — `noble-security` na lista acima —, então um servidor deixado sozinho
se atualiza e reinicia o banco na hora em que o timer disparar. Algumas equipes aceitam isso. Outras
põem os pacotes do PostgreSQL em `Unattended-Upgrade::Package-Blacklist`, no arquivo
`/etc/apt/apt.conf.d/50unattended-upgrades`, e atualizam à mão, num horário marcado, com alguém
olhando. As duas coisas são decisões; descobrir depois do fato não é.
