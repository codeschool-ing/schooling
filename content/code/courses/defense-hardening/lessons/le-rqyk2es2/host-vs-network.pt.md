---
title: Um firewall em cada máquina
version: 1
---

**Um firewall de rede decide o que pode passar entre segmentos. Um firewall de host decide o que
pode chegar a uma máquina, e sair dela.** A imagem comum põe toda a filtragem na borda, entre o
escritório e a internet, e trata tudo o que está dentro como confiável. Aí uma máquina de dentro é
tomada, e a borda não tem nada a dizer sobre o que ela faz em seguida, porque tudo o que ela faz em
seguida acontece dentro.

O laboratório da Jatobá mostra o problema sem nada dar errado. Todas as máquinas dividem um
segmento, e nada no segmento filtra coisa alguma:

```
ana@desk:~$ nc -zv -w2 web 22 2>&1; nc -zv -w2 web 80 2>&1
Connection to web (192.168.60.10) 22 port [tcp/ssh] succeeded!
Connection to web (192.168.60.10) 80 port [tcp/http] succeeded!
ana@web:~$ sudo -u portal nc -zv -w2 desk 22 2>&1
Connection to desk (192.168.60.20) 22 port [tcp/ssh] succeeded!
```

O `desk` alcança o SSH e o portal no `web`, de que pode precisar. E o `web`, com a própria conta do
portal, alcança o SSH do `desk`, de que o portal nunca precisa. Se o portal um dia rodar um comando
para o qual não foi escrito, do jeito que a aula 8 encenou, essa é a primeira porta aberta que ele
encontra: de uma máquina para a seguinte, o que se chama **movimento lateral**.
É assim que um
único servidor comprometido vira um escritório comprometido.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l10-lateral\" aria-label=\"Duas máquinas num segmento. No web, dois programas: o nginx, rodado pela conta www-data, e o portal, rodado pela conta portal. A partir do desk, conexões ao nginx na porta 80 e ao SSH do web são permitidas. A partir do web, a tentativa do portal de abrir o SSH do desk é recusada pela regra por conta, e qualquer conexão nova que o web inicie rumo ao desk é descartada pela lista de saída.\"><defs><marker id=\"l10-lateral-dh-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l10-lateral-dh-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"30.0\" y=\"50.0\" width=\"230.0\" height=\"190.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"42.0\" y=\"68.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">desk</text><rect x=\"420.0\" y=\"50.0\" width=\"280.0\" height=\"190.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"432.0\" y=\"68.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">web</text><rect x=\"470.0\" y=\"90.0\" width=\"200.0\" height=\"40.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"570.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">nginx</text><text x=\"570.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">conta www-data</text><rect x=\"470.0\" y=\"170.0\" width=\"200.0\" height=\"40.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"570.0\" y=\"184.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">portal</text><text x=\"570.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">conta portal</text><path d=\"M260.0 100.0 L470.0 100.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l10-lateral-dh-ah-phosphor)\"></path><text x=\"365.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">portas 80, 22: permitidas</text><path d=\"M470.0 190.0 L260.0 190.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l10-lateral-dh-ah-amber)\"></path><text x=\"365.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">portal para desk:22</text><text x=\"365.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">recusado: regra por conta</text><text x=\"365.0\" y=\"255.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o que o web iniciar: descartado pela lista de saída</text><text x=\"360.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">o mesmo segmento, filtrado no host</text></svg>", "caption": "Nada entre as duas máquinas filtra coisa alguma. As regras moram no web."}
```

Um firewall de host responde a três perguntas que um firewall de rede não consegue:

- **Que programa?** Um equipamento de rede vê endereços e portas. A própria máquina sabe que
  processo é dono de cada socket, que conta o roda e que serviço o iniciou, então uma regra pode
  dizer *o portal não pode se conectar a lugar nenhum* e deixar todos os outros programas em paz.
- **E os vizinhos da máquina?** O tráfego entre duas máquinas do mesmo segmento nunca cruza um
  firewall de rede. Só os dois hosts o veem.
- **E quando ela sai?** Um notebook no Wi-Fi de um café está fora de todo controle de rede do
  escritório. O firewall dele é o único que ele leva junto.

**Um não substitui o outro.** O firewall de rede é um lugar só para impor uma política a muitas
máquinas, e o firewall de host é a última palavra sobre cada uma. A aula 5 já deu ao `web` uma
política de entrada; esta aula trata das regras que um equipamento de rede jamais conseguiria
escrever, por aplicação, e da direção que a aula 5 deixou aberta: **a saída**.

Suba o laboratório com as máquinas que esta aula usa:

```sh
sudo bash hostlab.sh up web desk
```
