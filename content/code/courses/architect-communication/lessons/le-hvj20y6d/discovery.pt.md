---
title: Descoberta: dos sintomas a um diagnóstico
version: 1
---

**Descoberta é encontrar o que está acontecendo de fato, a partir de três fontes que mentem cada
uma de um jeito: os dados, as pessoas e o próprio sistema.** Um diagnóstico construído sobre uma só
herda o ponto cego dela. Construído sobre as três, os pontos cegos quase sempre se anulam.

## Comece pelos dados, porque eles não têm opinião

A primeira tarde de Lívia foi com o log de deploys e as notas de incidentes de janeiro a abril. Ela
contou antes de formar qualquer opinião:

| | |
|---|---|
| releases da logística, de janeiro a abril | 23 |
| releases seguidos de um incidente no planejamento de rotas em até 24 horas | 7 |
| fração dos releases que causaram um incidente | cerca de 30% |
| mediana do tempo entre o merge e a produção | 9 dias |

Depois, para cada um dos sete incidentes, ela leu as notas e escreveu uma linha sobre o que tinha
quebrado de fato:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Uma contagem dos sete incidentes de rotas por causa. Tabela compartilhada mudada por um serviço e lida pelo outro: 5. Erro de configuração: 1. Capacidade num pico de sexta: 1. Timeout entre os dois serviços: 0.\"><defs><marker id=\"incidentca-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">tabela compartilhada mudada por um serviço e lida pelo outro</text><rect x=\"430\" y=\"22\" width=\"40\" height=\"22\" rx=\"3\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"478\" y=\"22\" width=\"40\" height=\"22\" rx=\"3\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"526\" y=\"22\" width=\"40\" height=\"22\" rx=\"3\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"574\" y=\"22\" width=\"40\" height=\"22\" rx=\"3\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"622\" y=\"22\" width=\"40\" height=\"22\" rx=\"3\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"676\" y=\"33\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">5</text><text x=\"20\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">erro de configuração</text><rect x=\"430\" y=\"66\" width=\"40\" height=\"22\" rx=\"3\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"484\" y=\"77\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text><text x=\"20\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">capacidade num pico de sexta</text><rect x=\"430\" y=\"110\" width=\"40\" height=\"22\" rx=\"3\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"484\" y=\"121\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text><text x=\"20\" y=\"164\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">timeout entre os dois serviços</text><rect x=\"430\" y=\"154\" width=\"40\" height=\"22\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"></rect><text x=\"484\" y=\"165\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">0</text><text x=\"20\" y=\"202\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">os 7 incidentes de rotas depois de versões da logística, de janeiro a abril, pelo que quebrou</text></svg>", "caption": "A linha que importa é a vazia. Um broker resolve timeouts entre serviços, e nenhum dos sete incidentes foi um."}
```

Cinco dos sete tinham a mesma forma: um serviço mudou uma coluna de uma tabela que o planejador de
rotas e o serviço de zonas liam, e o outro serviço quebrou ao ler o formato novo. Um foi um erro de
configuração. Um foi um problema de capacidade num pico de sexta-feira, que é a história da aula 4
de novo.

**Nenhum dos sete foi causado por uma chamada síncrona entre os dois serviços estourando o tempo
limite**, que é o problema que um message broker resolveria. Isso ainda não encerrava a questão. Os
dados mostram o que quebrou; não mostram por que o time não tinha impedido que quebrasse.

## Depois as pessoas, porque os dados não dizem o porquê

Foram quatro entrevistas de trinta minutos, com pessoas escolhidas por Henrique, cada uma aberta
repetindo a linha do contrato: aquilo não era uma avaliação de ninguém. Lívia fez as mesmas
perguntas abertas a todas:

- *O que acontece no dia de um release?*
- *Quando um release quebra alguma coisa, como vocês ficam sabendo?*
- *Se você pudesse mudar uma coisa no jeito como vocês fazem release, o que seria?*

Três das quatro mencionaram a tabela compartilhada sem que ninguém perguntasse. Duas disseram, com
outras palavras, que mudá-la "precisa que o pessoal do serviço de zonas concorde, e eles estão
sempre ocupados", então as mudanças eram feitas em silêncio, torcendo para dar certo. Paulo, o
engenheiro mais experiente, disse que a ideia do broker tinha surgido porque "com um broker cada
serviço teria a sua própria cópia dos dados e ninguém conseguiria quebrar ninguém".

Essa frase era o diagnóstico esperando ser notado. **O broker não era desejado para troca de
mensagens; era desejado como um jeito de parar de compartilhar uma tabela sem ter de negociar quem
era o dono dela.**

## Depois o sistema, para conferir o que as pessoas acreditam

O que as pessoas contam sobre o próprio sistema é em parte folclore. Lívia passou uma hora lendo o
histórico de mudanças do esquema e o código dos dois serviços. Confirmou que a tabela não tinha
dono registrado em lugar nenhum, que os dois serviços escreviam nela e que nenhum teste rodava os
dois serviços juntos antes de um release; eles só eram testados juntos em staging, de madrugada,
depois do merge.

## Hipóteses, sem apego

Na conversa do meio do caminho, em 22 de maio, Lívia tinha três hipóteses, e as apresentou a
Henrique como hipóteses, com o que distinguiria uma da outra:

1. **Os serviços precisam de mensageria assíncrona.** Previria timeouts nos incidentes. *Não
   aparece.*
2. **A tabela compartilhada não tem dono nem contrato**, então as mudanças nela não passam pela
   revisão do outro lado. Previria incidentes depois de mudanças de esquema. *Cinco de sete.*
3. **Os dois serviços só são testados juntos depois do merge**, então a quebra é encontrada tarde.
   Previria incidentes encontrados em staging ou em produção, nunca antes do merge. *Todos os sete.*

As hipóteses 2 e 3 eram verdadeiras e se reforçavam. Foi na conversa do meio do caminho que
Henrique ouviu isso pela primeira vez, uma semana antes da nota escrita, e é por isso que a nota
final não o surpreendeu.
