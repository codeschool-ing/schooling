---
title: Quem está perguntando
version: 1
---

A aula 2 terminou num vazamento. Um atendente perguntou quando um pedido fica retido para revisão
manual de fraude, e o pipeline, buscando em todos os documentos para todo mundo, respondeu com o
limite que a equipe financeira tinha escrito como não sendo para atendentes: 0,82. Nada no pipeline
falhou. Ele não sabia quem estava perguntando, então não tinha como saber o que quem perguntou podia
ler.

Todo pedaço carrega o `audience` do seu documento desde a aula 5: `public`, `staff`, `finance`,
`sellers` ou `developers`. O que faltava era a outra metade, **uma decisão sobre quais públicos cada
leitor abre**, tomada uma vez e escrita onde possa ser revisada:

```schooling-example
{
  "language": "python",
  "file": "access.py",
  "parts": [
    {
      "code": "\"\"\"Who may read what: the audiences each role opens, decided by the system and never by the question.\"\"\"\nimport psycopg\nfrom minilm import embed\nfrom pgvector.psycopg import register_vector\n\nROLES = {\n    \"customer\":  [\"public\"],\n    \"seller\":    [\"public\", \"sellers\"],\n    \"developer\": [\"public\", \"developers\"],\n    \"agent\":     [\"public\", \"staff\"],\n    \"finance\":   [\"public\", \"staff\", \"finance\"],\n}",
      "note": "Quem pode ler o quê, escrito uma vez. Cada papel abre uma lista de públicos, os valores do campo `audience` que todo pedaço carrega desde a aula 5."
    },
    {
      "code": "def audiences(role):\n    \"\"\"The audiences a role may read. A role nobody wrote down reads nothing.\"\"\"\n    return ROLES.get(role, [])",
      "note": "Um papel que não está no dicionário recebe uma lista vazia, e uma lista vazia não casa com linha nenhuma. Um erro de digitação no nome do papel fecha a porta em vez de abri-la."
    }
  ]
}
```

O papel vem da sessão: a conta que entrou, as permissões dela no sistema da própria loja. Nunca vem da
requisição nem da pergunta. Neste laboratório um dicionário faz as vezes desse sistema, e um programa
diz qual papel está representando.

```
ana@lab:~/rag$ python roles.py "When does an order get held for manual fraud review?" customer agent finance
When does an order get held for manual fraud review?
customer  Returns and refunds policy > Damaged, faulty and wrong items (public, 0.516), Terms of sale > 2. Placing an order (public, 0.506)
          I could not find that in our documents.
agent     Customer support handbook > Suspected fraud (staff, 0.586), Returns and refunds policy > Damaged, faulty and wrong items (public, 0.516), Terms of sale > 2. Placing an order (public, 0.506)
          I could not find that in our documents.
finance   Refund controls and chargebacks > Automatic holds (finance, 0.644), Customer support handbook > Suspected fraud (staff, 0.586), Returns and refunds policy > Damaged, faulty and wrong items (public, 0.516)
          An order with a score of 0.82 or more is held before dispatch and goes to manual review. [1] The payment provider gives every order a fraud score from 0 to 1. [1]
```

A mesma pergunta, três leitores, três conjuntos de fontes. **Só o financeiro recebe o documento do
financeiro**, e o 0,82 na resposta. A primeira fonte do atendente é a seção do manual sobre suspeita de
fraude, que é o que um atendente deve saber; as fontes do cliente são duas seções públicas que passam
do piso sem tratar de retenção por fraude. As duas respostas são a recusa: o extract-1 não achou frase
no que esses leitores podem ver perto o bastante de "quando um pedido fica retido", e para o cliente
essa é a resposta certa. Para o atendente, uma pergunta sobre o que fazer, e não sobre a regra, mostra
o que o manual lhe dá:

```
ana@lab:~/rag$ python roles.py "What happens to an order that looks fraudulent?" agent finance
What happens to an order that looks fraudulent?
agent     Customer support handbook > Suspected fraud (staff, 0.678), Terms of sale > 2. Placing an order (public, 0.516)
          If an order looks wrong to you, for example a new account ordering many copies of one expensive title to an address that is not the billing address, do not accuse the customer and do not cancel the order yourself. [1]
finance   Customer support handbook > Suspected fraud (staff, 0.678), Refund controls and chargebacks > Automatic holds (finance, 0.554), Terms of sale > 2. Placing an order (public, 0.516)
          If an order looks wrong to you, for example a new account ordering many copies of one expensive title to an address that is not the billing address, do not accuse the customer and do not cancel the order yourself. [1] The payment provider gives every order a fraud score from 0 to 1. [2]
```

O atendente ouve que não deve acusar o cliente nem cancelar o pedido, a instrução do manual. O
financeiro recebe a mesma frase e, como fonte 2, o fato sobre notas de fraude do seu próprio
documento. **Cada leitor recebeu a melhor resposta que as suas permissões permitem**, e ninguém recebeu
uma resposta feita de texto que não pode ler.
