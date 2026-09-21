---
title: O atributo que é calculado, e o que confere
version: 1
---

```python
class Retangulo:
    def __init__(self, largura, altura):
        self.largura = largura
        self.altura = altura

    @property
    def area(self):
        return self.largura * self.altura

r = Retangulo(3, 4)
r.area          # 12 — sem parênteses
```

O `@property` faz um método parecer um atributo. `r.area` roda a função e devolve o valor dela.

## Por que não simplesmente um método

Porque `area` não é algo que o retângulo FAZ, é algo que ele É. Quem chama não deveria ter de
lembrar qual entre `r.largura` e `r.area()` precisa de parênteses quando os dois são só fatos sobre
o retângulo.

**E é uma mudança que dá para fazer depois.** Um atributo que começa como dado puro dá para virar
uma property sem nenhuma chamada mudar — que é exatamente por que o Python não tem getters e
setters por toda parte: você os acrescenta no dia em que precisa.

## O setter, que é onde a validação vai

```python
class Aluno:
    @property
    def nota(self):
        return self._nota

    @nota.setter
    def nota(self, valor):
        if not 0 <= valor <= 100:
            raise ValueError(f"nota fora da faixa: {valor}")
        self._nota = valor
```

Agora `aluno.nota = 150` levanta erro, no momento em que o valor errado chega em vez de três
funções depois. O valor de verdade mora em `self._nota` — o sublinhado diz "meu", e a property é a
porta.

**Os nomes precisam ser diferentes**, ou o setter chama a si mesmo. Esse é o engano que todo mundo
comete uma vez, e ele aparece como um `RecursionError`.

## O que deixar de fora de uma

Uma property deveria ser barata e não deveria surpreender. Ler um atributo que abre um arquivo, faz
uma requisição ou leva um segundo é uma property que mentiu sobre o próprio custo — **isso é um
método, com parênteses, para quem chama enxergar o trabalho**.

E ela não deveria mudar nada. Um `r.area` que também incrementa um contador é um fato que se move
quando você olha para ele.
