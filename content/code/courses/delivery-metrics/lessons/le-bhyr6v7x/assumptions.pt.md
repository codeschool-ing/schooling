---
title: Mude a janela e veja a previsão se mover
version: 1
---

Toda previsão de Monte Carlo se apoia numa aposta: **os dias de onde ela aprende se parecem com os dias que virão**. Os programas recebem a janela como duas datas opcionais, então você pode testar a aposta diretamente. Aqui está o mesmo par de perguntas, aprendido de junho e julho, sob as regras antigas, em vez do fim de agosto e de setembro.

```
ana@laptop:~/delivery$ python3 howmany.py 31 2026-06-01 2026-07-31
learning from 61 days, 52 items; 10000 runs of 31 days
    8-11                                  0.1%
   12-15  #                               1.5%
   16-19  ########                        7.6%
   20-23  #####################          21.1%
   24-27  #############################  29.3%
   28-31  ########################       23.5%
   32-35  ############                   12.2%
   36-39  ####                            3.7%
   40-43  #                               0.9%
   44-47                                  0.1%
   48-51                                  0.0%
50% of runs finished at least 26 items
70% of runs finished at least 23 items
85% of runs finished at least 21 items
95% of runs finished at least 18 items
ana@laptop:~/delivery$ python3 when.py 30 2026-06-01 2026-07-31
30 items from 2026-10-01; 10000 runs
50% of runs finished by Wed 04 Nov
70% of runs finished by Sun 08 Nov
85% of runs finished by Thu 12 Nov
95% of runs finished by Mon 16 Nov
```

A previsão de 85% para outubro cai de 29 itens para **21**, e a data para trinta itens passa do fim de outubro para **12 de novembro**, quase duas semanas depois. Mesmo time, mesmas pessoas, mesmo programa. A única diferença é em qual histórico ele acreditou.

## Escolhendo a janela

Nenhuma das janelas está errada em si; a questão é qual delas descreve o time que vai fazer o trabalho. Desde 3 de agosto o time de Billing trabalha sob regras diferentes, e junho e julho descrevem um time que não existe mais. A aula 1 fez a mesma observação sobre médias, e ela vale com mais força aqui, porque uma previsão é uma promessa em cima da qual alguém vai planejar.

Três regras para a janela:

- **Uma política só.** Nunca atravesse uma mudança de regras, e deixe de fora as semanas logo depois de uma, enquanto o sistema antigo escoa.
- **Longa o bastante para incluir dias ruins.** Trinta a sessenta dias é comum. Duas semanas boas dão uma previsão otimista.
- **Recente.** Se o time, o produto ou o tipo de trabalho mudou, o histórico venceu, qualquer que seja o tamanho dele.

## Quando as outras suposições falham

**Os dias não são independentes** quando os dias ruins se agrupam: uma semana de incidentes, um período de feriados, uma correria de release. A simulação então subestima quão ruim uma sequência de dias pode ser. Se o seu histórico tem agrupamentos visíveis, amplie a confiança que você cita, ou preveja com o percentil 95 em vez do 85.

**Os itens não são comparáveis** quando o trabalho à frente é de outro tipo que o trabalho para trás: a primeira integração com um parceiro novo, uma migração. O conselho da aula 9 vale: não há histórico para trabalho genuinamente novo, e uma classe de referência ou uma estimativa tem de preencher a lacuna.

**O escopo não é fixo**, nunca. A aula 11 o acrescenta.

## Preveja de novo, toda semana

Uma previsão não se faz uma vez só. Cada semana traz histórico novo e menos itens restantes, e rodar de novo os dois comandos leva segundos. **Uma previsão atualizada toda semana deriva em direção à verdade**, e a própria deriva é informação: se a data de 85% continua escorregando para depois, algo no sistema mudou, e o time sabe disso semanas antes de um prazo ser perdido, e não no próprio dia.
