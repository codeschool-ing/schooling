---
title: Conferir um conjunto de regras antes que ele entre no ar
version: 1
---

O conjunto de regras de um firewall é um programa que roda sobre cada pacote, e é editado por gente
com pressa. Duas propriedades do `nft` tornam essa edição mais segura, e as duas valem ser usadas de
propósito.

**Conferir antes de carregar.** O `nft -c` analisa o arquivo e o confere contra o kernel em execução
sem mudar nada. Uma cópia da base com uma palavra escrita errado, `acept` onde deveria estar
`accept`:

```
root@fw:~# nft -c -f typo.nft; echo "exit $?"
typo.nft:7:88-94: Error: syntax error, unexpected comment
    iifname "eth2" oifname { "eth0", "eth1" } tcp dport { 80, 443 } ct state new acept comment "staff browse"
                                                                                       ^^^^^^^
exit 1
root@fw:~# nft list ruleset | grep -c accept
11
```

O erro nomeia o arquivo, a linha e as colunas, e o conjunto de regras em execução fica intocado: 11
`accept`s antes e depois.

**O carregamento é atômico.** O `nft -f` aplica um arquivo inteiro como uma transação só: toda linha
entra em vigor, ou nenhuma entra. O mesmo arquivo quebrado, carregado de verdade:

```
root@fw:~# nft -f typo.nft; echo "exit $?"
typo.nft:7:88-94: Error: syntax error, unexpected comment
    iifname "eth2" oifname { "eth0", "eth1" } tcp dport { 80, 443 } ct state new acept comment "staff browse"
                                                                                       ^^^^^^^
exit 1
root@fw:~# nft list ruleset | grep -c accept
11
```

Continua 11. **Nada aplicado pela metade.** Isso importa mais com um arquivo que começa com `flush
ruleset`, como estes. Sem carregamento atômico, um erro na linha 7 deixaria o firewall limpo, só com
as linhas 1 a 6 carregadas. Com uma política `drop`, quase nada passaria; com `accept`, quase tudo.

O `iptables` carrega uma regra por comando, então um script de cinquenta linhas de `iptables` que
falha na linha 20 deixa dezenove aplicadas. O `iptables-restore` existe exatamente por esse motivo, e
faz para um arquivo inteiro o que o `nft -f` faz.

Um conjunto de regras que passa na análise não é um conjunto de regras correto. A única verificação
disso é a da aula 4: sondar cada célula a partir da zona onde ela começa, depois de cada mudança.
