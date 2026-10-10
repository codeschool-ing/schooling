---
title: Correspondências aproximadas, para faixas e datas
version: 1
---

**Uma correspondência aproximada não procura a própria chave. Ela procura o último limite que a
chave alcançou.** Isso é errado para um código de produto e exatamente certo para uma faixa, um
nível, uma alíquota ou um preço que mudou numa data: toda tabela que diz "deste valor em diante,
esta resposta".

## Os três tamanhos, como tabela

A aula 3 separou as vendas em três tamanhos com um `SE` aninhado, e os limites, 4 e 10, ficaram
enterrados na fórmula. Ponha-os em células. Em `Sales`, deixe a coluna N vazia e digite esta
tabelinha a partir de **O1**:

| | O | P |
|---|---|---|
| 1 | `From` | `Band` |
| 2 | 1 | `Small` |
| 3 | 4 | `Medium` |
| 4 | 10 | `Large` |

Cada linha diz onde uma faixa **começa**. Digite `Band` em **M1**, e em **M2**:

```localised
=PROCX(E2;$O$2:$O$4;$P$2:$P$4;;-1)
```

Os dois pontos e vírgulas seguidos deixam de fora o quarto argumento, a mensagem para chave ausente,
e o quinto, `-1`, pede **correspondência exata ou a próxima chave menor**. A S1001 tem 14 sacos: não
há 14 em O2:O4, a próxima chave menor é 10, e M2 mostra `Large`. Uma venda de 6 sacos cai em 4,
`Medium`; uma de 1 cai em 1, `Small`. Preencha para baixo e conte: 22 `Large`, 41 `Medium` e 45
`Small`, exatamente o que o `SE` da aula 3 deu.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l04-approx\" aria-label=\"A tabela de faixas com as chaves 1, 4 e 10 e as faixas Small, Medium e Large, e uma reta de quantidades de sacos de 1 a 20 com as três chaves marcadas. Três vendas são postas na reta: 14 sacos anda para a esquerda até a chave 10 e é Large, 6 sacos anda até 4 e é Medium, 1 saco está sobre a chave 1 e é Small.\"><text x=\"68.0\" y=\"41.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">O</text><text x=\"133.0\" y=\"41.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">P</text><text x=\"32.0\" y=\"61.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><rect x=\"40.0\" y=\"50.0\" width=\"56.0\" height=\"22.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"90.0\" y=\"61.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">From</text><rect x=\"96.0\" y=\"50.0\" width=\"74.0\" height=\"22.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"102.0\" y=\"61.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Band</text><text x=\"32.0\" y=\"83.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2</text><rect x=\"40.0\" y=\"72.0\" width=\"56.0\" height=\"22.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"90.0\" y=\"83.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><rect x=\"96.0\" y=\"72.0\" width=\"74.0\" height=\"22.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"102.0\" y=\"83.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Small</text><text x=\"32.0\" y=\"105.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3</text><rect x=\"40.0\" y=\"94.0\" width=\"56.0\" height=\"22.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"90.0\" y=\"105.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">4</text><rect x=\"96.0\" y=\"94.0\" width=\"74.0\" height=\"22.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"102.0\" y=\"105.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">Medium</text><text x=\"32.0\" y=\"127.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4</text><rect x=\"40.0\" y=\"116.0\" width=\"56.0\" height=\"22.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"90.0\" y=\"127.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">10</text><rect x=\"96.0\" y=\"116.0\" width=\"74.0\" height=\"22.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"102.0\" y=\"127.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">Large</text><path d=\"M240.0 60.0 L680.0 60.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M240.0 56.0 L240.0 64.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M263.2 56.0 L263.2 64.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M286.3 56.0 L286.3 64.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M309.5 56.0 L309.5 64.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M332.6 56.0 L332.6 64.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M355.8 56.0 L355.8 64.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M378.9 56.0 L378.9 64.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M402.1 56.0 L402.1 64.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M425.3 56.0 L425.3 64.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M448.4 56.0 L448.4 64.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M471.6 56.0 L471.6 64.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M494.7 56.0 L494.7 64.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M517.9 56.0 L517.9 64.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M541.1 56.0 L541.1 64.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M564.2 56.0 L564.2 64.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M587.4 56.0 L587.4 64.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M610.5 56.0 L610.5 64.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M633.7 56.0 L633.7 64.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M656.8 56.0 L656.8 64.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M680.0 56.0 L680.0 64.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M240.0 48.0 L240.0 72.0\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"240.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">1</text><path d=\"M309.5 48.0 L309.5 72.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"309.5\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">4</text><path d=\"M448.4 48.0 L448.4 72.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"448.4\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">10</text><text x=\"680.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">20</text><circle cx=\"541.1\" cy=\"108.0\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"551.1\" y=\"108.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">E = 14</text><path d=\"M533.1 108.0 L450.4 108.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M450.4 108.0 L458.4 112.0 L458.4 104.0 Z\" fill=\"var(--amber)\" stroke=\"none\"></path><text x=\"440.4\" y=\"108.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">Large</text><circle cx=\"355.8\" cy=\"144.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"365.8\" y=\"144.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">E = 6</text><path d=\"M347.8 144.0 L311.5 144.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M311.5 144.0 L319.5 148.0 L319.5 140.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\"></path><text x=\"301.5\" y=\"144.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">Medium</text><circle cx=\"240.0\" cy=\"180.0\" r=\"5\" fill=\"var(--paper)\"></circle><text x=\"250.0\" y=\"180.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">E = 1</text><text x=\"232.0\" y=\"180.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Small</text><text x=\"240.0\" y=\"222.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a maior chave que não passa do valor</text></svg>", "caption": "Uma correspondência aproximada volta do valor até o último limite que ele alcançou. 14 sacos passaram de 10, então é Large; 6 passou de 4, mas não de 10."}
```

Os limites agora moram onde qualquer pessoa os vê. Se a Café Serra decidir que `Large` começa em 12
sacos, uma célula muda e toda linha acompanha, o que nenhum `SE` aninhado jamais ofereceu.

## A mesma coisa nas funções mais antigas

O `PROCV` com `VERDADEIRO` e o `CORRESP` com 1 fazem o mesmo trabalho:

```localised
=PROCV(E2;$O$2:$P$4;2;VERDADEIRO)
```

dá os mesmos 22, 41 e 45. Os dois **exigem a primeira coluna em ordem crescente**, porque procuram
dividindo o intervalo ao meio em vez de ler linha por linha, e numa tabela fora de ordem dão
respostas erradas sem erro nenhum. O `PROCX` com `-1` lê as chaves em sequência e não precisa da
ordem, embora manter uma tabela de faixas ordenada continue sendo o jeito de deixá-la legível.

Dois detalhes mantêm uma tabela de faixas honesta. A primeira linha precisa começar no menor valor
possível, aqui 1, ou uma venda abaixo dele não acha nada e mostra `#N/D`. E as chaves são onde as
faixas **começam**, então o 10 pertence a `Large`; uma tabela de onde as faixas terminam poria cada
fronteira uma faixa fora do lugar.

## Um preço que mudou numa data

Datas são números, então a mesma busca acha "o preço em vigor naquele dia". O preço de tabela do
`CER1K` foi R$ 115 até o fim de 2025 e R$ 118 a partir de 1º de janeiro de 2026. Como tabela, em
**O6**:

| | O | P |
|---|---|---|
| 6 | `From` | `CER1K` |
| 7 | 2025-01-01 | 115 |
| 8 | 2026-01-01 | 118 |

Depois, para a venda S1003, na linha 4, uma venda online de `CER1K` em 13 de janeiro de 2025:

```localised
=PROCX(B4;$O$7:$O$8;$P$7:$P$8;;-1)
```

responde **115**, o preço de tabela do dia, que é o que a S1003 pagou. Na linha 85, a S1084, vendida
online em 25 de fevereiro de 2026, a mesma fórmula responde **118**, e foi isso que a S1084 pagou
também. As vendas online pagam o preço de tabela do seu dia, e é assim que se confere. Uma tabela
para os seis produtos poria uma coluna por produto ao lado das datas, e a busca precisaria então de
uma linha e de uma coluna: o padrão dos dois `CORRESP` da seção 05, com a linha achada por
`CORRESP(B4;$O$7:$O$8;1)`, o tipo aproximado.
