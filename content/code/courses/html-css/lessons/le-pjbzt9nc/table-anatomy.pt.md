---
title: As partes de uma tabela
version: 1
---

Aqui está a tabela de horários do sebo, escrita com todas as partes que uma tabela pode ter:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Opening hours · Andorinha Books</title>
  </head>
  <body>
    <main>
      <h1>Opening hours</h1>
      <table>
        <caption>Opening hours, from October 2026</caption>
        <thead>
          <tr>
            <th scope="col">Day</th>
            <th scope="col">Opens</th>
            <th scope="col">Closes</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <th scope="row">Monday to Friday</th>
            <td>10 am</td>
            <td>7 pm</td>
          </tr>
          <tr>
            <th scope="row">Saturday</th>
            <td>10 am</td>
            <td>4 pm</td>
          </tr>
          <tr>
            <th scope="row">Sunday</th>
            <td colspan="2">Closed</td>
          </tr>
        </tbody>
      </table>
    </main>
  </body>
</html>
```

De fora para dentro:

- **`<table>`** guarda tudo.
- **`<caption>`** é o título da tabela, e tem de ser a primeira coisa dentro dela. Ele nomeia a tabela, e a árvore o usa como nome acessível dela.
- **`<thead>`** e **`<tbody>`** separam as linhas de cabeçalho dos dados. Uma tabela também pode ter um **`<tfoot>`** para totais. Por padrão não mudam nada visível, e dão a estrutura ao CSS e aos leitores de tela.
- **`<tr>`** é uma linha. Uma tabela se escreve linha por linha; não existe elemento para coluna.
- **`<th>`** é uma célula de cabeçalho e **`<td>`** é uma célula de dado.
- **`scope`** num `<th>` diz se ele encabeça uma **coluna** (`col`) ou uma **linha** (`row`).

E a árvore:

```
ana@laptop:~/site$ probe hours.html tree
- main:
  - heading "Opening hours" [level=1]
  - table "Opening hours, from October 2026":
    - caption: Opening hours, from October 2026
    - rowgroup:
      - row "Day Opens Closes":
        - columnheader "Day"
        - columnheader "Opens"
        - columnheader "Closes"
    - rowgroup:
      - row "Monday to Friday 10 am 7 pm":
        - rowheader "Monday to Friday"
        - cell "10 am"
        - cell "7 pm"
      - row "Saturday 10 am 4 pm":
        - rowheader "Saturday"
        - cell "10 am"
        - cell "4 pm"
      - row "Sunday Closed":
        - rowheader "Sunday"
        - cell "Closed"
```

A tabela é nomeada pela legenda. Todo `<th scope="col">` virou um **columnheader** e todo `<th scope="row">` um **rowheader**, e cada linha é nomeada pelo conteúdo inteiro. É essa estrutura que deixa um leitor de tela anunciar *Saturday, Closes, 4 pm* numa célula, em vez de *4 pm* e mais nada.

## Dois hábitos que valem a pena

**Faça da primeira célula de cada linha um `<th scope="row">` quando ela nomeia a linha.** É o que mais se esquece: as pessoas marcam a linha de cima como cabeçalho e esquecem que *Saturday* encabeça a linha dela exatamente do mesmo jeito.

**Escreva a legenda.** Um título acima da tabela não a nomeia; `<caption>` nomeia. Se o design não tem espaço para uma legenda visível, ela pode ser escondida visualmente com CSS e continuar na árvore, uma técnica que a aula 7 mostra; o hábito começa aqui.
