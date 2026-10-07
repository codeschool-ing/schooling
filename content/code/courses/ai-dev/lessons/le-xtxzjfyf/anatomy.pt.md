---
title: Do que é feito um prompt de tarefa
version: 1
---

O mesmo pedido, feito de dois jeitos, recebe dois tipos de resposta. A diferença raramente é a
esperteza da frase. **É se o prompt leva o que um colega precisaria para fazer o trabalho sem voltar
para perguntar**: o que mudar, para que serve, o que não pode mudar, como você vai saber que ficou
pronto, e em que forma você quer a resposta.

## A versão curta

A loja da ana recusa `12,90`, que é como um cliente brasileiro digita um preço. O pedido mais rápido
tem uma linha. A resposta foi escrita pelo curso, como toda resposta de modelo desta aula:

```
ana@dev:~/shop$ assist ask "Fix parse_price so it accepts commas." --open shop/money.py
context sent (137 of 3000 tokens):
    137  shop/money.py
---
Here is a version that handles both separators:

def parse_price(text: str) -> int:
    return round(float(text.strip().replace(",", ".")) * 100)

```

Funciona, para a maioria das entradas, e quebra uma regra. O `CONVENTIONS.md` diz que um float
nunca guarda dinheiro, nem por um instante, e esta resposta passa por `float` no caminho até os
centavos. O assistente não tinha como saber: as convenções não estavam no contexto, e a linha não
dizia. **Nada na resposta está errado para a pergunta que foi feita.** Faltava o projeto na
pergunta.

## As cinco partes

A ana escreve o pedido num arquivo, para poder lê-lo antes de mandar e reaproveitá-lo depois:

```
Goal: `parse_price` in shop/money.py must accept a comma as the decimal
separator, because Brazilian customers type `12,90`.

Context: the function and its tests are below. CONVENTIONS.md is below too;
money is integer cents and a float must never hold it.

Constraints: change only `parse_price`. Keep the arithmetic in integers.
Do not change any existing test.

Done when: `12,90` and `12,9` give 1290, `12.90` still gives 1290, and the
whole suite passes.

Answer with: a unified diff against shop/money.py, and nothing else.
```

| parte | o que faz |
|---|---|
| objetivo (goal) | a mudança, e por que ela é desejada: o motivo deixa quem lê escolher entre dois jeitos de fazer |
| contexto (context) | o código e as regras, mandados com o prompt (aula 1 seção 10: se não está na requisição, o modelo não sabe) |
| restrições (constraints) | o que não pode mudar, e as regras que a mudança tem de manter |
| pronto quando (done when) | os casos que decidem se deu certo, que também são os testes |
| responda com (answer with) | a forma da resposta, para um programa poder conferi-la (aula 5 seção 05) |

```
ana@dev:~/shop$ wc -w prompts/comma.md
81 prompts/comma.md
```

Oitenta e uma palavras. **As palavras a mais não são cortesia**, e a maioria são coisas que a ana
escreveria no chamado de qualquer jeito. Um prompt que se lê como um bom chamado é um bom prompt, e o
hábito paga duas vezes: o mesmo texto diz à próxima pessoa para que serviu a mudança.

## O que não precisa estar lá

- **Persuasão.** "Você é um engenheiro de nível mundial", "isto é muito importante", "respire
  fundo". Ao modelo não falta motivação; faltam fatos.
- **Repetição em maiúsculas.** Se uma restrição importa, diga uma vez, com clareza, e confira com um
  teste. A aula 3 seção 05 disse o mesmo sobre arquivos de instruções.
- **O repositório inteiro.** Os arquivos que a mudança toca, os testes deles e as regras que valem. A
  conta da aula 2 cobra o resto em toda requisição.
