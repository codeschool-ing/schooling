---
title: O contrato da API
version: 1
---

**Cada campo que uma versão antiga do app lê é uma promessa que o servidor cumpre enquanto aquela
versão estiver na janela de suporte.** Ninguém a assinou. Ela foi feita no dia em que a versão saiu,
pelo código que interpreta a resposta, e esse código não pode mais ser mudado.

## As sessões do planner, como a 1.3.1 as lê

O planner pede ao servidor as sessões de estudo da semana. Desde a 1.3.1, a resposta tem esta cara:

```json
[
  { "id": "s-101", "course": "statistics", "minutes": 25, "day": "2026-10-12", "status": "done" },
  { "id": "s-102", "course": "python", "minutes": 40, "day": "2026-10-13", "status": "planned" }
]
```

O app 1.3.1 lê `minutes` como número e soma para o total da semana, lê `day` para pôr a sessão na
coluna certa, e desenha um visto quando `status` é `"done"` e um círculo vazio quando é `"planned"`.
Esses três usos são o contrato, diga o que disser a documentação do próprio servidor.

## Mudanças que cumprem a promessa, e mudanças que a quebram

| Mudança no servidor | A 1.3.1, já instalada |
| --- | --- |
| Acrescentar um campo, `seconds` | ignora, se o parser dela ignora campos que não conhece |
| Renomear `minutes` para `durationMinutes` | não acha `minutes`; o total da semana sai errado ou a tela falha |
| Mudar `minutes` de `25` para `"25"` | soma textos: `"25" + "40"` dá `"2540"` em JavaScript |
| Acrescentar um status, `"skipped"` | encontra um valor que não tem como desenhar |
| Tirar um campo da sessão que ninguém lê | nada, se ninguém lê mesmo |
| Tornar obrigatório um campo da requisição | a requisição de toda versão antiga é recusada |

**As mudanças seguras são acréscimos, e só os acréscimos que as versões antigas conseguem ignorar.**
Renomear é uma remoção e um acréscimo ao mesmo tempo, e o que quebra é a remoção. Mudar o tipo é uma
remoção disfarçada. Um valor novo num campo que já existe é o que parece acréscimo e não é, porque o
código antigo já decidiu o que fazer com cada valor que esperava.

## A metade do cliente: o leitor tolerante

Quem cumpre a promessa é o servidor; o app a deixa mais barata de cumprir, lendo com tolerância desde
a primeira versão:

- **Ignore os campos que você não conhece.** Um parser rígido que recusa um campo desconhecido
  transforma todo acréscimo numa mudança que quebra.
- **Dê um padrão ao que falta.** Um campo ausente recebe um valor que não faz mal, e a tela ainda
  desenha.
- **Tenha um caminho para o valor que você nunca viu.** Um `status` que não é `"done"` nem
  `"planned"` é desenhado como algo neutro, e não como um crash. Em Kotlin, um `when` sobre uma
  string precisa de um `else`; em Swift, um `switch` sobre um enum decodificado precisa de um caso
  de reserva para a decodificação sobreviver; e num app React Native o `default:` de um `switch` é a
  mesma decisão.

Nada disso deixa o servidor quebrar o contrato; só faz os erros do servidor ficarem menores. A
configuração remota da lição 19 é lida do mesmo jeito, pelo mesmo motivo.

## Dois jeitos de fazer uma mudança que não é acréscimo

1. **Versionar o endpoint.** `/v2/sessions` responde com o formato novo e `/v1/sessions` mantém o
   antigo até a última versão que o chama sair da janela. Dois formatos são dois caminhos de código
   para manter funcionando, e esse é o custo.
2. **Expandir, depois contrair.** Acrescente `seconds` ao lado de `minutes` e mande os dois; lance um
   app que lê `seconds`; espere até toda versão da janela lê-lo; só então pare de mandar `minutes`.
   Leva meses e mantém um endpoint só.

Os dois terminam igual: um formato antigo só é removido quando a contagem da primeira seção diz que
ninguém na janela ainda o lê. A próxima seção é o teste que segura o servidor a isso até lá.
