---
title: Funções que recebem a instância
version: 1
---

```python
class Aluno:
    def __init__(self, nome):
        self.nome = nome
        self.notas = []

    def acrescentar_nota(self, nota):
        self.notas.append(nota)

    def media(self):
        if not self.notas:
            return 0
        return sum(self.notas) / len(self.notas)
```

Um método é uma função definida no corpo da classe cujo primeiro parâmetro é a instância. Fora
isso é uma função comum: padrões, `*args`, retorno antecipado, tudo da aula 5.

## Chamar um de dentro de outro

```python
    def relatorio(self):
        return f"{self.nome}: {self.media():.1f}"
```

`self.media()` — pela instância, nunca pelo nome puro. Escrever `media()` dentro de `relatorio`
procura uma função de nível de módulo e levanta um `NameError`, que são as regras de escopo da
aula 5 respondendo exatamente como devem.

## Devolver um objeto novo em vez de alterar este

```python
    def com_cidade(self, cidade):
        return Aluno(self.nome, cidade)      # um aluno novo
```

Duas formas, e a escolha vale ser deliberada: um método que ALTERA a instância devolve `None` por
convenção, e um método que devolve um objeto NOVO deixa o original em paz. O `list.sort` e o
`sorted` são esse par na biblioteca padrão, e a aula 3 os encontrou.

**Misturar os dois numa classe só é o que confunde as pessoas** — uma classe em que alguns métodos
alteram e outros devolvem cópias precisa que os nomes digam qual é qual.

## Um método é uma função na classe

```python
Aluno.media            # uma função comum
ada.media              # um método ligado: a função, com ada presa nela
```

`ada.media` é a função com o `self` já preenchido. É por isso que ele dá para passar adiante como
qualquer outro valor — `sorted(alunos, key=Aluno.media)` funciona, e `map(ada.acrescentar_nota,
notas)` também.
