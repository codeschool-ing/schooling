---
title: Isolar uma máquina, em segundos
version: 1
---

Quando há suspeita sobre uma máquina, a primeira decisão não é o que aconteceu. É **como impedir que
ela toque em qualquer outra coisa enquanto isso é descoberto**. Puxar o cabo funciona quando há
alguém do lado dela. Uma regra no firewall funciona de onde quer que o defensor esteja, e é uma
linha que pode ser escrita com antecedência, de modo que na hora só precisa de um endereço.

A quarentena de `desk`, como um arquivo de uma linha, com o número do chamado no comentário:

```
root@fw:~# cat quarantine.nft; nft -f quarantine.nft
insert rule ip filter forward ip saddr 192.168.10.21 counter drop comment "quarantine: desk, ticket 4711"
```

O `insert` a coloca em primeiro lugar na chain, antes de todo `accept`, então nada do que a máquina
envia atravessa o `fw`. Então `desk` tenta o de sempre:

```
ana@desk:~$ curl -s -m3 https://www.example.com/; echo "exit $?"
exit 28
ana@desk:~$ dig +short +time=1 +tries=1 www.example.com
;; communications error to 192.0.2.53#53: timed out
;; no servers could be reached
```

A loja não responde a tempo, e o servidor de nomes também não, que fica na DMZ e é alcançado através
do `fw`. Enquanto isso, o vizinho dela não é afetado:

```
ana@laptop:~$ curl -s https://www.example.com/
orders service: ok
```

O contador registra o que `desk` tentou depois de ser isolada, e isso em si já é evidência:

```
root@fw:~# nft list chain ip filter forward | grep quarantine
		ip saddr 192.168.10.21 counter packets 4 bytes 264 drop comment "quarantine: desk, ticket 4711"
```

Quatro pacotes nos poucos segundos que a captura durou. Numa máquina rodando ransomware, esse
contador subindo sem parar, com destinos que não são da empresa, é o software tentando alcançar quem
o controla.

Três coisas que a quarentena **não** faz, e que precisam ser feitas por outros meios:

- não impede `desk` de alcançar máquinas do próprio segmento, e é por isso que o firewall de host da
  seção anterior importa, e por isso os switches também podem desligar uma porta;
- não preserva o que está na memória de `desk`, que se perde se alguém a desligar em pânico; isolar
  em vez de desligar guarda a evidência;
- não avisa ninguém: o número do chamado no comentário está ali para que a regra seja removida quando
  o chamado for fechado, e não encontrada daqui a um ano por alguém se perguntando o que era `desk`.
