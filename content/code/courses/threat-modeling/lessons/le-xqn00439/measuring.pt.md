---
title: Medindo se o modelo está vivo
version: 1
---

Um modelo que confere a si mesmo produz números como efeito colateral, e alguns deles dizem se a
prática está funcionando. A tentação é medir o que é fácil de contar. A disciplina é medir o que
mudaria se o modelo morresse.

### Cinco números que valem guardar

Cada um vem de um arquivo do repositório ou do git log dele, então nenhum depende de alguém lembrar
de contar:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l15-measures\" aria-label=\"Cinco medidas do modelo em 12 de outubro de 2026. Ameaças abertas sem requisito e sem decisão: 0, depois do R20 e do R21. Exceções conhecidas no baseline: 3, R14, R17 e R21 sem verificação. Aceites vigentes: 2, RA-001 e RA-003. Aceites atrasados: 0 em 12 de outubro, e 1 em 16 de dezembro. Ameaças achadas fora do modelo: 2, T18 e T19, de um relatório SOC 2.\"><rect x=\"20.0\" y=\"15.0\" width=\"340.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"32.0\" y=\"35.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">ameaças abertas: sem requisito, sem decisão</text><rect x=\"370.0\" y=\"15.0\" width=\"60.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"400.0\" y=\"35.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">0</text><text x=\"442.0\" y=\"35.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">depois do R20 e do R21</text><rect x=\"20.0\" y=\"65.0\" width=\"340.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"32.0\" y=\"85.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">exceções conhecidas no baseline</text><rect x=\"370.0\" y=\"65.0\" width=\"60.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"400.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">3</text><text x=\"442.0\" y=\"85.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">R14, R17, R21 sem verificação</text><rect x=\"20.0\" y=\"115.0\" width=\"340.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"32.0\" y=\"135.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">aceites vigentes</text><rect x=\"370.0\" y=\"115.0\" width=\"60.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"400.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">2</text><text x=\"442.0\" y=\"135.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">RA-001 e RA-003</text><rect x=\"20.0\" y=\"165.0\" width=\"340.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"32.0\" y=\"185.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">aceites atrasados</text><rect x=\"370.0\" y=\"165.0\" width=\"60.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"400.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">0</text><text x=\"442.0\" y=\"185.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">em 12 de outubro; 1 em 16 de dezembro</text><rect x=\"20.0\" y=\"215.0\" width=\"340.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"32.0\" y=\"235.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">ameaças achadas fora do modelo</text><rect x=\"370.0\" y=\"215.0\" width=\"60.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"400.0\" y=\"235.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">2</text><text x=\"442.0\" y=\"235.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">T18, T19, de um relatório SOC 2</text></svg>", "caption": "Todo número aqui vem de um arquivo ou de um git log, e nenhum precisa de alguém lembrar de contar."}
```

- **Ameaças abertas**, sem requisito e sem decisão. É a própria contagem de "novos" da checagem, e o
  valor saudável é zero em todo merge. Uma ameaça pode ficar aberta um dia; uma aberta há um mês
  quer dizer que ninguém tomou uma decisão que era sua de tomar.
- **Exceções conhecidas no baseline**, e se o número está caindo. Três está bom. As mesmas três um ano
  depois quer dizer que a verificação não está acontecendo.
- **Aceites vigentes, e quantos estão atrasados.** A aula 12 chamou essa de uma das medidas mais
  simples que existem. Uma contagem crescente de aceites quer dizer que se está convivendo com riscos
  em vez de tratá-los; atrasados querem dizer que as revisões que justificam essa convivência não
  estão acontecendo.
- **Ameaças achadas fora do modelo.** A T18 e a T19 vieram de um relatório SOC 2; outras virão de
  incidentes, auditorias e testes. Cada uma é uma que o processo do próprio modelo perdeu, e a razão
  entre elas e as que a equipe achou sozinha é o mais perto que existe de uma medida da qualidade do
  modelo.
- **Quanto o modelo fica atrás do sistema.** O tempo entre uma mudança que deveria ter mexido no
  modelo e o commit que mexeu. Com a revisão de projeto no mesmo pull request, ele é zero por
  construção. Sem ela, é o número que cresce primeiro quando um modelo começa a morrer.

O histórico mostra o último direto. Toda mudança nas ameaças, nos requisitos e nas decisões, com a
data:

```
(.venv) ana@vm:~/tm/portal-model$ git log --format="%ad %s" --date=short -- threats.csv requirements.csv decisions
2026-10-12 Write requirements for T18 and T19
2026-10-12 Add the threats the gateway SOC 2 report raised
2026-10-09 Review RA-002 late, and accept T06 again until December
2026-10-01 Record the first decisions
2026-09-17 Write a requirement for each threat
2026-09-14 Add the threats the abuse cases found
2026-09-03 List the threats found with STRIDE
```

Seis semanas é pouco para mostrar tendência, e o honesto a dizer sobre os números da Vereda é que eles
descrevem uma prática que acabou de começar. O motivo de escolhê-los agora é que daqui a um ano o
mesmo comando vai mostrar ou um modelo que mudou sempre que o sistema mudou, ou uma lista que parou em
outubro.

### Números que enganam

Duas medidas populares são piores que nenhuma:

- **O número de ameaças.** Mais ameaças não é um modelo melhor; um modelo do mesmo portal com sessenta
  ameaças genéricas de uma ferramenta, e nenhuma do tipo da T13, pontuaria mais e protegeria menos. A
  aula 3 fez esse argumento sobre os 196 achados do pytm.
- **A porcentagem de ameaças "mitigadas".** Ela recompensa escrever um requisito e parar ali. Um
  requisito que ninguém verifica conta como mitigado, e é por isso que a checagem conta a verificação
  à parte e o baseline mantém os não verificados à vista.

Uma medida que uma equipe consegue melhorar fazendo menos trabalho de verdade vai ser melhorada desse
jeito, sem ninguém decidir trapacear.

### Onde isso deixa o curso

Quinze aulas atrás este repositório era um diretório vazio. Agora ele guarda um diagrama que roda,
19 ameaças com ids e 21 requisitos com a sua verificação. Guarda estimativas em reais com as suas
faixas, um plano ordenado e registros de decisão com donos e datas. E guarda um mapeamento para três
frameworks, um índice de evidências e uma checagem que falha quando qualquer parte disso sai do
passo. Nenhum desses arquivos é o modelo de ameaças sozinho. **O modelo de ameaças é o hábito de
mudá-los sempre que o sistema muda**, e a checagem existe para esse hábito não depender da memória
de ninguém.