---
title: Quando a montagem falha
version: 1
---

Um laboratório que não monta é onde a maioria das pessoas desiste, então aqui estão as falhas que este
de fato já produziu, com o que cada mensagem quer dizer.

**`RTNETLINK answers: File exists`.** O script tentou acrescentar um endereço ou uma rota que o seu
computador já tem. Isso aconteceu enquanto este curso era gravado: a máquina da gravação já usava
`192.0.2.0/24` na própria rede, e é por isso que a rede do meio do laboratório é `198.51.100.0/24`. Rode
`ip route` e procure qualquer uma das quatro redes do laboratório (`203.0.113.0/24`, `198.51.100.0/24`,
`192.168.20.0/24`, `192.168.99.0/24`). Se uma já estiver lá, o seu computador está usando essa rede;
troque-a em cada linha do script onde ela aparece.

**`Cannot create namespace file "/run/netns/fw": File exists`.** Um `up` anterior foi interrompido e
deixou máquinas para trás. `bash soclab.sh down`, e depois `up` de novo.

**`Operation not permitted`** no primeiro comando `ip`. Você não é root (`sudo -i` antes), ou está dentro
de um contêiner que não tem permissão para criar namespaces, o que é comum em terminais "playground"
online. Use uma máquina virtual.

**`ts: command not found`** ou **`nfpcapd: command not found`.** Falta um pacote da linha do `apt
install`. O `moreutils` traz o `ts`, e o `nfdump` traz o `nfpcapd`.

**O log do SSH continua vazio.** Confira se os servidores estão rodando com `pgrep -a sshd`: devem
aparecer um escutando em `198.51.100.22` e outro em `192.168.20.10`. Se um reinício apagou o `/run/sshd`,
`down` e `up` o recriam.

Quando a mensagem não estiver nesta lista, procure nela o nome do comando que falhou; o script para ali,
então a última linha impressa é a que vale pesquisar. E restaure o snapshot que você tirou antes da aula:
numa máquina virtual, isso leva segundos.
