---
title: Tráfego leste-oeste, testado
version: 1
---

O tráfego entre clientes e servidores é **norte-sul** (north-south); o tráfego entre servidores é
**leste-oeste** (east-west), e é a direção em que um atacante se move depois da primeira base de apoio
(aula 9). Com as regras geradas nos dois servidores, cada célula leste-oeste é testada a partir da sua
origem:

```
ana@app:~$ probe db:5432 db:22
db:5432                open
db:22                  blocked
ana@db:~$ probe app:8080 app:22
app:8080               blocked
app:22                 blocked
```

O `app` alcança o banco de dados e não o SSH de `db`; `db` não alcança nada em `app`. **Nenhuma dessas
conexões atravessa o `fw`**: as duas máquinas ficam no segmento de servidores, e antes desta aula as
duas estavam abertas. Depois, os outros papéis:

```
ana@www:~$ probe app:8080 db:5432
app:8080               open
db:5432                blocked
ana@admin:~$ probe app:22 db:22 db:5432
app:22                 open
db:22                  open
db:5432                blocked
```

O proxy alcança a aplicação e não o banco de dados. O papel de administração alcança o SSH nos dois
servidores e não a porta do banco de dados.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"O segmento de servidores depois da microssegmentação. app e db dividem um switch, e cada um tem o próprio firewall em volta. A partir do www, o proxy, só a porta 8080 de app está aberta. A partir de app, só a porta 5432 de db. A partir de admin, só o SSH de cada um. db não abre nada para app, e nada mais dentro do segmento está aberto.\"><defs><marker id=\"ms-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"ms-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"230\" y=\"20\" width=\"470\" height=\"190\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"238\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">segmento de servidores</text><rect x=\"250\" y=\"50\" width=\"180\" height=\"90\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><rect x=\"265\" y=\"70\" width=\"150\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"275\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">app</text><text x=\"275\" y=\"103\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">:8080  :22</text><rect x=\"500\" y=\"50\" width=\"180\" height=\"90\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><rect x=\"515\" y=\"70\" width=\"150\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"525\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">db</text><text x=\"525\" y=\"103\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">:5432  :22</text><path d=\"M430 93 L500 93\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#ms-ah-phosphor)\"></path><text x=\"465\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">:5432</text><rect x=\"20\" y=\"60\" width=\"120\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">www</text><text x=\"30\" y=\"93\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">papel proxy</text><path d=\"M140 85 L250 85\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#ms-ah-phosphor)\"></path><text x=\"200\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">:8080</text><rect x=\"20\" y=\"160\" width=\"120\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">admin</text><text x=\"30\" y=\"193\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">papel admin</text><path d=\"M140 175 L340 175 L340 140\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#ms-ah-paper-dim)\"></path><path d=\"M340 175 L590 175 L590 140\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#ms-ah-paper-dim)\"></path><text x=\"360\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">:22 em cada, só a partir de admin</text></svg>", "caption": "Um switch, duas máquinas, e um muro separado em volta de cada uma."}
```

O resultado é a matriz da aula 4, desenhada de novo no nível de máquinas individuais, **aplicada onde o
tráfego de fato está**. Um `app` comprometido agora alcança uma porta em uma outra máquina, a que a
aplicação precisa, e nada mais no seu próprio segmento.

Duas observações práticas. Os arquivos gerados são **substituídos inteiros** a cada execução, e é por
isso que começam com `flush ruleset`: as regras de um host são a saída da política, nunca editadas à
mão no host, ou a próxima geração remove a edição em silêncio. E o arquivo de política é o que se revisa
e versiona, como a aula 5 pediu para o do firewall: uma mudança em quem pode alcançar o banco de dados é
um diff de uma linha que alguém pode aprovar.
