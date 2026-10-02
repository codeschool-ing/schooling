---
title: Uma ficha do prompt
version: 1
---

Os registros de decisão e o registro de falhas são para quem vai mudar o prompt. A terceira nota é
para quem vai usá-lo: um time que quer apontá-lo para outra caixa de entrada, a pessoa de plantão
quando o roteamento dá errado, uma gerente perguntando quanto custa. **Essas pessoas precisam de uma
página, e ela precisa dizer quão bom é o prompt em números, inclusive os números que não o
favorecem.**

A ideia tem um precedente publicado. *Model Cards for Model Reporting* (Mitchell e outros, 2019)
propôs um documento curto para acompanhar todo modelo treinado: para que serve, para que não deve
ser usado, como foi avaliado e com quais dados, e as limitações conhecidas. Um prompt não é um modelo
treinado, mas é um componente sobre o qual outras pessoas vão construir sem ler o que tem dentro, que
é exatamente a situação para a qual o model card foi escrito.

## Os números da ficha

Todo número de uma ficha vem de um comando, rodado na versão que a ficha descreve:

```
ana@lab:~/triage$ for s in dev holdout attacks pasted; do pl run prompts/triage.txt cases/$s.jsonl --out runs/$s.jsonl > /dev/null; printf "%-8s" $s; pl check runs/$s.jsonl | tail -n 1; done
dev     all          36     4
holdout all          11    19
attacks all           6     4
pasted  all           4     2
ana@lab:~/triage$ pl check runs/dev.jsonl --failures | tail -n 4
t14    urgency   normal, expected low
t24    urgency   low, expected normal
t28    urgency   normal, expected low
t37    category  billing, expected delivery
ana@lab:~/triage$ pl cost runs/dev.jsonl
tokens          count   per call
input           11859      296.5
cache_read          0        0.0
cache_write         0        0.0
output           1497       37.4

cost of these 40 calls: 5.8032 cents
cost of a million calls like them: 145,080 cents
```

O laço roda o prompt sobre cada conjunto de teste e guarda a última linha de cada verificação:
aprovações, depois falhas. As falhas em dev são os modos de falha conhecidos, uma mensagem de cada
vez. O `pl cost` transforma os tokens em dinheiro usando o `prices.json` do curso; a aula 16 explica
como, e para a ficha só importam os números por chamada e a última linha.

## A ficha

| | `prompts/triage.txt` |
|---|---|
| para que serve | Classificar cada mensagem da caixa de atendimento da Folio numa categoria, uma urgência e um resumo de uma frase, em JSON para o programa de roteamento |
| para que não serve | Responder a clientes, ou mensagens em qualquer língua que não o inglês: nenhum conjunto de teste tem essas mensagens |
| responsável | Ana Lima |
| versão | id `c1916fcd`, commit `03e1151` |
| modelo e parâmetros | o substituto do laboratório com temperatura 0 e `max_tokens` 400, os padrões da bancada; nenhum dos dois está escrito no arquivo ainda, o que a aula 14 manda corrigir |
| notas | dev 36/40, holdout 11/30, attacks 6/10, pasted 4/6 |
| falhas conhecidas | urgência na fronteira entre low e normal (`t14`, `t24`, `t28`); um pedido atrasado puxado para billing pelo primeiro exemplo (`t37`); bem mais fraco nas mensagens difíceis de holdout |
| custo | 296,5 tokens de entrada e 37,4 de saída por chamada; 145.080 centavos por milhão de chamadas com o `prices.json` |
| decisões e falhas | 0001 exemplos em JSON; F-0001 os exemplos em linhas simples |

**A linha mais importante é a nota de holdout.** Trinta e seis de quarenta em dev parece um prompt
pronto, e onze de trinta em mensagens mais difíceis diz que não é. Uma ficha que mostrasse só a nota
de dev seria verdadeira e enganaria todo mundo que a lesse. A linha *para que não serve* faz o mesmo
trabalho em palavras: diz onde termina o que foi testado, para que ninguém descubra isso em produção.

## Mantendo a ficha verdadeira

Uma ficha é uma afirmação sobre uma versão. Quando o prompt muda e a ficha não, ela descreve um
prompt que não existe mais, e nada nela parece velho. Dois hábitos evitam isso.

- **Produza os números com os mesmos comandos que a barreira roda**, e atualize a ficha na mesma
  mudança que altera o prompt. A barreira já calculou os números; copiá-los é um minuto de trabalho.
- **Ponha a versão na ficha**, o id do prompt e o commit. Quem comparar com a saída do `pl run` sabe
  na hora se a ficha é sobre o arquivo que tem na frente.
