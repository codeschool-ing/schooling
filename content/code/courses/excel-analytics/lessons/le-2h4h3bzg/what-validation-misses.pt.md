---
title: O que a validação não vê
version: 1
---

**A validação confere uma coisa só: um valor digitado numa célula e confirmado com Enter.** Tudo o
mais que muda uma célula passa por ela sem um pio, e uma planilha cheia de regras ainda pode guardar
valores que desrespeitam todas elas. Conhecer as brechas é o que impede uma regra de ser confundida
com uma garantia.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 330\" role=\"img\" data-fig=\"l08-paths\" aria-label=\"Quatro caminhos pelos quais um valor chega a uma célula validada. Só o primeiro, digitar e apertar Enter, passa pela regra, que recusa, avisa ou informa. Colar troca o valor e a regra juntos. A nova resposta de uma fórmula e um valor que já estava lá quando a regra foi criada chegam sem conferência. Circular Dados Inválidos, embaixo, confere cada célula contra a regra quando você pede.\"><rect x=\"330.0\" y=\"32.0\" width=\"90.0\" height=\"66.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"375.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--amber)\">a regra</text><rect x=\"590.0\" y=\"30.0\" width=\"140.0\" height=\"200.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"660.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">a célula</text><text x=\"30.0\" y=\"55.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">digitado, e Enter</text><path d=\"M250.0 55.0 L326.0 55.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M326.0 55.0 L318.0 51.0 L318.0 59.0 Z\" fill=\"var(--amber)\" stroke=\"none\"></path><path d=\"M420.0 55.0 L586.0 55.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M586.0 55.0 L578.0 51.0 L578.0 59.0 Z\" fill=\"var(--amber)\" stroke=\"none\"></path><text x=\"375.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Parar · Aviso</text><text x=\"375.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">· Informações</text><text x=\"30.0\" y=\"105.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">colado com Ctrl+V</text><path d=\"M250.0 105.0 L584.0 105.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M581.0 105.0 L586.0 105.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M586.0 105.0 L578.0 101.0 L578.0 109.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><text x=\"598.0\" y=\"105.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">regra trocada</text><text x=\"30.0\" y=\"155.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a resposta de uma fórmula muda</text><path d=\"M250.0 155.0 L584.0 155.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M581.0 155.0 L586.0 155.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M586.0 155.0 L578.0 151.0 L578.0 159.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><text x=\"598.0\" y=\"155.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">sem conferência</text><text x=\"30.0\" y=\"205.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">já estava lá antes da regra</text><path d=\"M250.0 205.0 L584.0 205.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M581.0 205.0 L586.0 205.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M586.0 205.0 L578.0 201.0 L578.0 209.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><text x=\"598.0\" y=\"205.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">sem conferência</text><text x=\"598.0\" y=\"55.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">conferido</text><path d=\"M30.0 262.0 L730.0 262.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"30.0\" y=\"285.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">Circular Dados Inválidos confere cada célula contra a regra, mas só quando você pede,</text><text x=\"30.0\" y=\"303.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">e não muda nada: desenha um círculo em volta de cada valor que a desrespeita.</text></svg>", "caption": "A validação vigia uma porta, a digitação. Uma colagem, uma fórmula recalculada e os dados que já estavam na planilha entram pelas outras, e Circular Dados Inválidos é como achá-los."}
```

## Quatro jeitos de passar pela regra

- **Colar.** **Ctrl+V** numa célula validada troca o que a célula guarda *e a regra dela*: o valor
  chega sem conferência e a célula fica sem regra depois. **Colar Especial › Valores** mantém a
  regra, e mesmo assim não confere o valor colado. Uma coluna preenchida colando de outro lugar não
  está protegida pelas regras dela.
- **Valores que já estavam lá.** Uma regra vale para o que for digitado daqui em diante. Pôr uma
  regra numa coluna que já tem dados não confere nenhum deles.
- **Fórmulas.** Uma célula cujo valor vem de uma fórmula não é conferida quando a resposta da fórmula
  muda.
- **Tirar a regra.** Qualquer um que abra a janela pode escolher **Limpar Tudo** (**Clear All**). A
  validação orienta quem digita; ela não impede quem resolve contorná-la. A aula 17 protege uma
  planilha para que as regras fiquem onde estão.

## Achar o que passou: Circular Dados Inválidos

O Excel ainda consegue mostrar quais células desrespeitam suas regras, sempre que você pede.
Experimente em dados que existiam antes de qualquer regra. Suponha que o Café Serra decida que uma
venda acima de 15 sacos precisa da aprovação de um gerente:

1. Selecione a coluna `Bags` da tabela `Sales`, E2:E109.
2. **Dados › Validação de Dados**, **Número inteiro**, **está entre** `1` e `15`, **OK**. Nada muda
   na planilha, porque nada foi digitado.
3. Clique na setinha ao lado de **Validação de Dados** e escolha **Circular Dados Inválidos**
   (**Circle Invalid Data**).

Um círculo vermelho aparece em volta de cada célula que desrespeita a regra. São quatro. Uma fórmula
confirma a contagem e mostra que os círculos não deixaram nenhuma de fora:

```localised
=CONT.SE(Sales[Bags]; ">15")
```

responde **4**: duas vendas de 16 sacos, uma de 17 e uma de 20. Os círculos são uma visão, não uma
mudança: **Limpar Círculos de Validação** (**Clear Validation Circles**), na mesma setinha, os
remove, e editar uma célula circulada para um valor válido remove o círculo dela.

Agora tire a regra de novo, porque `Sales` é o registro do curso do que aconteceu, e as vendas acima
de 15 sacos aconteceram: com E2:E109 ainda selecionado, **Dados › Validação de Dados › Limpar Tudo**,
**OK**.

## Deixar a pasta como as próximas aulas esperam

Apague as linhas de teste que você digitou em `NewSales`, para a tabela voltar a ter uma linha vazia,
e mantenha a planilha com as regras e os dois nomes. Nada em `New sales` chega a `Sales`: as aulas
depois desta calculam a partir de `Sales`, e os números delas contam com as 108 linhas dela.
