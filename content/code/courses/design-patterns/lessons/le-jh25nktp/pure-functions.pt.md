---
title: "Funções puras: mesmos argumentos, mesma resposta, nada mais"
version: 1
---

**Programação funcional costuma ser entendida como uma linguagem: Haskell, Clojure, F#. As ideias
que se pagam numa base de código back-end são menores e portáteis**, e a primeira delas cabe numa
frase. Uma função pura devolve um valor que depende só dos argumentos, e não faz mais nada: não muda
nenhuma variável fora dela, não grava arquivo, não manda mensagem, não lê relógio.

Cada metade da definição exclui algo específico. *Depende só dos argumentos* exclui ler uma global
que outra pessoa pode mudar, a hora atual, um número aleatório ou uma linha do banco. *Não faz mais
nada* exclui escrever em qualquer um deles. O que sobra é uma função que você pode chamar duas vezes
com os mesmos argumentos e obter a mesma resposta, em qualquer ordem, em qualquer dia, sem nada
diferente no mundo depois.

Crie `~/patterns/functional` e trabalhe lá:

```sh
mkdir -p ~/patterns/functional
cd ~/patterns/functional
```

## Dois jeitos de calcular uma multa

```schooling-example
{"language": "python", "file": "pure.py", "parts": [
 {"code": "# pure.py\nfrom datetime import date\n\ndaily_fine = 50\nfines_charged = []", "note": "Duas variáveis de módulo, o tipo de estado compartilhado que uma base de código acumula com os anos."},
 {"code": "\n\ndef charge(due: date, returned: date) -> int:\n    cents = max((returned - due).days, 0) * daily_fine\n    fines_charged.append(cents)\n    return cents", "note": "Impura duas vezes. Ela lê `daily_fine`, que qualquer um pode reatribuir, e acrescenta em `fines_charged`, o que muda o mundo a cada chamada."},
 {"code": "\n\ndef fine(due: date, returned: date, daily: int = 50) -> int:\n    return max((returned - due).days, 0) * daily", "note": "Pura. A taxa diária é um argumento com valor padrão, então toda a entrada da função está na assinatura."},
 {"code": "\n\nif __name__ == \"__main__\":\n    due, back = date(2026, 3, 16), date(2026, 3, 20)\n    print(\"charge:\", charge(due, back), charge(due, back), \"log:\", fines_charged)\n    daily_fine = 100\n    print(\"charge, same arguments:\", charge(due, back))\n    print(\"fine:\", fine(due, back), fine(due, back), fine(due, back, daily=100))", "note": "A linha `daily_fine = 100` representa algum outro módulo mudando a configuração. Ela roda no nível do módulo, então reatribui a global que `charge` lê."}
]}
```

```
ana@laptop:~/patterns/functional$ python3 pure.py
charge: 200 200 log: [200, 200]
charge, same arguments: 400
fine: 200 200 400
```

`charge` foi chamada três vezes com as mesmas duas datas e respondeu 200, 200 e 400, e o registro
cresceu uma entrada por chamada. Para saber o que `charge(due, back)` devolve você precisa dos
argumentos, do valor atual de uma global e de saber que chamá-la tem consequências. `fine` respondeu
200 toda vez, e 400 só quando pediram 400.

## O que a pureza compra

**Uma função pura pode ser entendida pela assinatura e pelo corpo, e por mais nada.** Esse é o
benefício inteiro, e ele aparece de quatro formas práticas:

- testes: o teste é uma chamada e uma asserção, sem preparação e sem limpeza. O `overdue` da lição
  13 era puro por esse motivo;
- raciocínio: `fine(due, back)` pode ser trocado pelo seu valor em qualquer ponto do programa sem
  mudar o que o programa faz. O termo para isso é *transparência referencial*;
- cache: se a resposta depende só dos argumentos, ela pode ser lembrada. `functools.cache` numa
  função impura devolve respostas velhas; numa pura é sempre seguro;
- concorrência: duas threads chamando `fine` ao mesmo tempo não interferem, porque ela não toca em
  nada compartilhado. A lição 18 mostra o que acontece com código que toca.

## Pura por fora

Pureza é uma propriedade do que quem chama consegue observar, não de cada linha. Uma função que
monta uma lista local com `append` e a devolve é pura: a lista nasce dentro da chamada e ninguém mais
a vê mudar. A seção sobre efeitos colaterais nas bordas usa exatamente essa forma. O que quebra a
pureza é a mutação que escapa: mudar um argumento que quem chama ainda guarda, ou qualquer coisa no
nível do módulo.

O Python não confere nada disso. Nem Java, Go ou TypeScript. Haskell confere, pelo sistema de tipos.
Nas quatro linguagens deste curso, pureza é uma disciplina que você mantém e que um revisor enxerga:
uma função que recebe tudo de que precisa como argumento e devolve tudo o que produz é pura à
inspeção.
