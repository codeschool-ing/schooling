---
title: Dois jeitos de fechar uma porta
version: 1
---

**Uma porta se fecha num de dois lugares: na máquina, por não haver nada escutando, ou na frente do
listener, por um filtro que descarta o que chega.** A aula 1 fez o primeiro: removeu os serviços de
que o portal não precisava, e a porta fechou porque não sobrou programa atrás dela. Esta aula faz o
segundo, e os dois não são alternativas. Quem defende quer os dois.

Suba o laboratório com `sudo bash hostlab.sh up web desk admin`. Como em toda aula, o `web` é novo: o
servidor FTP, o telnet e o `rpcbind` que a aula 1 removeu estão de volta. A partir do `desk`, tente
cinco portas:

```
ana@desk:~$ for p in 21 22 23 80 111; do nc -zv -w2 web $p; done
Connection to web (192.168.60.10) 21 port [tcp/ftp] succeeded!
Connection to web (192.168.60.10) 22 port [tcp/ssh] succeeded!
Connection to web (192.168.60.10) 23 port [tcp/telnet] succeeded!
Connection to web (192.168.60.10) 80 port [tcp/http] succeeded!
Connection to web (192.168.60.10) 111 port [tcp/sunrpc] succeeded!
```

No `web`, as mesmas cinco, mais o portal atrás do nginx, estão escutando:

```
ana@web:~$ sudo ss -Htln | awk '{print $4}'
127.0.0.1:8080
0.0.0.0:111
0.0.0.0:80
0.0.0.0:21
0.0.0.0:22
0.0.0.0:23
```

## Contra o que cada jeito protege

| | fecha a porta | protege contra | deixa passar |
|---|---|---|---|
| **remover o listener** | tirando o programa | os bugs dele, agora e depois; os erros de configuração dele | um listener novo amanhã: um pacote, um servidor de teste, uma ferramenta que alguém iniciou à mão |
| **filtrar** | descartando pacotes antes de qualquer programa vê-los | todo listener que as regras não citam, inclusive o de amanhã | uma falha num serviço que as regras permitem, alcançável de propósito |

Os dois cobrem as lacunas um do outro. A remoção da aula 1 quer dizer que o servidor FTP não pode ser
atacado de jeito nenhum, diga o firewall o que disser. Um filtro que aceita só o que o trabalho
precisa quer dizer que o próximo serviço que alguém instalar, por engano ou de propósito, fica
inalcançável até alguém decidir que não deveria ficar. **Um firewall de host é o inventário do que
pode ser alcançado, imposto pelo kernel.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l05-two-layers\" aria-label=\"Pacotes do desk chegam ao web e encontram duas camadas. A primeira é a chain de entrada do firewall, com policy drop: a porta 80 é aceita para qualquer um, a 22 só a partir do admin e do jump, e todo o resto para ali. A segunda camada são os listeners da máquina. FTP, telnet e rpcbind continuam escutando atrás do firewall, inalcançáveis; a aula 1 também os removeu, para que nenhuma camada dependa da outra.\"><defs><marker id=\"l05-two-layers-dh-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l05-two-layers-dh-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"110.0\" width=\"110.0\" height=\"60.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"75.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">desk</text><rect x=\"190.0\" y=\"30.0\" width=\"170.0\" height=\"230.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"275.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">chain de entrada</text><text x=\"275.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">policy drop</text><rect x=\"205.0\" y=\"90.0\" width=\"140.0\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"213.0\" y=\"102.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">tcp 80</text><text x=\"337.0\" y=\"102.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">qualquer um</text><rect x=\"205.0\" y=\"122.0\" width=\"140.0\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"213.0\" y=\"134.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">tcp 22</text><text x=\"337.0\" y=\"134.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">admin, jump</text><rect x=\"205.0\" y=\"154.0\" width=\"140.0\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"213.0\" y=\"166.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">tcp 21</text><text x=\"337.0\" y=\"166.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">descartada</text><rect x=\"205.0\" y=\"186.0\" width=\"140.0\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"213.0\" y=\"198.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">tcp 23</text><text x=\"337.0\" y=\"198.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">descartada</text><rect x=\"205.0\" y=\"218.0\" width=\"140.0\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"213.0\" y=\"230.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">tcp 111</text><text x=\"337.0\" y=\"230.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">descartada</text><path d=\"M130.0 140.0 L190.0 140.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l05-two-layers-dh-ah-paper-dim)\"></path><rect x=\"430.0\" y=\"30.0\" width=\"270.0\" height=\"230.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"565.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">listeners no web</text><rect x=\"445.0\" y=\"90.0\" width=\"240.0\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"457.0\" y=\"102.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">nginx :80</text><rect x=\"445.0\" y=\"122.0\" width=\"240.0\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"457.0\" y=\"134.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">sshd :22</text><rect x=\"445.0\" y=\"154.0\" width=\"240.0\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"457.0\" y=\"166.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">vsftpd :21</text><rect x=\"445.0\" y=\"186.0\" width=\"240.0\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"457.0\" y=\"198.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">inetd :23</text><rect x=\"445.0\" y=\"218.0\" width=\"240.0\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"457.0\" y=\"230.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">rpcbind :111</text><path d=\"M345.0 102.0 L445.0 102.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-two-layers-dh-ah-phosphor)\"></path><path d=\"M345.0 134.0 L445.0 134.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-two-layers-dh-ah-phosphor)\"></path><text x=\"565.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">ainda escutando, inalcançáveis</text></svg>", "caption": "O filtro esconde o que continua rodando. Removê-lo, como a aula 1 fez, é a outra camada.", "same": ["admin, jump"]}
```

## Negar por padrão

O filtro da próxima seção começa por uma regra escrita por último e que vale para tudo: descartar.
Cada regra acima dela é uma permissão para uma coisa de que o trabalho precisa. Essa ordem se chama
**negar por padrão**, e é a forma de todo conjunto de regras de firewall deste curso. O contrário,
aceitar tudo e descartar o que se sabe ser ruim, é uma lista dos ataques em que alguém pensou no dia
em que a escreveu.

Esta aula filtra o que chega à máquina, a direção de **entrada**. Filtrar o que uma máquina envia, e
filtrar por aplicação, é assunto da aula 10. A segunda metade desta aula fecha outro tipo de porta: a
tomada USB de uma estação, que é um caminho de entrada para dados, e de saída.
