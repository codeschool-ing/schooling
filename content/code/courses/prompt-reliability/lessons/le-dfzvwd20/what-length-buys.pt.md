---
title: O que um prompt mais longo compra
version: 1
---

Um prompt cresce como cresce um regulamento. Alguém vê uma resposta ruim e acrescenta uma linha,
outra pessoa acrescenta a mesma linha em maiúsculas, e ninguém apaga nada, porque apagar parece
mais arriscado do que acrescentar. **A ideia por baixo disso é que um prompt mais longo é um prompt
mais cuidadoso.** Ele é só mais longo, e o tamanho tem um preço que se paga em cada chamada.

Este é o prompt de triagem depois de algumas semanas desse tipo de cuidado:

```
ana@lab:~/triage$ cat -n prompts/v2-long.txt
     1	You are a helpful, friendly and professional assistant for Folio, an online bookshop.
     2	Your job is to read customer messages and sort them so the support team can answer them.
     3	
     4	Keep the summary brief so the team can scan the queue quickly.
     5	
     6	Answer in JSON with three fields:
     7	- "category": one of billing, delivery, returns, account, other
     8	- "urgency": one of low, normal, high
     9	- "summary": what the customer needs
    10	
    11	IMPORTANT: Do not make up information that is not in the message.
    12	Do not add fields that are not listed above.
    13	Never include the customer's name or email in the summary.
    14	IMPORTANT: Do not make up information that is not in the message.
    15	
    16	The team reads the summary instead of the message, so describe the problem in full detail.
    17	
    18	Message: {{message}}
ana@lab:~/triage$ pl tokens prompts/v2-json.txt
69 tokens, 46 words, 295 characters
ana@lab:~/triage$ pl tokens prompts/v2-long.txt
167 tokens, 131 words, 764 characters
```

`v2-json.txt` é o prompt que a aula 1 rodou quando pediu JSON pela primeira vez: 69 tokens. O
longo pede os mesmos três campos com as mesmas duas listas e ocupa 167. Os outros 98 tokens são
uma persona, três regras sobre o que não fazer, uma delas escrita duas vezes, e duas instruções
sobre o resumo que discordam entre si. A próxima seção trata dessas duas.

## Pago em cada chamada

O prompt vai inteiro com cada mensagem. **O que as instruções custam, você paga quarenta vezes por
quarenta mensagens e um milhão de vezes por um milhão.** Os preços do laboratório estão num
arquivo, e o `pl cost` soma o que uma execução gastou:

```
ana@lab:~/triage$ cat prices.json
{
  "model": "standin-1",
  "note": "cents per million tokens; written by the course, not any provider's price list",
  "input": 300,
  "cache_read": 30,
  "cache_write": 375,
  "output": 1500
}
ana@lab:~/triage$ pl run prompts/v2-json.txt cases/dev.jsonl --out runs/v2.jsonl
40 calls, prompt 9c365e2d, written to runs/v2.jsonl
ana@lab:~/triage$ pl run prompts/v2-long.txt cases/dev.jsonl --out runs/long.jsonl
40 calls, prompt 2b255df5, written to runs/long.jsonl
ana@lab:~/triage$ pl cost runs/v2.jsonl
tokens          count   per call
input            3139       78.5
cache_read          0        0.0
cache_write         0        0.0
output           1595       39.9

cost of these 40 calls: 3.3342 cents
cost of a million calls like them: 83,355 cents
ana@lab:~/triage$ pl cost runs/long.jsonl
tokens          count   per call
input            7059      176.5
cache_read          0        0.0
cache_write         0        0.0
output           1709       42.7

cost of these 40 calls: 4.6812 cents
cost of a million calls like them: 117,030 cents
```

A entrada por chamada foi de 78,5 tokens para 176,5. A diferença são os 98 tokens de instruções a
mais, iguais em toda mensagem, diga ela o que disser. A saída mudou bem menos, de 39,9 para 42,7.
Aos preços do curso, um milhão de chamadas custa 83.355 centavos com o prompt curto e 117.030 com
o longo, **cerca de 40% a mais por respostas que não são melhores**, como a última seção desta aula
mede.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Tokens por chamada, na média das quarenta mensagens. O prompt curto: 69 de instruções, 9,5 de mensagem, 39,9 escritos. O prompt longo: 167 de instruções, 9,5 de mensagem, 42,7 escritos.\"><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Tokens por chamada, média de 40</text><text x=\"118\" y=\"64\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">v2-json.txt</text><rect x=\"130\" y=\"50\" width=\"144.9\" height=\"28\" rx=\"2\" fill=\"var(--wire)\"></rect><rect x=\"274.9\" y=\"50\" width=\"19.9\" height=\"28\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"294.8\" y=\"50\" width=\"83.8\" height=\"28\" rx=\"2\" fill=\"var(--amber)\"></rect><text x=\"388.6\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">118.4</text><text x=\"118\" y=\"116\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">v2-long.txt</text><rect x=\"130\" y=\"102\" width=\"350.7\" height=\"28\" rx=\"2\" fill=\"var(--wire)\"></rect><rect x=\"480.7\" y=\"102\" width=\"19.9\" height=\"28\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"500.6\" y=\"102\" width=\"89.7\" height=\"28\" rx=\"2\" fill=\"var(--amber)\"></rect><text x=\"600.3\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">219.2</text><rect x=\"130\" y=\"166\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--wire)\"></rect><text x=\"148\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">instruções</text><rect x=\"300\" y=\"166\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><text x=\"318\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a mensagem</text><rect x=\"470\" y=\"166\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--amber)\"></rect><text x=\"488\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a resposta</text></svg>", "caption": "A mensagem tem o mesmo tamanho nos dois prompts e a resposta cresce menos de três tokens. Quase toda a diferença são instruções, pagas de novo em cada chamada."}
```

Os preços são do curso, e o arquivo diz isso. O formato é o de costume: as tabelas de preço
publicadas pela Anthropic e pela OpenAI cobram mais por um token que o modelo escreve do que por um
que ele lê. Nesta execução isso não salva o prompt longo, porque ele acrescenta 3.920 tokens de
entrada nas quarenta chamadas e só 114 de saída. A aula 16 faz essa conta para um pipeline inteiro,
e a aula 17 mostra como um cache barateia a parte fixa de um prompt. **Nenhum dos dois faz valer a
pena mandar uma instrução inútil.**

## O que um leitor faz com o tamanho

O modelo não é o único leitor. Quem abrir o `v2-long.txt` no mês que vem para resolver uma
reclamação tem dezoito linhas para manter na cabeça, e precisa descobrir quais ainda importam. A
linha 14 repete a linha 11 palavra por palavra. As linhas 11 e 14 estão em maiúsculas, o que diz a
essa pessoa que elas importam mais do que a linha 13, e ninguém decidiu isso. **Cada linha de um
prompt é uma afirmação de que ela muda uma resposta**, e o leitor não tem como saber quais
afirmações são verdadeiras a não ser testando.
