---
title: Vermelho, verde, refatorar
version: 1
---

**O desenvolvimento guiado por testes, TDD, é um jeito de escrever código em que o teste vem primeiro: escreva um
teste pequeno que falha, escreva só o código suficiente para ele passar, depois arrume o código enquanto o teste o
mantém honesto.** Kent Beck o descreveu em *Test-Driven Development: By Example* em 2002, fazendo-o crescer a
partir da programação com o teste antes do XP. Os três passos têm cores, tiradas do que o executor de testes
mostra:

1. **vermelho**: escreva um teste para uma coisa pequena que o código ainda não faz, e rode. Ele precisa falhar. Um
   teste que passa antes de o código existir não está testando nada.
2. **verde**: escreva o mínimo de código que faz o teste passar. Não o código elegante, não o código geral: o
   mínimo.
3. **refatorar**: melhore o código, os nomes, a forma, a duplicação, sem mudar o que ele faz. Rode os testes depois
   de cada mudança; eles dizem se o comportamento mexeu.

Depois o próximo teste, e outra volta. Um ciclo leva minutos. Uma funcionalidade é dezenas de ciclos.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 600 250\" role=\"img\" data-fig=\"l15-cycle\" aria-label=\"O ciclo do TDD como três caixas em laço. Vermelho: escreva um teste que falha. Verde: o mínimo de código que passa. Refatorar: arrumar, com os testes ainda verdes. Uma seta sai de refatorar e volta ao vermelho para o próximo teste. No meio: um ciclo leva minutos.\"><defs><marker id=\"qa-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"225.0\" y=\"12.0\" width=\"160.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"305.0\" y=\"33.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">vermelho</text><text x=\"305.0\" y=\"46.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">escreva um teste que falha</text><rect x=\"400.0\" y=\"150.0\" width=\"160.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"480.0\" y=\"171.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">verde</text><text x=\"480.0\" y=\"184.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o mínimo de código que passa</text><rect x=\"50.0\" y=\"150.0\" width=\"160.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"171.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">refatorar</text><text x=\"130.0\" y=\"184.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">arrumar, testes ainda verdes</text><path d=\"M385.0 50.0 L470.0 148.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><path d=\"M398.0 190.0 L212.0 190.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><path d=\"M130.0 148.0 L223.0 50.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><rect x=\"245.0\" y=\"100.0\" width=\"120.0\" height=\"40.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"305.0\" y=\"113.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um ciclo:</text><text x=\"305.0\" y=\"126.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">minutos</text></svg>", "caption": "Vermelho, verde, refatorar, e de novo. Uma funcionalidade é dezenas destes."}
```

## Por que o teste vem primeiro

Escrever o teste primeiro parece um detalhe de ordem, e muda três coisas.

- **Sabe-se que o teste consegue falhar.** Ele foi visto vermelho antes de o código existir. Um teste escrito
  depois do código nunca foi visto falhando, e um teste que não consegue falhar, por um erro de digitação ou uma
  asserção errada, parece exatamente um teste que passa.
- **O código ganha forma sendo usado.** Escrever o teste quer dizer escrever a chamada antes de a função existir,
  então a primeira pessoa a usar a interface do código é quem o escreve, antes de ser tarde para mudá-la.
- **Cada linha de código tem um motivo.** Verde quer dizer o mínimo de código; qualquer coisa a mais não tem teste
  pedindo por ela. O código que acaba existindo é o código de que algum exemplo precisou.

## Para que serve o TDD, e para que não serve

O TDD é antes de tudo um jeito de **projetar** código. As verificações que se acumulam são um efeito colateral
valioso: uma suíte de regressão que cresceu um exemplo de cada vez, cada um visto falhando uma vez.

É por isso que o TDD não substitui o teste, e por isso que quem testa num time de TDD ainda tem trabalho. Os testes
de uma suíte de TDD são exemplos em que alguém pensou enquanto escrevia o código. Valem o que os exemplos valem, e
nada mais. Quem desenvolve e não pensa num estudante numa quarta não escreve teste para isso, e a suíte fica verde.

O resto desta aula constrói uma pequena funcionalidade com TDD, no laboratório, um ciclo de cada vez. Você não vai
precisar escrever código neste curso; vai precisar ler um teste e uma função lado a lado, e saber o que cada cor
quer dizer. As aulas 16 e 17 levam o mesmo ciclo um nível acima, a exemplos que a dona do produto consegue ler.
