---
title: Escopo: as bordas, e a evidência delas
version: 1
---

O **escopo** é a resposta para "o que este incidente inclui?": quais contas, quais hosts, quais dados, quais
partes de fora. Ele define o trabalho de todas as fases seguintes, porque você contém, erradica e recupera o
que está no escopo. Definir o escopo é iterativo: comece pelo que sabe, pergunte o que cada item tocou, e pare
quando as respostas pararem de crescer.

A partir do endereço, quais contas ele usou?

```
ana@soc:~/week$ sqlite3 -header -column siem.db "SELECT DISTINCT user FROM logs WHERE src_ip = '203.0.113.66' AND action = 'success'"
user 
-----
bruno
```

A partir dessa conta, quais hosts ela alcançou naquela noite?

```
ana@soc:~/week$ sqlite3 -header -column siem.db "SELECT host, src_ip, count(*) AS logins FROM logs WHERE user = 'bruno' AND action = 'success' AND timestamp BETWEEN '2026-09-17 05:00' AND '2026-09-17 06:30' GROUP BY host, src_ip"
host   src_ip         logins
-----  -------------  ------
files  198.51.100.22  1     
gw     203.0.113.66   2     
```

A partir desses hosts, o que saiu?

```
ana@soc:~/week$ sqlite3 -header -column siem.db "SELECT dst_ip, dst_port, count(*) AS n FROM logs WHERE src_ip = '192.168.20.10' AND product = 'firewall' AND timestamp BETWEEN '2026-09-17 05:00' AND '2026-09-17 06:30' GROUP BY 1, 2"
dst_ip         dst_port  n
-------------  --------  -
203.0.113.200  443       1
```

A corrente se fecha: um endereço, uma conta, dois hosts, um destino lá fora. Desenhado, com a outra metade:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"O escopo do incidente de quinta como um caminho: o endereço externo 203.0.113.66 chegou ao gw como bruno; do gw, a conta do bruno chegou ao files; o files enviou dados para 203.0.113.200. Esses quatro estão no escopo. Embaixo, o que foi conferido e ficou fora do escopo: as outras quatro contas da equipe, e todo outro destino para o qual o files enviou, que foi só o provedor de backup.\"><rect x=\"10\" y=\"20\" width=\"700\" height=\"96\" rx=\"3\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"20\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">no escopo</text><rect x=\"30\" y=\"46\" width=\"150\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"105.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">203.0.113.66</text><text x=\"105.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fora</text><rect x=\"200\" y=\"46\" width=\"150\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"275.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">gw</text><text x=\"275.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">bruno, senha, depois chave</text><rect x=\"380\" y=\"46\" width=\"150\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"455.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">files</text><text x=\"455.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">bruno, a partir do gw</text><rect x=\"550\" y=\"46\" width=\"150\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"625.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">203.0.113.200</text><text x=\"625.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">612 MB recebidos</text><path d=\"M180 74 L200 74\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M200 74 L192.0 70.0 L192.0 78.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><path d=\"M350 74 L370 74\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M370 74 L362.0 70.0 L362.0 78.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><path d=\"M530 74 L550 74\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M550 74 L542.0 70.0 L542.0 78.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><text x=\"20\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">conferido, e fora do escopo</text><rect x=\"20\" y=\"152\" width=\"320\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"180.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">ana, carla, diego, helena</text><text x=\"180.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nenhum login de 203.0.113.66</text><rect x=\"380\" y=\"152\" width=\"320\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"540.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">outros destinos a partir do files</text><text x=\"540.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">só o backup, 203.0.113.150</text></svg>", "caption": "No escopo, e conferido e fora. Escopo é uma afirmação com evidência dos dois lados da linha.", "same": ["ana, carla, diego, helena"]}
```

A linha de baixo é a metade que a maioria dos escopos deixa de fora. **"Fora do escopo" também é uma
afirmação**, e precisa de evidência própria: as outras quatro contas não tiveram login a partir do endereço, e
o `files` não enviou nada naquela noite além do backup e de `203.0.113.200`. Escreva as duas coisas, com as
consultas que as mostraram, porque a primeira pergunta da diretoria vai ser "pode ser mais?", e "conferimos
estes, assim" é uma resposta diferente de "achamos que não".

O escopo também tem uma dimensão de **dados** que os logs respondem mal. O fluxo diz que 612 MB saíram; não diz
quais 612 MB. Quais arquivos de clientes estavam no `files`, e quais deles a conta conseguia ler, é pergunta
para o dono do servidor de arquivos, e a resposta decide a aula 21.
