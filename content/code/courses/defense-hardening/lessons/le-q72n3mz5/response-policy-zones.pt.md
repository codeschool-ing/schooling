---
title: Uma lista de bloqueio que o resolvedor lê
version: 1
---

**Uma zona de política de resposta, RPZ, é uma lista de nomes e do que o resolvedor deve dizer sobre
cada um no lugar da verdade.** Ela é escrita no formato de um arquivo de zona DNS comum, e é por isso
que pode ser compartilhada entre organizações e transferida como qualquer outra zona, e todos os
grandes resolvedores a leem: BIND, Unbound, PowerDNS e os serviços de DNS da maioria dos fornecedores
de segurança.

Cada linha diz um gatilho e uma ação. As duas ações que esta aula usa:

| escrita como | o resolvedor responde |
|---|---|
| `nome CNAME .` | `NXDOMAIN`, "este nome não existe" |
| `nome A 192.168.60.53` | o endereço dado, seja qual for a resposta verdadeira |

Um nome pode ser exato, `boletos-jatoba.example.net`, ou uma família inteira com curinga,
`*.cobranca-urgente.example.org`, que cobre todo nome abaixo desse domínio. As duas entradas abaixo
são as primeiras decisões do escritório. A primeira é um domínio parecido que manda boletos falsos aos
clientes da Jatobá; a segunda é um domínio cujos subdomínios todos servem para entregar arquivos que
ninguém deveria abrir.

```
root@dns:~# cat > /etc/unbound/feed.zone <<'EOF'
$TTL 300
@ SOA localhost. hostmaster.jatoba.example. 1 3600 600 86400 300
@ NS localhost.
boletos-jatoba.example.net      CNAME .
*.cobranca-urgente.example.org  A     192.168.60.53
EOF
root@dns:~# cat >> /etc/unbound/unbound.conf.d/jatoba.conf <<'EOF'
rpz:
    name: feed.jatoba.example
    zonefile: /etc/unbound/feed.zone
    rpz-log: yes
    rpz-log-name: feed
EOF
root@dns:~# unbound-checkconf && systemctl restart unbound; systemctl is-active unbound
unbound-checkconf: no errors in /etc/unbound/unbound.conf
active
```

As três primeiras linhas são o que faz dela uma zona: uma validade padrão de 300 segundos para cada
resposta, e os dois registros que toda zona tem, o `SOA` e o `NS`. Os valores deles importam para uma
zona transferida entre servidores; para um arquivo lido do disco, basta que estejam ali. O bloco
`rpz:` acrescentado à configuração do resolvedor aponta para o arquivo, dá a ele um nome para os logs
e pede ao Unbound que registre cada aplicação. Esse é o bloco que o `respip` do `module-config`
estava esperando.

## O que o desk vê agora

```
ana@desk:~$ dig boletos-jatoba.example.net | grep status
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 11682
ana@desk:~$ dig +short pagamento.cobranca-urgente.example.org
192.168.60.53
ana@desk:~$ dig +short web.jatoba.example
192.168.60.10
```

O domínio parecido não existe, até onde o `desk` consegue saber. O domínio de downloads responde com
o endereço do próprio `dns`, que a próxima seção põe para trabalhar. E o nome do escritório continua
intacto: uma zona de política muda só os nomes que lista.

## O que o resolvedor anota

```
root@dns:~# journalctl -u unbound -o cat | grep "rpz: applied" | cut -d" " -f3-
rpz: applied [feed] boletos-jatoba.example.net. rpz-nxdomain 192.168.60.20@46963 boletos-jatoba.example.net. A IN
rpz: applied [feed] *.cobranca-urgente.example.org. rpz-local-data 192.168.60.20@54498 pagamento.cobranca-urgente.example.org. A IN
```

Cada linha diz que zona bateu, que entrada bateu (o curinga aparece como foi escrito), o que foi feito
e quem perguntou: `192.168.60.20` é o `desk`, e o número depois do `@` é a porta de onde saiu a
pergunta. **Uma consulta bloqueada é um achado, não só uma prevenção.** Alguém no `desk` seguiu um
link para um domínio que o escritório listou como perigoso, e quem lê este log fica sabendo em um
minuto, sem que ninguém no `desk` tenha avisado nada.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l14-rpz\" aria-label=\"Três perguntas do desk chegam ao dns e saem com três respostas diferentes. web.jatoba.example não está na lista e recebe o endereço verdadeiro, 192.168.60.10. boletos-jatoba.example.net bate numa entrada escrita CNAME ponto e recebe NXDOMAIN. pagamento.cobranca-urgente.example.org bate numa entrada curinga com endereço e recebe 192.168.60.53, o sinkhole.\"><defs><marker id=\"l14-rpz-dh-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l14-rpz-dh-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l14-rpz-dh-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"290.0\" y=\"90.0\" width=\"140.0\" height=\"70.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"117.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">dns</text><text x=\"360.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">lê o feed.zone</text><text x=\"20.0\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">web.jatoba.example</text><path d=\"M220.0 50.0 L290.0 125.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.1\" fill=\"none\" marker-end=\"url(#l14-rpz-dh-ah-paper-dim)\"></path><path d=\"M430.0 125.0 L520.0 50.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-rpz-dh-ah-phosphor)\"></path><text x=\"530.0\" y=\"42.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fora da lista</text><text x=\"530.0\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">192.168.60.10</text><text x=\"20.0\" y=\"110.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">boletos-jatoba.example.net</text><path d=\"M220.0 110.0 L290.0 125.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.1\" fill=\"none\" marker-end=\"url(#l14-rpz-dh-ah-paper-dim)\"></path><path d=\"M430.0 125.0 L520.0 110.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-rpz-dh-ah-amber)\"></path><text x=\"530.0\" y=\"102.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">CNAME .</text><text x=\"530.0\" y=\"118.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">NXDOMAIN</text><text x=\"20.0\" y=\"170.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">pagamento.cobranca-urgente…</text><path d=\"M220.0 170.0 L290.0 125.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.1\" fill=\"none\" marker-end=\"url(#l14-rpz-dh-ah-paper-dim)\"></path><path d=\"M430.0 125.0 L520.0 170.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-rpz-dh-ah-amber)\"></path><text x=\"530.0\" y=\"162.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">A 192.168.60.53</text><text x=\"530.0\" y=\"178.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">192.168.60.53</text><text x=\"360.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a pergunta é a mesma; a lista decide a resposta</text></svg>", "caption": "Uma zona de política muda só os nomes que lista, e diz por quê a cada vez."}
```

Por que `NXDOMAIN` para um e um endereço para o outro? `NXDOMAIN` é a recusa silenciosa: o programa
não recebe nada e desiste, e não se aprende mais nada. Um endereço manda o programa para um lugar que
você escolhe, e esse lugar pode registrar o que ele estava tentando fazer. A próxima seção o monta.
