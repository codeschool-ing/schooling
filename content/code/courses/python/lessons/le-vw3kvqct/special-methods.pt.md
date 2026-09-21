---
title: A interface que a linguagem já sabe chamar
version: 1
---

O Python chama certos métodos pelo nome. Escrever um liga a sua classe a uma sintaxe que já existe.

## `__repr__` e `__str__`

```python
class Aluno:
    def __repr__(self):
        return f"Aluno(nome={self.nome!r}, cidade={self.cidade!r})"
```

O `__repr__` é para quem desenvolve: o interpretador, uma linha de log, uma lista impressa na
depuração. **Escreva um para toda classe que você definir.** Sem ele você recebe `<__main__.Aluno
object at 0x7f3c…>`, que diz o tipo e mais nada, exatamente na hora em que você queria o conteúdo.

O `__str__` é para uma pessoa — `print(x)` e `f"{x}"` o usam. Se for escrever só um, escreva o
`__repr__`: o `str` recorre a ele, e o contrário não.

O `!r` na f-string pede o `repr` de cada campo, que é o que mantém as aspas numa string e faz da
linha algo que você poderia colar de volta.

## O `__eq__`

```python
    def __eq__(self, outro):
        if not isinstance(outro, Aluno):
            return NotImplemented
        return (self.nome, self.cidade) == (outro.nome, outro.cidade)
```

Agora o `==` compara valores em vez de identidade. Devolver `NotImplemented` para um tipo sem
relação é a recusa correta — o Python então tenta o `__eq__` do outro objeto antes de decidir.

**Definir `__eq__` põe `__hash__` em `None`**, o que torna a classe não hasheável e inutilizável
como chave de dicionário. Isso é deliberado: algo que muda e compara por valor quebraria o
dicionário em que está. Devolva o `__hash__` só para algo imutável.

## `__len__`, `__bool__`, `__contains__`, `__getitem__`

```python
    def __len__(self):  return len(self.notas)
```

`len(x)` chama `__len__`. `if x:` chama `__bool__`, e recorre ao `__len__` — então **uma classe com
um `__len__` e nenhuma nota é falsa**, o que surpreende quem esperava que um objeto fosse verdadeiro
por existir. O `in` chama `__contains__`; `x[i]` chama `__getitem__`.

## `__lt__`, e o `functools.total_ordering`

O `<` chama `__lt__`, e o `sorted` precisa só desse. Escrever as seis comparações à mão é onde os
enganos moram; o `@total_ordering` deriva o resto do `__lt__` e do `__eq__`.

## A regra

**Escreva os que fazem a sua classe se comportar como aquilo que ela já é.** Uma classe que é uma
coleção merece `__len__` e `__iter__`. Uma classe que é um valor merece `__eq__`. Uma que não é nem
uma coisa nem outra precisa só do `__repr__` — e o `__repr__` é o que nunca é desperdiçado.
