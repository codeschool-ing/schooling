---
title: O que uma verificação deve comparar
version: 1
---

Uma verificação (o `assert`) é uma pergunta de sim ou não sobre um resultado. **A melhor verificação
compara o resultado inteiro com um valor esperado exato**, porque é a comparação que falha para o
maior número de respostas erradas.

Compare duas formas de testar a resposta HTTP de uma cotação:

```python
assert "price" in body                                  # passes for any price
assert body == {"cep": "01310-100", "zone": "SP",       # passes for one answer
                "cents": 2190, "price": "R$ 21,90"}
```

A primeira passa se o preço estiver errado, se a zona faltar ou se `cents` voltar como string. A
segunda falha em todos esses casos. Uma verificação fraca é pior do que nenhum teste, porque
acrescenta uma linha verde ao relatório que promete mais do que conferiu.

## Valor exato pede aritmética exata

Dinheiro é o lugar clássico onde o "exato" dá errado:

```
ana@laptop:~/shipquote$ python3 -c 'print(0.1 + 0.2 == 0.3, 0.1 + 0.2)'
False 0.30000000000000004
ana@laptop:~/shipquote$ python3 -c 'print(10 + 20 == 30)'
True
```

`0.1 + 0.2` não é `0.3` em ponto flutuante binário; é `0.30000000000000004`. Um teste que compara
preços guardados como float ou falha sem motivo de negócio, ou é "consertado" com uma tolerância, e
uma tolerância em dinheiro esconde erros reais de um centavo. **É por isso que o `shipquote` guarda
todo valor em centavos inteiros**, e por isso seus testes comparam com `==`. Quando um valor é de
fato aproximado, como uma duração medida, o pytest oferece `pytest.approx` com uma tolerância
explícita; usá-lo é declarar que a aproximação faz parte da especificação.

## Verificando que algo é recusado

Recusa também é comportamento. `freight` precisa recusar peso zero, e o teste diz isso com
`pytest.raises`:

```python
def test_a_weight_of_zero_is_refused():
    with pytest.raises(ValueError, match="weight must be positive"):
        freight("01310-100", 0, 5000)
```

O bloco `with` só passa se o código dentro dele levantar um `ValueError` cuja mensagem case com o
padrão. Se nada for levantado, o teste falha. O `match` importa: sem ele, um `ValueError` de outra
linha qualquer, um erro de leitura por exemplo, também satisfaria o teste.

## Um comportamento por teste

Um teste que afirma dez coisas sem relação para na primeira falha e esconde as outras nove. Um
teste com o nome de um comportamento, com as verificações de que esse comportamento precisa, diz o
que quebrou só pelo nome. `test_split_adds_back_up_to_the_total` e
`test_split_hands_the_odd_cents_to_the_first_instalments` são dois testes de uma função, porque são
duas promessas: uma pode quebrar sem a outra.

**Dê ao teste o nome da regra, não da função.** `test_split_1` não diz nada quando fica vermelho às
3 da manhã num log de pipeline. `test_split_adds_back_up_to_the_total` é uma frase com a qual uma
pessoa age sem abrir o arquivo.
