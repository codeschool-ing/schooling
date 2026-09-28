---
title: O que custa guardar estado, e onde o sem estado ainda cabe
version: 1
---

Memória é o que torna um firewall com estado melhor, e memória é finita. No `fw`:

```
root@fw:~# sysctl net.netfilter.nf_conntrack_max net.netfilter.nf_conntrack_count
net.netfilter.nf_conntrack_max = 262144
net.netfilter.nf_conntrack_count = 7
root@fw:~# sysctl net.netfilter.nf_conntrack_tcp_timeout_established net.netfilter.nf_conntrack_udp_timeout net.netfilter.nf_conntrack_udp_timeout_stream net.netfilter.nf_conntrack_tcp_loose
net.netfilter.nf_conntrack_tcp_timeout_established = 432000
net.netfilter.nf_conntrack_udp_timeout = 30
net.netfilter.nf_conntrack_udp_timeout_stream = 120
net.netfilter.nf_conntrack_tcp_loose = 1
```

A tabela comporta até 262.144 entradas e tinha 7 em uso. **Uma conexão TCP estabelecida é mantida
por 432.000 segundos, cinco dias, depois do último pacote**, porque o conntrack não tem como saber
se uma conexão quieta morreu ou só está descansando. Um fluxo UDP é esquecido depois de 30 segundos,
ou depois de 120 quando vira um stream, com pacotes indo e voltando mais de uma vez.

Duas consequências decorrem disso, e as duas voltam mais adiante no curso:

- **A tabela pode ser enchida.** Toda conversa que alguém inicia custa uma entrada, mesmo uma que
  nunca se completa. Enchê-la de propósito é uma forma de negação de serviço, e a aula 6 mede as
  defesas: SYN cookies, limites de taxa e um tempo menor para conexões que nunca terminaram o
  handshake.
- **Um reinício esquece tudo.** Uma troca para um segundo firewall também, a menos que os dois
  compartilhem as tabelas. O que acontece com uma conexão encontrada no meio do fluxo depende do
  produto. O Linux, por padrão, trata o próximo pacote dela como `new`, que é o `1` em
  `nf_conntrack_tcp_loose` acima, e assim a conexão sobrevive onde uma regra a teria deixado
  começar. Um firewall mais estrito a chama de `invalid` e a descarta. Firewalls montados em pares
  sincronizam as tabelas para que a pergunta nem apareça.

## Onde um filtro sem estado ainda cabe

Sem estado não é obsoleto, é barato. Cabe onde há tráfego demais para lembrar e a decisão não
precisa de memória:

| lugar | por que sem estado |
|---|---|
| um roteador de núcleo ou de borda | milhões de fluxos; só descartar o que nunca pode ser legítimo, como um endereço de origem privado chegando da internet (aula 8) |
| na frente de um firewall com estado sob ataque | jogar fora uma enxurrada antes que ela chegue a uma tabela que poderia encher |
| uma ACL de switch ou roteador | o hardware compara cabeçalhos na velocidade da linha e não guarda tabela (aula 17) |

**Os dois são camadas, não rivais.** Um filtro sem estado barato na borda remove o que está
obviamente errado; o firewall com estado atrás dele decide quais conversas podem existir. A aula 2
acrescenta uma terceira camada, que lê o que vai dentro da conversa.
