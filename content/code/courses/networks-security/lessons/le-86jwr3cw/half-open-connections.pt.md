---
title: Conexões semiabertas e SYN cookies
version: 1
---

Uma conexão TCP começa com três pacotes: o `SYN` do cliente, o `SYN-ACK` do servidor, o `ACK` do
cliente. Entre o segundo e o terceiro, o servidor mantém uma **conexão semiaberta** (half-open
connection) na memória, esperando. Um cliente que envia `SYN`s e nunca termina, em geral a partir de
endereços de origem que não são os seus, enche essa memória, e clientes reais são recusados. Isso é
um **SYN flood**, o ataque de protocolo clássico.

A defesa já vem no Linux, e ligada por padrão. No `www`:

```
root@www:~# sysctl net.ipv4.tcp_syncookies net.ipv4.tcp_max_syn_backlog net.ipv4.tcp_synack_retries
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 1024
net.ipv4.tcp_synack_retries = 5
```

A fila de conexões semiabertas comporta 1.024, e um `SYN-ACK` é reenviado 5 vezes antes de o
servidor desistir. O que importa é `tcp_syncookies = 1`: **quando a fila enche, o servidor para de
guardar conexões semiabertas**. Ele codifica o que teria lembrado no número de sequência do seu
`SYN-ACK`, um *cookie*, e esquece a conexão. O `ACK` de um cliente real traz esse número de volta, o
servidor o confere e só então monta a conexão. Uma enxurrada de `SYN`s que nunca terminam agora não
obriga o servidor a lembrar de nada.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Duas linhas do tempo de um handshake TCP entre um cliente e um servidor. Sem SYN cookies, o servidor guarda uma entrada semiaberta do SYN até chegar o ACK do cliente. Com SYN cookies e a fila cheia, o servidor não guarda nada: escreve o que teria lembrado no número de sequência do SYN-ACK e reconstrói a conexão quando o ACK traz esse número de volta.\"><defs><marker id=\"sc-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"sc-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"20\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">sem cookies</text><text x=\"30\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">cliente</text><text x=\"270\" y=\"40\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">servidor</text><path d=\"M50 50 L50 200\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path><path d=\"M250 50 L250 200\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path><path d=\"M50 70 L250 95\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#sc-ah-paper-dim)\"></path><text x=\"130\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">SYN</text><path d=\"M250 115 L50 140\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#sc-ah-paper-dim)\"></path><text x=\"130\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">SYN-ACK</text><path d=\"M50 160 L250 185\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#sc-ah-paper-dim)\"></path><text x=\"140\" y=\"163\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">ACK</text><text x=\"260\" y=\"212\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">guarda uma entrada semiaberta</text><text x=\"380\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">com cookies, fila cheia</text><text x=\"390\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">cliente</text><text x=\"630\" y=\"40\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">servidor</text><path d=\"M410 50 L410 200\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path><path d=\"M610 50 L610 200\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path><path d=\"M410 70 L610 95\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#sc-ah-paper-dim)\"></path><text x=\"490\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">SYN</text><path d=\"M610 115 L410 140\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#sc-ah-paper-dim)\"></path><text x=\"490\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">SYN-ACK</text><path d=\"M410 160 L610 185\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#sc-ah-paper-dim)\"></path><text x=\"500\" y=\"163\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">ACK</text><text x=\"620\" y=\"212\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">não guarda nada</text><rect x=\"252\" y=\"95\" width=\"8\" height=\"90\" rx=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"620\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">seq = cookie</text></svg>", "caption": "Um SYN que nunca termina custa ao servidor uma vaga na fila, ou, com o cookie, nada.", "same": ["seq = cookie"]}
```

## O firewall tem o mesmo problema

O `fw` rastreia toda conexão que o atravessa, inclusive as que nunca se completam, então um SYN flood
passando por ele enche a tabela do conntrack da aula 1. Os timeouts dele decidem quanto tempo vive
uma entrada semiaberta:

```
root@fw:~# sysctl net.netfilter.nf_conntrack_tcp_timeout_syn_sent net.netfilter.nf_conntrack_tcp_timeout_syn_recv net.netfilter.nf_conntrack_tcp_timeout_established
net.netfilter.nf_conntrack_tcp_timeout_syn_sent = 120
net.netfilter.nf_conntrack_tcp_timeout_syn_recv = 60
net.netfilter.nf_conntrack_tcp_timeout_established = 432000
```

Uma conexão que só viu um `SYN` é mantida por 120 segundos; uma que viu o `SYN-ACK`, por 60. Perto
dos cinco dias de uma conexão estabelecida, parecem pouco, mas um flood se mede em milhares de pacotes
por segundo, e cada segundo de timeout são milhares de entradas. Encurtar os que pertencem a
handshakes não terminados não custa nada aos clientes legítimos, que terminam em milissegundos:

```
root@fw:~# sysctl -w net.netfilter.nf_conntrack_tcp_timeout_syn_recv=20
net.netfilter.nf_conntrack_tcp_timeout_syn_recv = 20
```

Uma mudança com `sysctl -w` dura até o próximo reinício. A versão permanente vai num arquivo em
`/etc/sysctl.d/`, onde também fica documentada para a próxima pessoa.
