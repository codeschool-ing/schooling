---
title: Onde a isca vai, e onde ela nunca vai
version: 1
---

**A isca funciona onde um invasor passa, e em nenhum outro lugar.** Um honeypot num canto da rede que
ninguém explora nunca dispara, e um que dispara o dia todo porque fica num caminho movimentado ensina o
escritório a ignorá-lo. A pergunta para cada peça é a mesma: depois que a primeira máquina cai, onde
alguém olha em seguida?

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l13-placement\" aria-label=\"Onde fica a isca numa rede como a da Jatobá. A internet está fora do firewall do escritório e não tem isca. Dentro, entre os servidores ao lado do web, um servidor-isca. Entre as estações ao lado do desk, portas-isca numa máquina ociosa. Dentro do próprio web, um honeytoken num diretório de backup. As setas mostram o caminho de um invasor: de uma estação para os servidores, e para dentro dos arquivos do servidor que ele alcança.\"><defs><marker id=\"l13-placement-dh-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"40.0\" width=\"120.0\" height=\"180.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"80.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">internet</text><text x=\"80.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nada de isca</text><path d=\"M150.0 40.0 L150.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"158.0\" y=\"230.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">firewall</text><rect x=\"180.0\" y=\"40.0\" width=\"230.0\" height=\"180.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"195.0\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">estações</text><rect x=\"200.0\" y=\"80.0\" width=\"90.0\" height=\"36.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"245.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">desk</text><rect x=\"300.0\" y=\"150.0\" width=\"95.0\" height=\"44.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"347.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">máquina ociosa,</text><text x=\"347.0\" y=\"181.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">portas-isca</text><rect x=\"450.0\" y=\"40.0\" width=\"250.0\" height=\"180.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"465.0\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">servidores</text><rect x=\"470.0\" y=\"80.0\" width=\"100.0\" height=\"60.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"520.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">web</text><rect x=\"480.0\" y=\"108.0\" width=\"80.0\" height=\"24.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"520.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--amber)\">honeytoken</text><rect x=\"590.0\" y=\"80.0\" width=\"95.0\" height=\"60.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"637.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">servidor-isca</text><text x=\"637.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">trap</text><path d=\"M290.0 98.0 L470.0 98.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l13-placement-dh-ah-paper-dim)\"></path><text x=\"352.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">o invasor olha em volta</text><path d=\"M570.0 120.0 L590.0 120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l13-placement-dh-ah-paper-dim)\"></path></svg>", "caption": "A isca fica no caminho da primeira máquina para a seguinte, e dentro do que se alcança.", "same": ["firewall", "honeytoken", "internet"]}
```

Numa rede como a da Jatobá isso dá três lugares:

- **Entre os servidores.** Uma máquina como o `trap`, com nome e cara iguais aos das outras, ao lado do
  `web` e do banco de dados. Alguém no `web` que lista a rede vê mais um servidor que vale tentar.
- **Entre as estações.** Portas-isca numa estação ociosa, ou um compartilhamento que parece ser do
  financeiro. A maioria das intrusões começa numa estação e se espalha a partir dali.
- **Dentro das próprias máquinas.** Honeytokens onde estariam os segredos de verdade: um arquivo de
  credenciais num diretório de backup, uma chave num diretório home, uma senha num script. Esses
  disparam depois da isca de rede, quando alguém já está dentro.

## Onde ela nunca vai

**Um honeypot nunca é exposto à internet por um escritório que quer detectar intrusões.** Na internet
ele seria varrido e tocado milhares de vezes por dia por ferramentas automáticas, o que não diz nada ao
escritório sobre a própria rede e enche o canal de alertas de ruído. Honeypots de pesquisa na internet
existem, rodados por pessoas cujo trabalho é estudar esse ruído, em redes mantidas bem longe de
qualquer coisa que protejam.

**E a isca nunca enfraquece o que está ao lado dela.** Um honeypot que oferecesse um login de verdade
com senha fraca seria uma porta de entrada com um alarme, o que continua sendo uma porta de entrada.
Esse é o principal motivo para preferir baixa interação: o `bait.py` aceita uma conexão e a fecha, e
não há nada atrás dele para invadir. O arquivo-isca guarda credenciais de uma conta que não existe,
nunca de uma real desabilitada para a ocasião. Uma máquina-honeypot recebe o mesmo endurecimento que
todas as outras, a aula 1 inclusive, e fica ela mesma isolada pelas regras de firewall da aula 10, para
que mesmo um ataque bem-sucedido a ela não leve a lugar nenhum.

## Quem lê o alerta

Isca que dispara num log que ninguém lê é decoração. Cada alerta de honeypot vai para onde os outros
alertas do escritório vão, com uma diferença: **ele nunca é agrupado nem resumido.** Um alerta de
honeypot é raro por definição, então o que chega merece uma pessoa em minutos, e não uma linha num
relatório semanal.
