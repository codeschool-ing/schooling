---
title: Três trabalhos que um método de string já faz
version: 2
---

A primeira pergunta sobre uma expressão regular é se você precisa de uma.

## Os três

```python
"error" in line                       # not re.search(r"error", line)
line.startswith("2026-")              # not re.match(r"2026-", line)
line.split(",")                       # not re.split(r",", line)
```

Cada padrão acima funciona, é mais lento, e é mais difícil de ler que o método ao lado. O
`replace` entra na lista também: trocar uma string fixa por outra string fixa não é trabalho para
o `re.sub`.

**O teste é se há VARIAÇÃO no que você está procurando.** Uma string fixa não tem nenhuma, e um
método de string é a resposta honesta.

## Onde um padrão ganha o lugar dele

- uma linha de log com carimbo de tempo, nível e mensagem
- um telefone escrito de seis jeitos diferentes
- toda URL numa página de texto
- uma data que alguém digitou, num de três formatos
- um campo que é dígitos, ou é vazio, ou é `N/A`

Essas são formas com variação dentro, e descrever a variação é exatamente o que esta linguagem
faz.

## HTML, que é a resposta errada famosa

```python
re.findall(r"<div>(.*?)</div>", html)     # no
```

Funciona no exemplo e falha com um `<div>` dentro de um `<div>`. Estruturas aninhadas não são uma
forma que uma expressão regular consiga descrever — isso é um fato sobre a linguagem, e não um
desafio, e nenhuma esperteza conserta.

O mesmo vale para qualquer coisa com aninhamento ou regras de aspas próprias: JSON, CSV,
código-fonte, XML. Cada um tem um analisador, e as aulas 9 e 21 têm os dois de que você vai
precisar.

## E a regra de bolso sobre comprimento

**Um padrão que não cabe numa linha é um analisador que alguém escreveu sem querer.** Quebre o
trabalho em passos — divida a linha, e depois case o pedaço — e todo passo continua sendo algo que
uma pessoa consegue conferir.
