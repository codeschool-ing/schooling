---
title: Estações de trabalho não têm o que tratar entre si
version: 1
---

Assim que um software roda num laptop, ele procura a próxima máquina. Numa LAN plana da equipe, ele
encontra todos os outros computadores respondendo nas portas que o Windows usa para compartilhar
arquivos, a **445**, e para oferecer área de trabalho remota, a **3389**. No laboratório, dois
processos escutando fazem as vezes desses serviços; suba-os no `desk`, como root, com
`for p in 445 3389; do setsid socat TCP-LISTEN:$p,bind=192.168.10.21,fork,reuseaddr SYSTEM:"echo desk $p" </dev/null >/dev/null 2>&1 & done`.
Em `desk`, as duas respondem a qualquer um do segmento:

```
ana@laptop:~$ probe desk:445 desk:3389
desk:445               open
desk:3389              open
```

A aula 4 já notou que o firewall nunca vê esse tráfego, porque as duas máquinas estão no mesmo
segmento. **Estações de trabalho raramente precisam falar umas com as outras**: os arquivos ficam em
servidores, a impressão passa por um servidor de impressão, o suporte se conecta a partir do segmento
de gestão. Então a regra é a mesma de todo o resto deste curso, aplicada na própria máquina: permitir
o que é usado, descartar o resto.

`desk` ganha um firewall de host:

```
root@desk:~# cat host.nft
flush ruleset
table inet host {
  chain input {
    type filter hook input priority filter; policy drop;
    ct state established,related accept
    iifname "lo" accept
    icmp type echo-request limit rate 5/second accept
    ip saddr 192.168.99.0/24 tcp dport { 22, 3389 } accept comment "support works from the management segment"
  }
}
root@desk:~# nft -f host.nft
```

Política `drop` no input. Respostas e loopback passam, o ping é respondido a uma taxa limitada, e a
área de trabalho remota e o SSH são permitidos **só a partir do segmento de gestão**, onde o suporte
trabalha. O compartilhamento de arquivos não é permitido de jeito nenhum, porque uma estação de
trabalho não deveria servir arquivos. A partir de `laptop`, as duas portas agora estão fechadas:

```
ana@laptop:~$ probe desk:445 desk:3389
desk:445               blocked
desk:3389              blocked
```

E `desk` continua funcionando normalmente, porque as suas próprias conexões de saída voltam como
`established`:

```
ana@desk:~$ curl -s https://www.example.com/
orders service: ok
```

**De todos os controles de rede, este é o que mais faz para impedir a propagação de ransomware.** Não
custa nada além da disciplina de fazê-lo em toda estação de trabalho, e a gestão centralizada de
firewalls de host existe para garantir essa disciplina. O equivalente no Windows é o firewall embutido dele, configurado por política de
grupo (*group policy*) para recusar compartilhamento de arquivos e área de trabalho remota vindos da
LAN. A aula 21 generaliza a ideia para todo servidor.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"A LAN da equipe com seus firewalls de host. As tentativas do laptop de alcançar desk na porta 445, compartilhamento de arquivos, e na 3389, área de trabalho remota, são descartadas pelo próprio firewall de desk. admin, no segmento de gestão, alcança desk na 3389 através do fw, o que o firewall de desk permite. As conexões de saída do próprio desk até a loja continuam funcionando.\"><defs><marker id=\"lt-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"lt-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"lt-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"30\" width=\"420\" height=\"110\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"18\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">LAN da equipe</text><rect x=\"30\" y=\"70\" width=\"140\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"40\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">laptop</text><text x=\"40\" y=\"103\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">192.168.10.20</text><rect x=\"260\" y=\"70\" width=\"150\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"270\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">desk</text><text x=\"270\" y=\"103\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">firewall de host: drop</text><path d=\"M170 85 L255 85\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#lt-ah-amber)\" stroke-dasharray=\"4 3\"></path><text x=\"176\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">:445  :3389</text><text x=\"176\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">descartado em desk</text><rect x=\"560\" y=\"70\" width=\"140\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"570\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">admin</text><text x=\"570\" y=\"103\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">gestão</text><path d=\"M560 100 L410 105\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#lt-ah-phosphor)\"></path><text x=\"470\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">:3389</text><text x=\"455\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">permitido da gestão</text><rect x=\"260\" y=\"166\" width=\"150\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"270\" y=\"182\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">www</text><text x=\"270\" y=\"199\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a loja, na DMZ</text><path d=\"M335 116 L335 166\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#lt-ah-paper-dim)\"></path><text x=\"326\" y=\"156\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o tráfego do próprio desk, para fora</text></svg>", "caption": "Vizinhos de segmento deixam de confiar uns nos outros; o suporte continua entrando, de onde o suporte trabalha."}
```
