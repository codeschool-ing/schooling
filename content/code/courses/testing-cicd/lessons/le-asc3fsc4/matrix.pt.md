---
title: A matriz
version: 1
---

Uma **matriz** roda o mesmo job uma vez por combinação de algumas variáveis: versões da linguagem,
sistemas operacionais, bancos de dados, fusos horários. Cada combinação é uma **célula**. A matriz do
laboratório tem dois eixos, três versões do Python e dois fusos, então seis células. O motivo para
pagar seis execuções em vez de uma é que **alguns defeitos só existem em algumas células**, e uma
execução única na configuração de quem escreveu não os vê.

A aula 3 seção 09 apontou o fuso `WAREHOUSE` na linha 11 de `dispatch.py`. Aqui um colega simplifica
essa função, pensando que a loja e o servidor ficam os dois em São Paulo, então não há por que
nomear um fuso:

```
ana@laptop:~/shipquote$ git diff
diff --git a/shipquote/dispatch.py b/shipquote/dispatch.py
index 4c2649f..54c8b89 100644
--- a/shipquote/dispatch.py
+++ b/shipquote/dispatch.py
@@ -1,14 +1,11 @@
 """Which day an order leaves the warehouse."""
 from datetime import date, datetime, time, timedelta
-from zoneinfo import ZoneInfo
-
-WAREHOUSE = ZoneInfo("America/Sao_Paulo")
 CUTOFF = time(14, 0)          # orders after 14:00 leave the next working day
 
 
 def dispatch_date(ordered_at: float) -> date:
     """The day an order placed at this Unix time leaves the warehouse."""
-    local = datetime.fromtimestamp(ordered_at, WAREHOUSE)
+    local = datetime.fromtimestamp(ordered_at)
     day = local.date()
     if local.time() >= CUTOFF:
         day += timedelta(days=1)
ana@laptop:~/shipquote$ python -m pytest -q tests/test_dispatch.py
...                                                                      [100%]
3 passed in 0.14s
ana@laptop:~/shipquote$ git push
remote: ci: run 4, commit 1247039, checked out clean        
remote: ci: 3.11  America/Sao_Paulo  pass  41 passed, 2 skipped in 1.92s        
remote: ci: 3.11  UTC                FAIL  1 failed, 40 passed, 2 skipped in 1.39s        
remote: ci: 3.12  America/Sao_Paulo  pass  41 passed, 2 skipped in 1.89s        
remote: ci: 3.12  UTC                FAIL  1 failed, 40 passed, 2 skipped in 1.39s        
remote: ci: 3.13  America/Sao_Paulo  pass  41 passed, 2 skipped in 1.97s        
remote: ci: 3.13  UTC                FAIL  1 failed, 40 passed, 2 skipped in 1.43s        
remote: ci: run 4 FAILED, logs in /home/ana/ci/runs/4        
To /home/ana/ci/shipquote.git
   6b77129..1247039  main -> main
```

No notebook, os três testes de despacho passam: o relógio do notebook está em São Paulo. Na CI, **as
três células de São Paulo passam e as três de UTC falham**, um teste cada. Sem fuso, o
`datetime.fromtimestamp` lê a hora no fuso em que a máquina estiver configurada. O pedido do teste foi
feito às 13:30 em São Paulo, que são 16:30 em UTC: depois do corte, então uma máquina em UTC o
despacha no dia seguinte.

## Lendo a forma

O desenho de vermelho e verde é um diagnóstico antes de alguém abrir um log. **A falha acompanha o
fuso e ignora a versão do Python**: toda célula UTC falhou, qualquer que fosse o interpretador, e toda
célula de São Paulo passou. Então a causa é algo que depende do fuso, e a atualização de Python que a
equipe planejava não tem culpa.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A execução 4 da CI do laboratório como uma grade de seis células: três versões do Python, 3.11, 3.12 e 3.13, em dois fusos horários. As três células em America/Sao_Paulo passaram com 41 testes aprovados. As três células em UTC falharam, cada uma com um teste reprovado. A falha acompanha o fuso e ignora a versão do Python.\"><text x=\"320.0\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">Python 3.11</text><text x=\"460.0\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">Python 3.12</text><text x=\"600.0\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">Python 3.13</text><text x=\"234\" y=\"90.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">America/Sao_Paulo</text><rect x=\"258\" y=\"66\" width=\"124\" height=\"48\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"320.0\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">passou</text><text x=\"320.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">41 passed</text><rect x=\"398\" y=\"66\" width=\"124\" height=\"48\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"460.0\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">passou</text><text x=\"460.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">41 passed</text><rect x=\"538\" y=\"66\" width=\"124\" height=\"48\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"600.0\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">passou</text><text x=\"600.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">41 passed</text><text x=\"234\" y=\"150.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">UTC</text><rect x=\"258\" y=\"126\" width=\"124\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"320.0\" y=\"143.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">falhou</text><text x=\"320.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1 failed</text><rect x=\"398\" y=\"126\" width=\"124\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"460.0\" y=\"143.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">falhou</text><text x=\"460.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1 failed</text><rect x=\"538\" y=\"126\" width=\"124\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"600.0\" y=\"143.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">falhou</text><text x=\"600.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1 failed</text><path d=\"M250 196 L670 196\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"460.0\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a falha acompanha a linha, não a coluna</text></svg>", "caption": "A execução 4, desenhada como a matriz que ela é. Vermelho numa linha inteira, e o mesmo desenho em toda coluna, dizem que a causa é o fuso horário antes de alguém abrir um log."}
```

Os eixos que uma matriz deveria ter são aqueles **em que a produção pode diferir da máquina de quem
desenvolve**. A maioria dos servidores e quase todo runner de CI hospedado roda em UTC, enquanto uma
equipe no Brasil desenvolve no horário de São Paulo, então este eixo merece o lugar num projeto
brasileiro. Outros comuns:

| eixo | pega |
|---|---|
| versões da linguagem que o projeto suporta | um recurso usado antes de a versão mais antiga tê-lo |
| sistemas operacionais | separadores de caminho, fins de linha, sistemas de arquivos que ignoram maiúsculas |
| versões do banco | SQL aceito por uma e recusado por outra |
| fuso horário e localidade | datas, formatação de números, ordenação de palavras acentuadas |

## O custo de uma célula

Cada eixo multiplica: três Pythons, dois fusos e dois bancos seriam doze células. Equipes mantêm as
matrizes pequenas **testando as bordas de cada eixo** em vez de todo valor, o Python mais antigo e o
mais novo suportados em vez de todas as versões no meio, e excluindo combinações que não acontecem em
produção. A aula 6 escreve esta matriz como uma `strategy.matrix` do GitHub Actions, com `include` e
`exclude` exatamente para isso.
