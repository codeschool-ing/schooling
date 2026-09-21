---
title: `==`, `>=`, `~=`, e o que um número de versão promete
version: 1
---

```sh
MAIOR . MENOR . CORREÇÃO
  2   .  31   .     0
```

Versionamento semântico é uma **promessa que o autor faz**: uma versão de correção conserta algo,
uma versão menor acrescenta algo sem quebrar o que existia, e uma versão maior tem permissão de
quebrar coisas. Tudo abaixo se apoia nessa promessa ser cumprida, e na maior parte do tempo ela é.

## Os especificadores, resolvidos num ambiente novo

```sh
requests==2.31.0    →  2.31.0
requests~=2.31.0    →  2.31.0
requests~=2.31      →  2.34.2
requests>=2.26      →  2.34.2
```

Quatro pedidos, três respostas diferentes, rodados esta tarde contra o índice de verdade.

- **`==2.31.0`** — exatamente essa. Nenhuma surpresa e nenhum conserto também.
- **`~=2.31.0`** — "versão compatível": **o último componente pode se mover**, então isso quer
  dizer `>=2.31.0, ==2.31.*`. Versões de correção, nada além.
- **`~=2.31`** — a mesma regra com um componente a menos, então a versão *menor* pode se mover:
  `>=2.31, ==2.*`. É por isso que resolveu três versões menores à frente.
- **`>=2.26`** — qualquer coisa mais nova, inclusive uma versão maior que tinha permissão de
  quebrar você.

**`~=` é o que vale entender**, e a diferença entre as duas formas dele é a quantidade de
componentes que você escreveu, que é fácil de digitar errado e não produz erro.

## Os outros dois

```sh
requests>=2.26,<3        uma faixa, escrita por extenso
requests!=2.32.0         tudo menos uma versão que saiu quebrada
```

Uma vírgula é um **e**. `>=2.26,<3` é a forma explícita de `~=2.26` e vale preferir justamente por
não poder ser mal lida.

## O que um especificador não fixa

```sh
$ python -m pip show requests
Requires: certifi, charset-normalizer, idna, urllib3
```

```sh
o requests 2.31.0 pede:
  urllib3 (<3, >=1.21.1)
  charset-normalizer (<4, >=2)
  certifi (>=2017.4.17)
```

Fixar `requests==2.31.0` exatamente fixa **um** pacote. O `urllib3` pode ser qualquer coisa abaixo
de 3, o `certifi` qualquer coisa desde 2017. Duas instalações do mesmo `requirements.txt`, com um
mês de diferença, podem produzir código diferente — que é a próxima seção.
