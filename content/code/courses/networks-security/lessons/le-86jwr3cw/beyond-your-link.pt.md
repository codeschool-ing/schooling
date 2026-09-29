---
title: O que o prédio não consegue absorver
version: 1
---

Tudo até aqui acontece no equipamento do próprio defensor. Contra um ataque volumétrico maior do que
o link, nada disso roda, porque os pacotes são descartados antes de chegar ao equipamento. O que
resta se decide do lado do provedor, e alguém tem de combinar isso **antes** do ataque:

| medida | como funciona |
|---|---|
| a filtragem do provedor | o ISP descarta o tráfego para o endereço atacado nos próprios links, maiores |
| um serviço de limpeza de tráfego (scrubbing) | o tráfego é roteado por um provedor cujo trabalho é absorver enxurradas e encaminhar só o que parece legítimo |
| uma CDN na frente do site | o endereço público pertence a uma rede de centenas de locais; a enxurrada se espalha por todos eles, e o endereço do servidor de origem nunca é publicado |
| anycast | um endereço anunciado de muitos lugares, então cada lugar recebe só a parte do ataque mais próxima dele |

**O fator comum é capacidade que outra pessoa tem.** Uma empresa pequena não consegue comprar um link
maior do que um ataque; consegue comprar um serviço que tem um. A decisão de fazer isso é tomada numa
reunião, não durante um incidente, e o número que a decide é quanto custa uma hora do serviço fora do
ar.

## Olhando a tabela encher

No equipamento que é do defensor, o primeiro sinal de um ataque de protocolo é a tabela de conexões.
Dois números para acompanhar, e dois contadores que vale saber onde encontrar:

```
root@fw:~# conntrack -C; sysctl -n net.netfilter.nf_conntrack_max
9
262144
root@fw:~# conntrack -S | head -2
cpu=0   	found=0 invalid=0 insert=0 insert_failed=0 drop=0 early_drop=0 error=0 search_restart=0 clash_resolve=0 chaintoolong=0 
cpu=1   	found=0 invalid=0 insert=0 insert_failed=0 drop=0 early_drop=0 error=0 search_restart=0 clash_resolve=0 chaintoolong=0 
```

`conntrack -C` é quantas entradas existem agora, contra o máximo de 262.144. `conntrack -S` conta, por
processador, o que aconteceu com as entradas: **`drop` e `early_drop` subindo querem dizer que a
tabela está cheia** e novas conexões estão sendo recusadas, ou antigas despejadas para abrir espaço.
Aqui eles estão em 0. Num gráfico ao longo do tempo, o primeiro número é o que merece um alerta, bem
antes de chegar ao segundo.

Um plano escrito fica ao lado do gráfico: quem chamar no provedor, como ligar o serviço de limpeza de
tráfego, para qual endereço fazer o failover e quem decide. A primeira negação de serviço que alguém
vive costuma ser gasta procurando um número de telefone.
