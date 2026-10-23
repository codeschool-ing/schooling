---
title: Não dá para defender o que você não listou
version: 1
---

**Todas as aulas deste curso supuseram uma lista em silêncio.** A aula 1 tirou os serviços de que o
`web` não precisava, o que exigia saber que o `web` existia e qual era o trabalho dele. A aula 15 fez
os servidores aceitarem SSH só do bastião, o que funciona para os servidores que alguém configurou. A
aula 16 comparou versões instaladas com avisos, nas máquinas que alguém lembrou de conferir. A aula 17
distribuiu atualizações em anéis, para as máquinas que estavam nos anéis. Cada controle é aplicado às
"nossas máquinas", e **protege exatamente as máquinas de que alguém se lembrou**.

É por isso que os dois primeiros dos CIS Critical Security Controls, a lista priorizada publicada pelo
Center for Internet Security, não tratam de firewalls nem de antivírus. O controle 1 é um inventário
dos ativos da empresa: cada dispositivo, com dono e endereço. O controle 2 é um inventário de software:
o que está instalado e permitido em cada um. Eles vêm primeiro porque todo controle seguinte é aplicado
ao que eles produzem, e uma lacuna neles é uma lacuna em todos os outros de uma vez.

A imagem comum de um inventário é uma planilha que alguém preenche uma vez. A planilha é metade dele. A
outra metade é **medição**: perguntar à rede o que existe de fato e perguntar a cada máquina o que ela
roda de fato, e comparar isso com o que a planilha diz. Onde as duas discordam é por onde entram os
ataques das aulas anteriores: o servidor que ninguém corrigiu porque não estava na lista, o serviço que
ninguém endureceu porque ninguém sabia que estava escutando.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l18-loop\" aria-label=\"Duas fontes se encontram numa comparação. À esquerda, os registros: o hosts.csv com cinco máquinas e uma linha de base por papel. À direita, a medição: uma varredura da rede que acha sete máquinas, e uma coleta, em cada máquina, do que ela roda. No meio, a comparação produz achados, cada um com um dono, e as correções mudam as máquinas, o que a próxima medição vê.\"><defs><marker id=\"l18-loop-dh-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l18-loop-dh-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"110.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">o que o escritório diz</text><text x=\"610.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">o que existe</text><rect x=\"30.0\" y=\"40.0\" width=\"160.0\" height=\"50.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"110.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">hosts.csv</text><text x=\"110.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cinco máquinas, donos</text><rect x=\"30.0\" y=\"120.0\" width=\"160.0\" height=\"50.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"110.0\" y=\"137.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">baseline.json</text><text x=\"110.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o que cada papel roda</text><rect x=\"530.0\" y=\"40.0\" width=\"160.0\" height=\"50.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"610.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">nmap -sn</text><text x=\"610.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sete máquinas respondem</text><rect x=\"530.0\" y=\"120.0\" width=\"160.0\" height=\"50.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"610.0\" y=\"137.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">inventory.py</text><text x=\"610.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o que cada uma roda</text><rect x=\"280.0\" y=\"75.0\" width=\"160.0\" height=\"60.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">drift.py</text><text x=\"360.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">achados, com donos</text><path d=\"M190.0 65.0 L280.0 105.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l18-loop-dh-ah-paper-dim)\"></path><path d=\"M530.0 65.0 L440.0 105.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l18-loop-dh-ah-paper-dim)\"></path><path d=\"M190.0 145.0 L280.0 105.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l18-loop-dh-ah-paper-dim)\"></path><path d=\"M530.0 145.0 L440.0 105.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l18-loop-dh-ah-paper-dim)\"></path><path d=\"M360.0 135.0 L360.0 215.0 L610.0 215.0 L610.0 170.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l18-loop-dh-ah-amber)\"></path><text x=\"485.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">correções mudam as máquinas; meça de novo</text></svg>", "caption": "Um inventário é uma lista conferida contra medição, não uma lista.", "same": ["baseline.json", "drift.py", "hosts.csv", "inventory.py", "nmap -sn"]}
```

## O que esta aula monta

Três arquivos e dois scripts, todos no `admin`: a lista de máquinas do próprio escritório, uma **linha
de base** de como cada tipo de máquina deveria ser, um script que coleta o que cada máquina é de fato e
um script que informa onde a realidade e os registros discordam. Cada script é curto o bastante para ser
lido inteiro, e cada um é o núcleo do que ferramentas comerciais de gestão de ativos e de configuração
fazem.

Suba o laboratório inteiro: esta é a única aula que precisa de todas as máquinas.

```sh
sudo bash hostlab.sh up
```
