---
title: O que um firewall decide, e onde
version: 1
---

Um firewall não é uma parede. É uma **lista de perguntas feitas sobre cada pacote enquanto ele
atravessa uma máquina**, e um veredito para cada resposta: deixar passar ou descartar. Tudo o que
este curso constrói do lado da rede se resume a escrever bem essas perguntas.

Este curso tem um laboratório só, e toda aula o começa do zero. É uma pequena empresa: um firewall
chamado `fw` com cinco interfaces de rede e, atrás de cada uma, um segmento que merece um grau de
confiança diferente.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 410\" role=\"img\" aria-label=\"O laboratório do curso. No meio, o firewall fw. Acima dele, o segmento da internet, 203.0.113.0/24, com remote, um desconhecido, e branch, o roteador da filial. À esquerda, a LAN da equipe, 192.168.10.0/24, com laptop e desk. À direita, a DMZ, 192.0.2.0/24, com www e dns. Abaixo, o segmento de servidores, 192.168.20.0/24, com app e db, e o segmento de gestão, 192.168.99.0/24, com admin. Cada segmento só alcança os outros através do fw.\"><defs><marker id=\"lm-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><path d=\"M360 180 L360 96\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path><path d=\"M290 203 L206 203\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path><path d=\"M430 203 L514 203\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path><path d=\"M330 226 L230 300\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path><path d=\"M390 226 L490 300\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path><text x=\"366\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">eth0</text><text x=\"248\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">eth2</text><text x=\"472\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">eth1</text><text x=\"262\" y=\"262\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">eth3</text><text x=\"458\" y=\"262\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">eth4</text><rect x=\"200\" y=\"10\" width=\"320\" height=\"86\" rx=\"3\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"208\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">internet</text><text x=\"510\" y=\"22\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">203.0.113.0/24</text><rect x=\"215\" y=\"36\" width=\"130\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"225\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">remote</text><text x=\"225\" y=\"69\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um desconhecido</text><rect x=\"360\" y=\"36\" width=\"145\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"370\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">branch</text><text x=\"370\" y=\"69\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a filial</text><rect x=\"290\" y=\"180\" width=\"140\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"300\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">fw</text><text x=\"300\" y=\"213\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">roteia e filtra</text><rect x=\"10\" y=\"130\" width=\"196\" height=\"146\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"18\" y=\"142\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">LAN da equipe</text><text x=\"198\" y=\"142\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">192.168.10.0/24</text><rect x=\"24\" y=\"158\" width=\"168\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">laptop</text><text x=\"34\" y=\"191\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">192.168.10.20</text><rect x=\"24\" y=\"214\" width=\"168\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">desk</text><text x=\"34\" y=\"247\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">192.168.10.21</text><rect x=\"514\" y=\"130\" width=\"196\" height=\"146\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"522\" y=\"142\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">DMZ</text><text x=\"702\" y=\"142\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">192.0.2.0/24</text><rect x=\"528\" y=\"158\" width=\"168\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"538\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">www</text><text x=\"538\" y=\"191\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">192.0.2.80</text><rect x=\"528\" y=\"214\" width=\"168\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"538\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">dns</text><text x=\"538\" y=\"247\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">192.0.2.53</text><rect x=\"40\" y=\"300\" width=\"330\" height=\"100\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"48\" y=\"312\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">servidores</text><text x=\"362\" y=\"312\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">192.168.20.0/24</text><rect x=\"54\" y=\"330\" width=\"148\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"64\" y=\"346\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">app</text><text x=\"64\" y=\"363\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">192.168.20.10</text><rect x=\"212\" y=\"330\" width=\"148\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"222\" y=\"346\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">db</text><text x=\"222\" y=\"363\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">192.168.20.30</text><rect x=\"420\" y=\"300\" width=\"220\" height=\"100\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"428\" y=\"312\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">gestão</text><text x=\"632\" y=\"312\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">192.168.99.0/24</text><rect x=\"434\" y=\"330\" width=\"192\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"444\" y=\"346\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">admin</text><text x=\"444\" y=\"363\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">192.168.99.10</text></svg>", "caption": "Um firewall, cinco segmentos. Toda aula começa deste mapa.", "same": ["DMZ", "internet"]}
```

O `lab.sh`, ao lado do curso, o monta com namespaces de rede em um único computador Linux. Cada
namespace tem suas próprias interfaces, rotas e firewall, e por isso se comporta como uma máquina à
parte. Os endereços vêm das faixas reservadas para documentação, e nada no laboratório alcança a
internet de verdade.

**Quando o laboratório sobe, o `fw` roteia tudo e não filtra nada.** É o estado de mais redes do
que alguém admite, e vale a pena vê-lo uma vez. `remote` é um desconhecido no segmento da internet;
`db` guarda o banco de dados da empresa e `app`, a aplicação interna:

```
ana@remote:~$ nc -w2 192.168.20.30 5432 </dev/null
db ready
ana@remote:~$ curl -s -m2 http://192.168.20.10:8080/admin/
admin console
```

Um desconhecido abriu uma conexão na porta do banco de dados e leu a página de administração da
aplicação. Nada foi quebrado para isso. O roteador fez o seu trabalho, que é entregar pacotes, e
**ninguém no caminho perguntou se ele deveria**.

## Três lugares onde um pacote encontra as regras

O Linux passa um pacote pelas suas regras em pontos fixos, chamados **hooks**. Três importam para
filtrar:

| hook | o pacote está | exemplo no `fw` |
|---|---|---|
| `input` | endereçado a esta máquina | alguém abrindo SSH no próprio `fw` |
| `forward` | atravessando esta máquina rumo a outra | `laptop` alcançando `app` através do `fw` |
| `output` | saindo desta máquina, criado aqui | o `fw` perguntando um nome ao DNS |

Um firewall que protege as máquinas **atrás** dele escreve suas regras em `forward`. Um firewall de
host, que protege só a máquina onde roda, as escreve em `input`. A aula 21 põe um em cada servidor;
até lá, quase toda regra aqui fica em `forward`.

## O que uma regra pode olhar

Todo pacote carrega os mesmos poucos fatos nos cabeçalhos, e uma regra pode testar qualquer um:

- a **interface** por onde chegou e aquela por onde vai sair: `iifname "eth2"`, `oifname "eth3"`;
- o **endereço de origem e o de destino**: `ip saddr`, `ip daddr`;
- o **protocolo** e, para TCP e UDP, a **porta de origem e a de destino**: `tcp dport 8080`.

Os endereços, o protocolo e as duas portas formam a **quíntupla** (*five-tuple*), e juntos nomeiam
uma conversa. Interfaces importam tanto quanto endereços. Um endereço é escrito por quem enviou o
pacote, e a aula 8 mostra por que não dá para confiar nele sozinho; a interface é onde o cabo de
fato está.

A ferramenta no `fw` é o **nftables**, o comando `nft`. O `iptables` é o antecessor dele, e nas
distribuições atuais é uma camada de compatibilidade que escreve regras do nftables por baixo. No
`fw`, ele mesmo diz isso:

```
root@fw:~# iptables -V
iptables v1.8.10 (nf_tables)
```

As ideias deste curso são as mesmas nos dois, e nos appliances de firewall de que a aula 2 trata.
