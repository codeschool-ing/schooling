---
title: Funções de ordem superior e composição
version: 1
---

**Uma função de ordem superior recebe uma função como argumento ou devolve uma.** Python, Java, Go e
TypeScript tratam funções como valores, então isto é menos exótico do que o nome: `sorted(loans,
key=...)` é uma função de ordem superior, e todo callback que você já passou também. O que o estilo
funcional acrescenta é o hábito de montar comportamento combinando funções pequenas, em vez de
escrever uma classe para cada variação.

## Três usos num arquivo

```schooling-example
{"language": "python", "file": "hof.py", "parts": [
 {"code": "# hof.py\nfrom functools import reduce\nfrom typing import Callable\n\nLOANS = [(\"Dom Casmurro\", 4), (\"Central do Brasil\", 15), (\"Iracema\", 0), (\"Cidade de Deus\", 4)]", "note": "Quatro empréstimos como título e dias de atraso, os números do relatório da lição 14."},
 {"code": "\n\ndef per_day(cents: int) -> Callable[[int], int]:\n    def fine(days_late: int) -> int:\n        return days_late * cents\n    return fine", "note": "Uma função que devolve uma função. A `fine` de dentro lembra de `cents` depois que `per_day` já retornou; essa variável lembrada é um *closure*."},
 {"code": "\n\ndef capped(limit: int) -> Callable[[int], int]:\n    return lambda cents: min(cents, limit)", "note": "A mesma ideia escrita como `lambda`: uma função que recebe um valor e nunca o deixa passar de `limit`."},
 {"code": "\n\ndef pipeline(*steps: Callable) -> Callable:\n    return lambda value: reduce(lambda acc, step: step(acc), steps, value)", "note": "Composição: dadas funções, monte a que as aplica em sequência, da esquerda para a direita. `reduce` passa a saída de cada passo para o seguinte."},
 {"code": "\n\nif __name__ == \"__main__\":\n    print(\"most late first:\", [title for title, _ in sorted(LOANS, key=lambda loan: loan[1], reverse=True)])\n    standard = per_day(50)\n    print(\"50 a day:\", [standard(days) for _, days in LOANS])\n    gentle = pipeline(per_day(50), capped(500))\n    print(\"capped at 500:\", [gentle(days) for _, days in LOANS])", "note": "Passar uma função (`key=`), receber uma de volta (`per_day(50)`) e compor duas (`pipeline`). O teto é uma política inventada, aqui para haver algo a compor."}
]}
```

```
ana@laptop:~/patterns/functional$ python3 hof.py
most late first: ['Central do Brasil', 'Dom Casmurro', 'Cidade de Deus', 'Iracema']
50 a day: [200, 750, 0, 200]
capped at 500: [200, 500, 0, 200]
```

A ordenação pôs *Dom Casmurro* antes de *Cidade de Deus*, ambos com quatro dias de atraso, porque a
ordenação do Python é **estável**: itens que comparam como iguais mantêm a ordem original. Quinze
dias a 50 centavos dão 750, e a política com teto transforma isso em 500 sem que nenhuma das funções
saiba da outra.

## Strategy sem as classes

Olhe de novo para `per_day(50)` e `capped(500)`. Na lição 6, uma strategy era uma interface com um
método e uma classe por variação. **Quando a interface tem um método só, uma função é a strategy**, e
a classe em volta é cerimônia. Peter Norvig apontou isso em 1996 sobre linguagens dinâmicas: vários
dos padrões clássicos ficam invisíveis, ou do tamanho de uma linha, quando funções são valores. Uma
política de multa é um `Callable[[int], int]`; uma política nova é uma função nova; o código que a
aplica não muda.

A versão com classe ainda tem seu lugar quando a strategy carrega vários métodos relacionados, ou
estado que um leitor deveria ver com nome, ou precisa ser achada por um contêiner de injeção de
dependência. Um método e nenhum estado é uma função.

## Composição, e a ordem dela

A matemática escreve a composição da direita para a esquerda: *(f ∘ g)(x)* é *f(g(x))*, então *g*
roda primeiro. O `pipeline` acima roda da esquerda para a direita, na ordem de leitura, que é o que
fazem os pipes do Unix, as cadeias de métodos e a maioria das bibliotecas de processamento de dados.
Nenhuma está errada; saiba qual uma biblioteca quer dizer antes de confiar nela.
`pipeline(per_day(50), capped(500))` e `pipeline(capped(500), per_day(50))` são políticas
diferentes: a segunda limita os *dias* a 500 antes de multiplicar, e na prática não limita nada.

Onde a composição ajuda é em manter cada passo pequeno o bastante para ser testado sozinho e
reaproveitado. Onde atrapalha é na depuração: um stack trace por quatro lambdas montadas por
`reduce` diz menos que um laço com variáveis nomeadas. **Dê nome aos passos que significam algo no
domínio**, como `per_day` e `capped` fazem, e o resultado composto continua legível.
