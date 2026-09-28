---
title: Uma só entrada, e uma chave que sabe onde mora
version: 1
---

A administração é o acesso mais poderoso da rede, então ganha o caminho mais estreito. O padrão é um
**jump host** (também chamado de bastion): uma máquina endurecida no segmento de gestão, a única
origem de onde qualquer servidor aceita SSH, onde toda sessão administrativa começa e fica registrada.
No laboratório, é o `admin`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Acesso administrativo ao db. Do laptop, na LAN da equipe, o SSH é bloqueado pelo firewall. De app, no segmento de servidores, o SSH é bloqueado pelo firewall do próprio db; só a porta 5432 está aberta para ele. De admin, a máquina de salto, o SSH é aceito, e a chave só vale a partir desse endereço. De admin2, com uma cópia da mesma chave, o SSH chega ao db e a chave é recusada.\"><defs><marker id=\"jh-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"jh-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"jh-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"560\" y=\"80\" width=\"140\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"570\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">db</text><text x=\"570\" y=\"113\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">firewall de host, from=</text><rect x=\"20\" y=\"20\" width=\"110\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"35.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">laptop</text><path d=\"M130 35 L560 103\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#jh-ah-amber)\" stroke-dasharray=\"4 3\"></path><text x=\"150\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">SSH: bloqueado no fw</text><rect x=\"20\" y=\"70\" width=\"110\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"85.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">app</text><path d=\"M130 85 L560 103\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#jh-ah-paper-dim)\"></path><text x=\"150\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">só 5432; SSH bloqueado no db</text><rect x=\"20\" y=\"120\" width=\"110\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"135.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">admin</text><path d=\"M130 135 L560 103\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#jh-ah-phosphor)\"></path><text x=\"150\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">SSH aceito: a máquina de salto</text><rect x=\"20\" y=\"170\" width=\"110\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"185.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">admin2</text><path d=\"M130 185 L560 103\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#jh-ah-amber)\" stroke-dasharray=\"4 3\"></path><text x=\"150\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">mesma chave, lugar errado: recusada</text></svg>", "caption": "Uma só entrada para a administração, e uma chave que só funciona a partir dela."}
```

A matriz do firewall já só deixa o SSH chegar aos servidores a partir da gestão; o firewall de host
de `db` estreitou isso ao endereço de `admin`, e só a ele.

Endereços, porém, podem ser emprestados, e chaves podem ser copiadas. O SSH deixa um servidor prender
uma chave ao lugar de onde ela pode ser usada, no arquivo `authorized_keys` de `db`:

```
root@db:~# cut -c1-96 /home/ana/.ssh/authorized_keys
from="192.168.99.10",no-agent-forwarding,no-port-forwarding,no-X11-forwarding ssh-ed25519 AAAAC3
```

`from="192.168.99.10"`: esta chave só é aceita a partir do jump host. As outras opções removem o que
um login administrativo raramente precisa: encaminhar o agente SSH, encaminhar portas, encaminhar o
X11. Cada uma é um jeito de transformar um login num caminho adiante. A partir do jump host:

```
ana@admin:~$ ssh db hostname
db
```

`db`. Agora a mesma chave privada, copiada para uma segunda máquina no segmento de gestão, `admin2`,
e o firewall de host instruído a deixar `admin2` se conectar, para que só a restrição da chave fique
no caminho:

```
ana@admin2:~$ ssh db hostname; echo "exit $?"
ana@db: Permission denied (publickey).
exit 255
```

**`Permission denied (publickey)`**: a chave estava certa e o lugar estava errado. Uma chave copiada,
o jeito mais comum de o acesso administrativo vazar, não serve para nada fora do jump host.

O próprio jump host passa então a ser o que mais precisa de proteção: autenticação multifator para as
pessoas que fazem login nele, seus próprios logs enviados para outro lugar como a aula 16 pediu, nada
mais instalado nele, e nenhum jeito de alcançá-lo a partir da LAN da equipe, o que a matriz da aula 4
já garante.
