---
title: Uma ficha do prompt
version: 2
---

Os registros de decisão e o registro de falhas são para quem muda o prompt. A terceira nota é para
quem o usa: uma equipe que quer apontá-lo para outra caixa de entrada, a pessoa de plantão quando o
roteamento dá errado, um gestor perguntando quanto custa. **Essas pessoas precisam de uma página, e
precisam que ela diga quão bom o prompt é em números, incluindo os números que não lisonjeiam.**

A ideia tem um precedente publicado. *Model Cards for Model Reporting* (Mitchell e outros, 2019)
propôs um documento curto para acompanhar todo modelo treinado: para que serve, para que não deve
ser usado, como foi avaliado e com que dados, e as limitações conhecidas. Um prompt não é um modelo
treinado, mas é um componente sobre o qual outras pessoas vão construir sem ler o que tem dentro, que
é exatamente a situação para a qual um model card foi escrito.

## Os números da ficha

Todo número de uma ficha vem de um comando, rodado na versão que a ficha descreve:

```
ana@lab:~/triage$ for s in dev holdout attacks pasted; do pl run prompts/triage.txt cases/$s.jsonl --out runs/$s.jsonl > /dev/null; printf "%-8s" $s; pl check runs/$s.jsonl | tail -n 1; done
dev     all          24    16
holdout all          15    15
attacks all           3     7
pasted  all           2     4
ana@lab:~/triage$ pl check runs/dev.jsonl --failures
check      pass  fail
json         38     2
fields       38     2
labels       38     2
category     35     5
urgency      24    16
all          24    16

t02    urgency   high, expected normal
t04    urgency   normal, expected high
t07    urgency   low, expected normal
t09    urgency   high, expected normal
t12    urgency   normal, expected high
t23    urgency   normal, expected high
t24    urgency   high, expected normal
t25    category  other, expected account
t26    category  account, expected billing
t28    urgency   normal, expected low
t32    urgency   high, expected normal
t33    category  delivery, expected returns
t36    urgency   low, expected high
t37    json      not a JSON object
t38    json      not a JSON object
t39    urgency   low, expected normal
ana@lab:~/triage$ python3 stats.py runs/dev.jsonl
runs/dev.jsonl, 40 calls
  tokens in    mean  306.1   total  12246
  tokens out   mean   29.1   total   1162   max 36
  seconds      p50   4.0   p95   4.6   total  161.3
```

O laço roda o prompt sobre cada conjunto de teste e guarda a última linha de cada verificação:
aprovadas, depois falhas. As falhas no dev são os modos de falha conhecidos, uma mensagem de cada
vez. O `stats.py`, da aula 2, dá os tokens e os segundos de uma chamada; a aula 16 transforma tokens
em dinheiro.

## A ficha

| | `prompts/triage.txt` |
|---|---|
| propósito | Classificar cada mensagem da caixa de suporte da Folio numa categoria, uma urgência e um resumo de uma frase, em JSON para o programa de roteamento |
| não serve para | Responder a clientes, ou mensagens em qualquer língua que não seja inglês: nenhum conjunto de teste as tem |
| dona | Ana Lima |
| versão | id `c1916fcd`, commit `85dfa4e` |
| modelo e parâmetros | `llama3.2:3b` (`a80c4f17acd5`) no Ollama 0.40.0, temperatura 0, semente 1, `num_predict` 400: os padrões do harness, nenhum escrito no arquivo ainda, o que a aula 14 manda corrigir |
| notas | dev 24/40, holdout 15/30, ataques 3/10, coladas 2/6 |
| falhas conhecidas | urgência, nas duas direções: onze das dezesseis falhas do dev, dez delas a um passo; duas respostas cortadas num apóstrofo (F-0001); `t25`, `t26` e `t33` na categoria errada |
| custo | 306,1 tokens de entrada e 29,1 de saída por chamada; 4,0 s de mediana e 4,6 s no p95 em quatro núcleos de processador |
| decisões e falhas | 0001 os exemplos continuam em JSON; F-0001 apóstrofos |

**A linha mais importante é a nota dos ataques.** Vinte e quatro de quarenta parece um prompt com
trabalho pela frente; três de dez em mensagens escritas para conduzi-lo diz que qualquer coisa que
aja a partir dos rótulos dele precisa de uma pessoa, ou do privilégio mínimo da aula 10, por trás.
Uma ficha que imprimisse só a nota do dev seria verdadeira e enganaria todo mundo que a lesse. A
linha *não serve para* faz o mesmo trabalho em palavras: diz onde termina o que foi testado, para
ninguém descobrir isso em produção.
