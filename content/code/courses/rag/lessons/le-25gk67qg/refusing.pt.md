---
title: Dizendo que as fontes não dizem
version: 2
---

A terceira linha da mensagem de sistema diz ao modelo o que responder quando as fontes não respondem. É a
instrução mais importante do prompt, porque a alternativa é a resposta de livro fechado da aula 1:
fluente, confiante e inventada. E é aquela em que esta aula menos confia.

## A instrução, sem nada a que se aplicar

O `no_floor.py` manda o que o `ask` mandaria se o código chamasse o modelo fosse o que fosse que a busca
achasse: a mensagem de sistema, a pergunta, e nenhuma fonte, porque nada passou do piso.

```schooling-example
{
  "language": "python",
  "file": "no_floor.py",
  "parts": [
    {
      "code": "import sys\n\nfrom answer import ask\n\n# What the model is sent when the search found nothing above the floor and the\n# code calls it anyway: the instructions and the question, and no sources.\nprint(ask(sys.argv[1], []))",
      "note": "O `ask` com uma lista vazia de fontes: a mensagem de sistema e a pergunta, e nada de onde responder."
    }
  ]
}
```
```
ana@vm:~/rag$ python no_floor.py "Can I place an order by phone?"
I could not find that in our documents.
```

**Sem nada de onde responder, o modelo obedeceu**, palavra por palavra. É a instrução funcionando uma
vez, numa pergunta, numa máquina, e ela vale exatamente isso. A aula 1 perguntou ao mesmo modelo sobre
devolver um livro sem fontes e sem instrução, e recebeu regras de empréstimo de biblioteca, fluentes,
confiantes e sobre outro negócio. Uma instrução é seguida na maior parte das vezes. *Na maior parte das
vezes* é a descrição honesta de toda instrução que um modelo recebe, e um telefone de uma central que
não existe é o tipo de resposta que acaba num print.

Então o `answer` não pergunta:

```
ana@vm:~/rag$ python answer.py "Can I place an order by phone?"
I could not find that in our documents.
ana@vm:~/rag$ python answer.py "Is there a student discount?"
I could not find that in our documents.
ana@vm:~/rag$ python answer.py "Can I pay in instalments?"
I could not find that in our documents.
```

**Quando nada passa do piso, o código devolve a recusa e o modelo nem é chamado.** As duas primeiras estão
certas: nenhum documento fala de pedido por telefone ou de desconto para estudantes. A terceira é o preço
que a aula 6 anunciou: a resposta está no documento de pagamentos, mas o pedaço dela marcou 0,445, abaixo
do piso de 0,5, então um cliente que pergunta sobre parcelas ouve que os documentos não dizem. O piso e os
erros dele foram escolhidos juntos, e o piso é o lugar mais barato para pôr a decisão, porque é um número
no código, não uma frase que um modelo pode ou não obedecer.

## O quanto um piso consegue neste conjunto de teste

A aula 6 escolheu 0,5 olhando o que a busca devolvia. Esta lista faz a mesma pergunta pelo outro lado.
Ela gera o embedding de cada frase de cada documento e imprime a melhor similaridade que cada pergunta
de teste acha em qualquer lugar:

```schooling-example
{
  "language": "python",
  "file": "floor.py",
  "parts": [
    {
      "code": "import glob\nimport json\n\nfrom chunking import sentences\nfrom vectors import embed\n\npool = [s for path in sorted(glob.glob(\"data/docs/*.md\")) for s in sentences(open(path).read())]\nvectors = embed(pool)\nfor line in open(\"data/eval.jsonl\"):\n    q = json.loads(line)\n    best = float((vectors @ embed(q[\"question\"])[0]).max())\n    print(f\"{best:.2f}  {'answerable  ' if q['facts'] else 'unanswerable'}  {q['question']}\")",
      "note": "Cada frase de cada documento, cortada pelo `sentences` da aula 4, e para cada pergunta de teste a melhor similaridade que ela acha entre elas."
    }
  ]
}
```
```
ana@vm:~/rag$ python floor.py | sort -r | sed -n "22,30p"
0.56  answerable    How often are sellers paid?
0.55  answerable    What must I check before changing a customer's order?
0.55  answerable    What does error E-4102 mean in the affiliate API?
0.52  unanswerable  Can I place an order by phone?
0.52  answerable    When is the contract of sale formed?
0.49  unanswerable  Which carrier do you use in Portugal?
0.47  answerable    Can I pay in instalments?
0.44  unanswerable  Do you have a shop in Porto Alegre where I can pick up books?
0.36  unanswerable  Is there a student discount?
```

O meio da lista é o que está impresso, onde os dois tipos se encontram, e **eles se sobrepõem**. *Can I
place an order by phone?*, que nenhum documento responde, acha uma frase com 0,52, tão perto quanto
*When is the contract of sale formed?*, que os termos de venda respondem, e mais perto que *Can I pay
in instalments?*, com 0,47. Nenhum número separa os dois tipos: todo piso recusa algumas perguntas
respondíveis ou deixa passar algumas sem resposta, e movê-lo só escolhe quais. Um piso ajustado a estas
trinta perguntas também pareceria melhor nelas do que nas perguntas que chegam depois, e é por isso que
a aula 8 separa uma parte do conjunto de teste.

## Recusar bem

Uma recusa é uma resposta, e pode ser boa ou ruim. **Diga o que não está coberto**, para que um cliente
que perguntou duas coisas saiba qual falhou. **Ofereça um próximo passo**, o formulário de contato, uma
pessoa, a busca da central de ajuda, porque um cliente recusado continua sem resposta para a pergunta.
**E registre**: recusas são a lista mais barata que uma equipe vai ter dos documentos que ainda não
escreveu.
