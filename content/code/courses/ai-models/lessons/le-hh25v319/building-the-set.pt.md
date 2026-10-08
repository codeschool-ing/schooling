---
title: Montando o conjunto
version: 1
---

Os casos são a avaliação. Um harness se reescreve numa tarde; um conjunto de casos que represente o
trabalho é o que exige reflexão, e é onde a maioria das avaliações dá errado sem ninguém perceber.

## De onde vêm os casos

Do próprio trabalho. A ana tirou quarenta e-mails da caixa de entrada da loja, removeu nomes,
endereços e qualquer coisa que identificasse um cliente, e manteve a redação, com erros de digitação
e tudo. Exemplos inventados são mais limpos que os reais, e é exatamente isso que há de errado com
eles: um modelo testado em e-mails arrumados é testado numa loja que não existe.

Depois ela conferiu a distribuição:

```
ana@desk:~/desk$ python -c "import json, collections; print(collections.Counter(json.loads(l)['label'] for l in open('cases/triage.jsonl')))"
Counter({'order-status': 9, 'refund': 8, 'address-change': 8, 'product-question': 8, 'other': 7})
```

Oito ou nove de cada rótulo, com `other` um pouco abaixo. O tráfego real raramente é tão uniforme, e
há uma escolha a fazer: **espelhar o tráfego**, para a nota geral prever o que a caixa de entrada
vai ver, ou **equilibrar os rótulos**, para a nota de um rótulo raro não depender de dois casos. A
ana equilibrou, e a seção 06 relata o resultado por modelo, sem dizer que ele prevê a caixa de
entrada. A segunda coisa que ela conferiu foram os casos sem pedido, que a tarefa de extração
precisa responder com `null`:

```
ana@desk:~/desk$ grep -c "\"order\": null" cases/triage.jsonl
15
```

Quinze de quarenta. Um conjunto de extração em que todo e-mail cita um pedido nunca testaria a
resposta "não há nenhum", e é ela que um modelo descuidado erra.

## Os casos que mais ensinam

**Casos de fronteira** valem mais que os fáceis, porque os fáceis todo candidato acerta e não
separam nenhum. A ana manteve os e-mails em que ela mesma hesitou. Dois deles:

```
ana@desk:~/desk$ grep -E "\"c(24|26)\"" cases/triage.jsonl
{"id": "c24", "text": "I'm a teacher and would like to order thirty copies. Do you give discounts to schools?", "label": "other", "order": null}
{"id": "c26", "text": "I ordered the hardback but you sent the paperback (LB-20431). I'll keep it if you refund the difference.", "label": "refund", "order": "LB-20431"}
```

Uma professora perguntando se escolas têm desconto em trinta exemplares está perguntando sobre um
produto, ou pedindo alguém que possa negociar? Um pedido de reembolso da diferença entre duas
edições é um reembolso, ou uma reclamação sobre a edição? **Uma pessoa decidiu os dois**, e a
decisão é tanto política da loja quanto um fato sobre o e-mail. A seção 07 mostra o que acontece com
eles.

## Rótulos precisam de uma segunda pessoa

Um rótulo é um julgamento, e o julgamento de uma pessoa só deriva. A verificação é barata: uma
segunda pessoa rotula os mesmos casos sem ver os rótulos da primeira, e toda discordância é
discutida e resolvida antes de qualquer modelo rodar. Onde duas pessoas não chegam a um acordo,
**nenhum modelo pode ser pontuado com justiça naquele caso**, e ele é reescrito, resolvido por uma
regra escrita, ou removido.

## Quantos

Quarenta bastam para separar um modelo ruim de um bom e são poucos para separar dois bons, o que a
seção 06 mede em vez de afirmar. Comece com o que uma pessoa consegue rotular com cuidado numa
tarde, e faça o conjunto crescer a partir das falhas que aparecem no uso. Um conjunto que só cresce
a partir de erros reais fica mais difícil exatamente onde o trabalho é difícil.
