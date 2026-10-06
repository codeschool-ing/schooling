---
title: Uma resposta precisa se apoiar na fonte
version: 1
---

O assistente responde às perguntas dos clientes a partir da central de ajuda da Tarefa. **Uma resposta
está ancorada quando o que ela diz pode ser achado nas fontes que recebeu**, e a defesa mais barata
contra uma resposta inventada é exigir que ela nomeie as fontes e depois conferir se elas dizem o que ela
diz. A central de ajuda do laboratório são três páginas curtas, escritas pelo curso:

```
ana@lab:~/guard$ ls data/helpdesk
hc-fees.md
hc-payouts.md
hc-refunds.md
ana@lab:~/guard$ cat data/helpdesk/hc-refunds.md
# Refunds

A client may ask for a refund of a job up to 14 days after its due date.
If the freelancer delivered nothing, the refund is the full amount paid.
If part of the work was delivered, a person on the support team decides the amount.
Refunds reach the client's card or Pix account in up to 5 business days.
```

O `data/answers.jsonl` tem seis respostas, **escritas pelo curso no lugar do que um modelo
responderia**, cada uma com os documentos que cita. O `guard ground` aplica três regras: uma resposta
cita ao menos um documento ou diz que não sabe; todo documento citado existe; todo número da resposta
aparece num documento citado.

```
ana@lab:~/guard$ head -2 data/answers.jsonl
{"id": "a1", "question": "How long do I have to ask for a refund?", "text": "You can ask for a refund up to 14 days after the job's due date.", "cites": ["hc-refunds"]}
{"id": "a2", "question": "How long do I have to ask for a refund?", "text": "You can ask for a refund up to 30 days after the job's due date.", "cites": ["hc-refunds"]}
ana@lab:~/guard$ guard ground data/answers.jsonl; echo "exit $?"
a1  ok    grounded in hc-refunds
a2  FLAG  the number 30 is in no cited document
a3  FLAG  cites hc-guarantee, which does not exist
a4  FLAG  cites nothing
a5  ok    abstains
a6  ok    grounded in hc-payouts
3 of 6 answers flagged
exit 1
```

- A `a2` cita a página certa e diz 30 dias onde a página diz 14. O número é a invenção, e o número é o
  que o cliente usa para agir.
- A `a3` cita `hc-guarantee`, uma página que não existe, para uma garantia que também não existe. Uma
  fonte inventada é a forma mais comum de uma resposta inventada, e a mais fácil de pegar.
- A `a4` não cita nada e afirma uma taxa de 15%, contra os 10% da página de taxas.
- A `a5` diz que não sabe e passa a pergunta a uma pessoa. **Abster-se é uma resposta correta**, e um
  sistema que pune isso ensina o modelo, pelo prompt e pela avaliação, a chutar.

O que acontece com uma resposta marcada segue a aula 19: ela não é mostrada, e a pergunta volta ao modelo
uma vez com o problema, ou vai para uma pessoa.

## O que esta verificação não vê

A `a6` passou. Leia-a contra a fonte:

```
ana@lab:~/guard$ grep a6 data/answers.jsonl
{"id": "a6", "question": "When are freelancers paid?", "text": "Freelancers are paid by Pix 2 business days after the job is posted.", "cites": ["hc-payouts"]}
ana@lab:~/guard$ cat data/helpdesk/hc-payouts.md
# Payouts

Freelancers are paid by Pix 2 business days after the client approves the work.
A payout key can only be changed on the Payouts page.
```

A resposta cita a página certa e todo número dela está na página. Mesmo assim está errada: o pagamento
vem depois da aprovação do cliente, não da publicação do trabalho. A verificação compara números e
nomes, **e não entende uma frase**, então uma conclusão errada tirada da página certa passa.

Há verificações mais fortes, e custam mais: comparar cada afirmação com o trecho de onde veio usando um
segundo modelo, ou mostrar ao cliente o trecho ao lado da resposta para que ele veja. Cada uma pega parte
do que a verificação barata deixa passar, e nenhuma pega tudo, e é por isso que os documentos de que o
assistente responde são mantidos curtos, atuais e sem ambiguidade. Uma central de ajuda que se contradiz
produz respostas ancoradas que se contradizem.
