---
title: Medindo o que os testes rodaram
version: 1
---

**Cobertura de código** é um registro de quais linhas do programa rodaram enquanto os testes
rodavam. Responde com exatidão a uma pergunta estreita: *que código nenhum teste executou?* Não
responde à pergunta que as pessoas costumam fazer a ela, *os testes são bons?*, e a maior parte desta
aula é sobre a distância entre as duas.

Em Python a ferramenta é o `coverage.py`. Ele roda um programa, aqui o pytest, com um rastreador que
anota cada linha executada, e depois informa por arquivo. A configuração do `shipquote` desde a aula
1 já diz o que medir:

```toml
[tool.coverage.run]
branch = true
source = ["shipquote"]

[tool.coverage.report]
show_missing = true
```

`source` limita o relatório ao pacote do próprio projeto, então testes e bibliotecas não entram na
conta. `branch = true` pede cobertura de ramos além de linhas, o que a seção 03 explica.
`show_missing` lista as linhas que nunca rodaram.

```
ana@laptop:~/shipquote$ coverage run -m pytest -q
........ss.................................                              [100%]
41 passed, 2 skipped in 2.47s
ana@laptop:~/shipquote$ coverage report
Name                    Stmts   Miss Branch BrPart  Cover   Missing
-------------------------------------------------------------------
shipquote/__init__.py       0      0      0      0   100%
shipquote/app.py           54     12      8      3    76%   20-21, 23, 31, 36-38, 60-63, 67
shipquote/carrier.py       27     10      2      0    66%   16-19, 22-29
shipquote/dispatch.py      12      0      4      0   100%
shipquote/mailer.py        14      9      0      0    36%   8-9, 12-18
shipquote/money.py          9      1      2      1    82%   14
shipquote/orders.py         7      0      2      0   100%
shipquote/quote.py         19      0      6      0   100%
shipquote/store.py         19      0      0      0   100%
shipquote/version.py        3      0      0      0   100%
-------------------------------------------------------------------
TOTAL                     164     32     24      4    81%
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 298\" role=\"img\" aria-label=\"Cobertura por arquivo do shipquote no passo 7, como barras de 0 a 100 por cento. quote.py, dispatch.py, orders.py e store.py estão em 100. money.py está em 82, app.py em 76. Duas barras estão destacadas: carrier.py com 66, cujos únicos testes foram pulados, e mailer.py com 36, que todo teste troca por um mock. O total é 81 por cento.\"><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">cobertura por arquivo, passo 7, total 81%</text><text x=\"188\" y=\"59\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">quote.py</text><rect x=\"200\" y=\"50\" width=\"440\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"200\" y=\"50\" width=\"440.0\" height=\"18\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><text x=\"650\" y=\"59\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">100%</text><text x=\"188\" y=\"87\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">dispatch.py</text><rect x=\"200\" y=\"78\" width=\"440\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"200\" y=\"78\" width=\"440.0\" height=\"18\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><text x=\"650\" y=\"87\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">100%</text><text x=\"188\" y=\"115\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">orders.py</text><rect x=\"200\" y=\"106\" width=\"440\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"200\" y=\"106\" width=\"440.0\" height=\"18\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><text x=\"650\" y=\"115\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">100%</text><text x=\"188\" y=\"143\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">store.py</text><rect x=\"200\" y=\"134\" width=\"440\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"200\" y=\"134\" width=\"440.0\" height=\"18\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><text x=\"650\" y=\"143\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">100%</text><text x=\"188\" y=\"171\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">money.py</text><rect x=\"200\" y=\"162\" width=\"440\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"200\" y=\"162\" width=\"360.8\" height=\"18\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><text x=\"650\" y=\"171\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">82%</text><text x=\"188\" y=\"199\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">app.py</text><rect x=\"200\" y=\"190\" width=\"440\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"200\" y=\"190\" width=\"334.4\" height=\"18\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><text x=\"650\" y=\"199\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">76%</text><text x=\"188\" y=\"227\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">carrier.py</text><rect x=\"200\" y=\"218\" width=\"440\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"200\" y=\"218\" width=\"290.4\" height=\"18\" rx=\"2\" fill=\"var(--amber)\"></rect><text x=\"650\" y=\"227\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--amber)\">66%</text><text x=\"188\" y=\"255\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">mailer.py</text><rect x=\"200\" y=\"246\" width=\"440\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"200\" y=\"246\" width=\"158.4\" height=\"18\" rx=\"2\" fill=\"var(--amber)\"></rect><text x=\"650\" y=\"255\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--amber)\">36%</text><text x=\"200\" y=\"284\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">destacado: código cujos únicos testes foram pulados, ou trocado por mock em toda parte</text></svg>", "caption": "O mesmo relatório como desenho. As duas barras curtas não são código descuidado: uma é uma classe cujos testes foram pulados, a outra um mailer que nenhum teste roda de verdade."}
```

## Lendo a tabela

Cada linha é um arquivo. **Stmts** é o número de comandos executáveis, **Miss** quantos nunca
rodaram, **Branch** e **BrPart** os pontos de decisão e quantos foram tomados só em parte, **Cover**
a porcentagem, e **Missing** onde olhar.

O total é **81%**, e sozinho o número diz pouco. As linhas da tabela dizem muito:

- `quote.py`, `dispatch.py`, `orders.py` e `store.py` estão em **100%**: as regras que as aulas 1 a
  3 testaram.
- `carrier.py` está em **66%**, e as linhas que faltam, 16 a 19 e 22 a 29, são o `CarrierClient`
  inteiro. É o teste de contrato da aula 2, **pulado porque `CARRIER_URL` não estava definida**. O
  pulo imprimiu `ss` na linha de progresso; o relatório de cobertura o transforma numa lista de
  linhas que ninguém conferiu.
- `mailer.py` está em **36%**. A aula 2 trocou o mailer por um mock com autospec em todo lugar,
  então o código que de fato fala com um servidor SMTP nunca roda num teste.
- `app.py` está em **76%**. Entre as linhas que faltam estão `/version`, o 404, a resposta de
  "parâmetro ausente", o caminho do 500 e `main()`.
- `money.py` perde uma linha, a 14: o `raise` de `split` com menos de uma parte.

Cada um desses é um fato sobre o qual dá para agir, e nenhum é um julgamento. **Código sem cobertura
é código em que nenhum teste poderia ter pego um defeito.** Código coberto é código que rodou; se
alguém conferiu o que ele fez é outra pergunta, que a seção 04 faz.

## De onde vêm os números

A cobertura instrumenta o interpretador, então tudo o que rodou no processo de teste conta,
inclusive o servidor HTTP, que os testes funcionais sobem numa thread. Código rodado num **processo
separado** não conta, a menos que esse processo também seja medido; uma suíte que suba o servidor com
`subprocess` mostraria `app.py` como intocado, por mais requisições que mandasse. A seção 09 mostra
como medições separadas são juntadas de novo.
