---
title: A classe base frágil
version: 1
---

**Uma subclasse depende de como o pai funciona por dentro, e o autor do pai não consegue ver essa
dependência.** O pai pode mudar de um jeito correto, testado e inofensivo para todo mundo que o
chama, e ainda assim quebrar um filho que outra pessoa escreveu. O nome disso é problema da classe
base frágil, e é o motivo mais forte para o título desta lição dizer *quase sempre*.

A imagem comum é que a herança reaproveita a *interface* do pai: seus métodos públicos, com o
significado que os nomes sugerem. Essa imagem erra num ponto específico. Um filho que sobrescreve um
método também herda todo lugar em que o pai chama esse método em `self`, e essas chamadas não fazem
parte de interface nenhuma que alguém tenha escrito.

Crie `~/patterns/composition` e trabalhe ali durante a lição inteira:

```sh
mkdir -p ~/patterns/composition
cd ~/patterns/composition
```

## Uma prateleira, e uma prateleira que conta

A biblioteca deixa as novidades numa prateleira, que é um objeto. Outra pessoa o escreveu, e ele
tem dois jeitos de pôr títulos nele:

```python
# shelf.py
class Shelf:
    def __init__(self):
        self._titles: list[str] = []

    def add(self, title: str) -> None:
        self._titles.append(title)

    def add_all(self, titles: list[str]) -> None:
        for title in titles:
            self.add(title)

    def __len__(self) -> int:
        return len(self._titles)
```

O relatório mensal quer saber quantos títulos foram para a prateleira. A herança parece o caminho
mais curto: um `CountingShelf` que é um `Shelf` com um contador, incrementado nos dois métodos.

```schooling-example
{"language": "python", "file": "counting.py", "parts": [
 {"code": "# counting.py\nfrom shelf import Shelf\n\n\nclass CountingShelf(Shelf):\n    def __init__(self):\n        super().__init__()\n        self.added = 0", "note": "Uma prateleira com um campo a mais. Todo o resto vem do pai."},
 {"code": "\n    def add(self, title: str) -> None:\n        self.added += 1\n        super().add(title)", "note": "Um título, mais um no contador, e o pai faz o trabalho de guardar."},
 {"code": "\n    def add_all(self, titles: list[str]) -> None:\n        self.added += len(titles)\n        super().add_all(titles)", "note": "Vários títulos, vários a mais no contador. Lido sozinho, cada método está correto."},
 {"code": "\n\nif __name__ == \"__main__\":\n    shelf = CountingShelf()\n    shelf.add(\"Dom Casmurro\")\n    shelf.add_all([\"Vidas Secas\", \"Iracema\", \"O Cortiço\"])\n    print(\"on the shelf:\", len(shelf))\n    print(\"counted:     \", shelf.added)", "note": "Um título, depois três: quatro na prateleira, e o contador devia dizer quatro."}
]}
```

```
ana@laptop:~/patterns/composition$ python3 counting.py
on the shelf: 4
counted:      7
```

Sete. `add_all` somou três ao contador e depois chamou o `add_all` do pai, que chama `self.add` uma
vez por título. `self` é um `CountingShelf`, então cada uma dessas chamadas cai no `add` do filho,
que conta de novo. **O filho foi quebrado por uma linha de dentro do pai que ele nunca leu.** Nada
nos métodos públicos de `Shelf` dizia que `add_all` é construído sobre `add`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 320\" role=\"img\" data-fig=\"l02-self-call\" aria-label=\"Um diagrama de sequência de counting.py acrescentando três títulos. O programa chama add_all no CountingShelf, que soma 3 ao contador e chama o add_all do pai, Shelf. O pai faz um laço e chama self.add uma vez por título; como self é o CountingShelf, cada uma dessas três chamadas volta para o add do filho, que soma 1 ao contador a cada vez antes de chamar o add do pai. Os três títulos são contados duas vezes: 1 do primeiro título, mais 3, mais 3, dá 7, enquanto a prateleira guarda 4.\"><defs><marker id=\"l02-self-call-dp-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l02-self-call-dp-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"25.0\" y=\"16.0\" width=\"150.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o programa</text><path d=\"M100.0 44.0 L100.0 272.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><rect x=\"275.0\" y=\"16.0\" width=\"150.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"350.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">CountingShelf</text><path d=\"M350.0 44.0 L350.0 272.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><rect x=\"525.0\" y=\"16.0\" width=\"150.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Shelf</text><path d=\"M600.0 44.0 L600.0 272.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><path d=\"M100.0 80.0 L346.0 80.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-self-call-dp-ah-paper-dim)\"></path><text x=\"225.0\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">add_all(3 titles)</text><text x=\"225.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">added += 3</text><path d=\"M350.0 135.0 L596.0 135.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-self-call-dp-ah-paper-dim)\"></path><text x=\"475.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">super().add_all(titles)</text><path d=\"M600.0 190.0 L354.0 190.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l02-self-call-dp-ah-amber)\"></path><text x=\"475.0\" y=\"179.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">self.add(title)  × 3</text><text x=\"475.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">self é o CountingShelf</text><text x=\"225.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">added += 1  × 3</text><path d=\"M350.0 245.0 L596.0 245.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-self-call-dp-ah-paper-dim)\"></path><text x=\"475.0\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">super().add(title)  × 3</text><text x=\"330.0\" y=\"300.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">contados: 1 + 3 + 3 = 7</text><text x=\"370.0\" y=\"300.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">na prateleira: 4</text></svg>", "caption": "O add_all do pai chama add em self, e self é o filho. Cada título acrescentado em lote é contado duas vezes."}
```

## O conserto que piora tudo

Depois que você sabe da chamada a `self`, o conserto parece óbvio: parar de contar em `add_all`, já
que o pai vai mandar todo título por `add` de qualquer jeito.

```schooling-example
{"language": "python", "file": "counting.py", "parts": [
 {"code": "# counting.py\nfrom shelf import Shelf\n\n\nclass CountingShelf(Shelf):\n    def __init__(self):\n        super().__init__()\n        self.added = 0\n\n    def add(self, title: str) -> None:\n        self.added += 1\n        super().add(title)", "note": "Agora só `add` é sobrescrito. O filho conta com o pai mandando todo título por ele."},
 {"code": "\n\nif __name__ == \"__main__\":\n    shelf = CountingShelf()\n    shelf.add(\"Dom Casmurro\")\n    shelf.add_all([\"Vidas Secas\", \"Iracema\", \"O Cortiço\"])\n    print(\"on the shelf:\", len(shelf))\n    print(\"counted:     \", shelf.added)"}
]}
```

```
ana@laptop:~/patterns/composition$ python3 counting.py
on the shelf: 4
counted:      4
```

Correto, e agora o filho depende de essa chamada a `self` continuar lá. Alguns meses depois, o autor
de `Shelf` percebe que acrescentar um título por vez é mais lento do que estender a lista de uma
vez. Ele faz uma mudança com a qual todos os testes dele concordam:

```python
# shelf.py
class Shelf:
    def __init__(self):
        self._titles: list[str] = []

    def add(self, title: str) -> None:
        self._titles.append(title)

    def add_all(self, titles: list[str]) -> None:
        self._titles.extend(titles)

    def __len__(self) -> int:
        return len(self._titles)
```

```
ana@laptop:~/patterns/composition$ python3 counting.py
on the shelf: 4
counted:      1
```

Nada em `counting.py` mudou, e o relatório agora erra por três. A prateleira continua com quatro
títulos, então um teste de `Shelf` passa, e nenhum erro aparece em lugar nenhum. **Duas mudanças
corretas, feitas por duas pessoas que nunca conversaram, produziram um número errado e mais nada.**

## Por que o pai não consegue proteger você

O autor de `Shelf` não fez nada de errado segundo regra alguma que pudesse conhecer. Para não
quebrar `CountingShelf`, ele teria de saber que a classe existe, e saber de qual das suas chamadas
internas a `self` ela dependia. Uma classe usada por um time dá para entender inteira; uma classe
herdada por toda uma base de código, ou publicada numa biblioteca, tem filhos que o autor nunca vai
ler.

Só existem duas saídas honestas. O pai pode **documentar o uso que faz de si mesmo** como parte do
contrato ("`add_all` chama `add` para cada título") e nunca mais mudar isso, que é o que fazem as
classes projetadas para extensão. Ou o filho pode parar de herdar e **guardar** uma prateleira,
para que o funcionamento interno do pai deixe de ser problema dele. A seção depois da próxima faz a
segunda coisa, e ela conserta as duas execuções acima de uma vez.

O `HashSet` do Java tem exatamente essa armadilha, e Joshua Bloch o usou no *Effective Java* para
defender o mesmo ponto: `HashSet` herda `addAll` de `AbstractCollection`, que chama `add` uma vez
por elemento, então uma subclasse que conta nos dois métodos conta cada elemento duas vezes. Go não
tem como ter esse problema, porque os métodos de uma struct embutida nunca chamam de volta a struct
que a embute.
