---
title: Uma cópia para todo mundo, e a armadilha nisso
version: 1
---

```python
class Aluno:
    escola = "codeschool"        # atributo de classe: um, compartilhado

    def __init__(self, nome):
        self.nome = nome         # atributo de instância: um por aluno
```

`Aluno.escola` existe uma vez. Toda instância o enxerga pela busca, então `ada.escola` funciona sem
`ada` ter um próprio.

## Atribuir pela instância não muda a classe

```python
ada.escola = "outra"       # cria um atributo de INSTÂNCIA que o sombreia
Aluno.escola               # continua 'codeschool'
```

A leitura vai à instância primeiro, e depois à classe. A escrita sempre cai na instância. Essa
assimetria é a fonte de quase toda a confusão aqui, e é a mesma forma das regras de escopo da
aula 5.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Ler um atributo olha primeiro a instância e depois a classe, então uma instância sem escola própria acha o atributo da classe. Escrever sempre cai na instância: cria um que sombreia a classe, e o atributo da classe nunca se move.\"> <defs><marker id=\"ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <text x=\"177\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper-dim)\">lendo ada.escola</text> <rect x=\"20\" y=\"36\" width=\"314\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"177\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">Aluno: escola = &quot;codeschool&quot;</text> <rect x=\"50\" y=\"136\" width=\"254\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"177\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">ada: nome</text> <path d=\"M177 130 L177 82\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <text x=\"187\" y=\"106\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">não está na instância, então a busca sobe</text> <text x=\"543\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">depois de ada.escola = &quot;outra&quot;</text> <rect x=\"386\" y=\"36\" width=\"314\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"543\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">Aluno: escola = &quot;codeschool&quot;</text> <rect x=\"416\" y=\"136\" width=\"254\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"543\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">ada: nome, escola = &quot;outra&quot;</text> <text x=\"543\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">achou na instância, então a busca para aqui</text> <text x=\"360\" y=\"206\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">e Aluno.escola continua &quot;codeschool&quot;</text> </svg>", "caption": "A leitura vai instância primeiro, depois classe. A escrita sempre cai na instância — e é nessa assimetria que mora a confusão."}
```

## O atributo de classe mutável

```python
class Aluno:
    notas = []              # UMA lista, compartilhada por todo aluno já criado

    def acrescentar_nota(self, nota):
        self.notas.append(nota)     # acrescenta à compartilhada
```

Esta é a armadilha do padrão mutável da aula 5 na outra fantasia dela. O `append` não atribui,
então ele nunca cria um atributo de instância — ele altera o da classe, e agora todo aluno tem
todas as notas. **Um atributo de classe mutável é quase sempre um defeito**; ponha-o no `__init__`.

Uma constante — uma string, um número, uma tupla — é o caso em que o atributo de classe está certo.

## `@classmethod` e `@staticmethod`

```python
class Aluno:
    @classmethod
    def de_linha(cls, linha):
        return cls(linha["nome"])      # cls é a classe

    @staticmethod
    def nota_valida(n):
        return 0 <= n <= 100
```

Um `classmethod` recebe a CLASSE como primeiro argumento, e o uso comum dele é um construtor
alternativo — `Aluno.de_linha(linha)` se lê melhor que uma função de nível de módulo que constrói
um. Usar `cls(...)` em vez de `Aluno(...)` faz uma subclasse receber o próprio tipo de volta.

Um `staticmethod` não recebe nenhum dos dois. É uma função comum que calha de morar na classe por
arrumação — e **se ela não toca a classe em nada, uma função de nível de módulo era a resposta
honesta**.
