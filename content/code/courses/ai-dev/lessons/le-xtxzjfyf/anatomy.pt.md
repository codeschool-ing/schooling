---
title: Do que é feito um prompt de tarefa
version: 2
---

O mesmo pedido, feito de dois jeitos, recebe dois tipos de resposta. A diferença raramente é a
esperteza da frase. **É se o prompt leva o que um colega precisaria para fazer o trabalho sem voltar
para perguntar**: o que mudar, para que serve, o que não pode mudar, como você vai saber que ficou
pronto, e em que forma você quer a resposta.

## A versão curta

A loja da ana recusa `12,90`, que é como um cliente brasileiro digita um preço. O pedido mais rápido
tem uma linha, enviado com o `assist` da aula 3 e o arquivo aberto. A resposta vai para
`scratch/reply.txt`, e o `cat -n` numera as linhas dela:

```
ana@dev:~/shop$ python scratch/assist.py ask "Fix parse_price so it accepts commas." --open shop/money.py > /dev/null
context sent (137 of 3000 tokens):
    137  shop/money.py
---
ana@dev:~/shop$ cat -n scratch/reply.txt
     1	You can use Python's built-in `replace` method to remove commas from the input string, and then proceed with the existing logic. Here's the updated `parse_price` function:
     2	
     3	```python
     4	def parse_price(text: str) -> int:
     5	    """Turn a price as people write it into cents: '12.90' -> 1290."""
     6	    text = text.replace(",", "")  # Remove commas
     7	    units, _, cents = text.strip().partition(".")
     8	    cents = (cents + "00")[:2]
     9	    return int(units) * 100 + int(cents)
    10	```
    11	
    12	Now the function should correctly parse prices with commas, such as "12,90".
```

A linha 6 apaga toda vírgula. `12,90` vira `1290`, que a função lê como mil duzentas e noventa
unidades, e o preço sai como 129000 centavos: uma caneca de 12,90 cobrada a 1290,00. O modelo leu a
vírgula como o inglês escreve `1,290`, separando os milhares, e para essa leitura a resposta está
certa. **Nada na resposta está errado para a pergunta que foi feita.** A pergunta nunca disse que a
vírgula era o separador decimal, nem quem a digita, e não levava nenhuma regra do projeto.

## As cinco partes

A ana escreve o pedido num arquivo, para poder lê-lo antes de enviar e reaproveitá-lo depois:

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
| objetivo | a mudança, e por que ela é desejada: o motivo deixa quem lê escolher entre dois jeitos de fazer |
| contexto | o código e as regras, enviados com o prompt (aula 1, seção 10: se não está na requisição, o modelo não sabe) |
| restrições | o que não pode mudar, e as regras que a mudança precisa manter |
| pronto quando | os casos que decidem se deu certo, que também são os testes |
| responda com | a forma da resposta, para que um programa possa conferi-la (aula 5, seção 05) |

```
ana@dev:~/shop$ wc -w prompts/comma.md
81 prompts/comma.md
```

Oitenta e uma palavras. **As palavras a mais não são cortesia**, e a maioria delas a ana escreveria
no chamado de qualquer jeito. Só o objetivo já teria evitado a resposta acima: ele diz que a vírgula
é decimal e dá `12,90` como caso. Um prompt que se lê como um bom chamado é um bom prompt, e o hábito
paga duas vezes, porque o mesmo texto conta para a próxima pessoa para que serviu a mudança.

## O que não precisa estar lá

- **Persuasão.** "Você é um engenheiro de nível mundial", "isto é muito importante", "respire
  fundo". O modelo não está com falta de motivação; está com falta de fatos.
- **Repetição em maiúsculas.** Se uma restrição importa, diga uma vez, com clareza, e confira com um
  teste. A aula 3, seção 05, disse o mesmo sobre arquivos de instruções.
- **O repositório inteiro.** Os arquivos que a mudança toca, os testes desses arquivos e as regras que
  valem. A aritmética da aula 2 cobra o resto a cada requisição.
