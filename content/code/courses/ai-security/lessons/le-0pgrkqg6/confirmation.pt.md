---
title: As chamadas que uma pessoa confirma, e o que é a confirmação
version: 1
---

Algumas ações são permitidas ao agente e ainda assim não deveriam acontecer sem uma pessoa. O
`issue_refund` é o exemplo: está dentro da tarefa do agente, e **move dinheiro e não pode ser desfeito**,
que é o texto que o manifesto põe nele. Então o portão o retém:

```
ana@lab:~/guard$ guard gate data/proposed-calls.jsonl --confirm c3
a confirmation names the person who gave it: add --by NAME
ana@lab:~/guard$ guard gate data/proposed-calls.jsonl --confirm c3 --by ana.lima | grep c3
c3  issue_refund   ALLOW  confirmed by ana.lima
```

Uma confirmação sem nome é recusada. **Uma confirmação é um ato administrativo, e registra quem o
tomou**, pelo mesmo motivo que todo outro ato: quando um reembolso é questionado um mês depois, "o
sistema permitiu" não responde nada, e "ana.lima confirmou às 14:02" responde a pergunta.

## Quais chamadas precisam de uma pessoa

A regra prática é sobre consequências, não sobre ferramentas:

- **irreversíveis**: dinheiro movido, mensagem enviada, registro apagado;
- **fora da plataforma**: qualquer coisa que alcance uma pessoa ou sistema que a Tarefa não controla;
- **grandes**: um efeito muito maior que o da chamada típica, mesmo que reversível.

Leitura quase nunca está na lista. Uma consulta que devolve o pedido errado gasta um turno; um
reembolso para o trabalho errado é um custo e um caso de suporte.

## Uma confirmação mostra o que vai acontecer, exatamente

Quem confirma é a última verificação, e só consegue conferir o que lhe mostram. Uma tela de confirmação
que diz *"O assistente quer emitir um reembolso. Permitir?"* pede confiança, não uma decisão. Uma que
mostra **a ferramenta, cada argumento e o efeito em palavras simples**, como *"Reembolsar R$ 1.200,00 a
Marcos Teixeira pelo trabalho 4471, o valor pago inteiro"*, deixa a pessoa perceber que o número do
trabalho está errado.

Dois modos de falha vêm com a confirmação, e os dois são sobre pessoas:

- **Fadiga.** Uma pessoa a quem pedem quarenta confirmações rotineiras por dia confirma a quadragésima
  primeira sem ler. Mantenha curta a lista de ações confirmadas, para que cada uma valha a leitura.
- **Confirmar o que o portão já recusou.** A `c4` pede R$ 9.000,00 contra R$ 1.200,00 pagos, e o portão
  a recusa antes de alguém ser consultado. Um limite que uma pessoa pudesse derrubar com um clique
  viraria uma sugestão; uma confirmação acrescenta uma verificação, nunca tira uma.
