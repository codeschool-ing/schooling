---
title: "Vermelho, verde, refatorar: o ciclo"
version: 1
---

**Desenvolvimento guiado por testes costuma ser descrito como "escrever testes", e uma equipe com
uma suíte grande de testes vai dizer que faz TDD. Nenhuma das duas coisas é a ideia.** TDD é um
jeito de escrever o próprio código: o próximo pedacinho de comportamento é escrito primeiro como um
teste que falha, e o código existe para fazer esse teste passar. A suíte no fim é um subproduto.
Kent Beck deu nome e livro ao método, *Test-Driven Development: By Example*, em 2002, e o laço que
ele descreveu tem três passos que nunca mudam de ordem.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l13-cycle\" aria-label=\"O ciclo vermelho-verde-refatorar como três caixas ligadas por setas em laço. Vermelho: escreva um teste para o próximo comportamento e rode; ele precisa falhar, pelo motivo que você espera. Uma seta com o rótulo &quot;um teste falha&quot; leva ao verde: escreva o mínimo de código que passa; uma constante ou uma linha copiada é permitida. Uma seta com o rótulo &quot;todos os testes passam&quot; leva a refatorar: melhore nomes e estrutura, não acrescente comportamento, rode os testes depois de cada movimento. Uma seta com o rótulo &quot;próxima linha da lista&quot; volta ao vermelho. No meio: uma volta leva um ou dois minutos.\"><defs><marker id=\"l13-cycle-dp-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"14.0\" y=\"24.0\" width=\"272.0\" height=\"92.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"150.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">vermelho</text><text x=\"150.0\" y=\"74.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">escreva um teste para o próximo comportamento</text><text x=\"150.0\" y=\"89.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">rode: ele falha, pelo motivo esperado</text><rect x=\"434.0\" y=\"24.0\" width=\"272.0\" height=\"92.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"570.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">verde</text><text x=\"570.0\" y=\"74.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">escreva o mínimo de código que passa</text><text x=\"570.0\" y=\"89.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">vale uma constante ou uma linha copiada</text><rect x=\"224.0\" y=\"216.0\" width=\"272.0\" height=\"92.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--scan)\" stroke-width=\"2\"></rect><text x=\"360.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">refatorar</text><text x=\"360.0\" y=\"266.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">melhore nomes e estrutura, sem comportamento novo</text><text x=\"360.0\" y=\"281.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">rode os testes depois de cada movimento</text><path d=\"M289.0 70.0 L431.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l13-cycle-dp-ah-paper-dim)\"></path><text x=\"360.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">um teste falha</text><path d=\"M570.0 118.0 L570.0 262.0 L499.0 262.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l13-cycle-dp-ah-paper-dim)\"></path><text x=\"578.0\" y=\"190.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">todos os testes passam</text><path d=\"M221.0 262.0 L150.0 262.0 L150.0 118.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l13-cycle-dp-ah-paper-dim)\"></path><text x=\"142.0\" y=\"190.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">próxima linha da lista</text><text x=\"360.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-style=\"italic\" fill=\"var(--amber)\">uma volta: um ou dois minutos</text></svg>", "caption": "O laço nunca muda de ordem. Só o passo verde pode ser desleixado, e só o passo de refatorar pode mudar a estrutura."}
```

**Vermelho.** Escreva um teste para a próxima coisa que o código deve fazer, rode e veja falhar. A
falha tem de ser a que você esperava. Um teste que falha porque o arquivo tem um erro de sintaxe não
disse nada sobre o comportamento.

**Verde.** Escreva o mínimo de código que faz o teste passar. As regras afrouxam aqui de propósito:
uma constante, uma linha copiada, um `if` que só cobre este caso, tudo é permitido. O objetivo é
voltar a uma suíte passando em segundos, não escrever a versão final.

**Refatorar.** Com todos os testes passando, melhore o código que está lá: tire a duplicação que o
passo verde deixou, dê nomes melhores, divida uma função que cresceu. Você não acrescenta
comportamento neste passo, e roda os testes depois de cada mudança. Se ficarem vermelhos, você
desfaz a mudança em vez de depurá-la.

Aí o laço recomeça com o próximo teste. Uma volta leva uns dois minutos. Uma volta que já levou
vinte é sinal de que o passo foi grande demais, e a seção sobre triangulação trata disso.

## Por que a execução vermelha não é formalidade

Um teste que você nunca viu falhar pode não estar testando nada. Ele pode afirmar a coisa errada,
chamar a função errada ou nem rodar, e cada um desses casos parece exatamente um teste passando.
**A execução vermelha é a única evidência de que o teste sabe distinguir código que funciona de
código quebrado.** A próxima seção mostra um arquivo de teste que afirma uma resposta errada e mesmo
assim sai limpo, porque uma única palavra faltando impediu o teste de rodar.

## A lista antes do primeiro teste

Beck começa anotando os testes em que consegue pensar, numa lista simples, e vai riscando. Não é uma
especificação; ela cresce conforme o trabalho mostra o que faltou. Para a calculadora de multas da
biblioteca desta lição, a lista começa com quatro linhas:

- um livro devolvido com três dias de atraso custa 150 centavos;
- um dia de atraso custa 50 centavos;
- devolvido antes do prazo, não custa nada;
- devolvido na data de vencimento, não custa nada.

A ordem importa mais do que parece. O primeiro teste é escolhido para ser fácil de passar e para
forçar uma decisão sobre a interface: como a função se chama, o que recebe, o que devolve. Os casos
difíceis vêm quando a forma já existe.

## O ciclo na sua linguagem

As ferramentas mudam e o laço não. Cada uma das quatro linguagens tem um executor de testes que
imprime uma falha com o valor esperado e o obtido lado a lado, e é só disso que o ciclo precisa.

| linguagem | um teste | rodar com |
|---|---|---|
| Python | `def test_three_days_late(self):` num `unittest.TestCase`, ou uma função solta para o pytest | `python3 -m unittest -v` |
| Java | um método anotado com `@Test`, com o `assertEquals(150, fine(...))` do JUnit 5 | `mvn test` ou `gradle test` |
| Go | `func TestThreeDaysLate(t *testing.T)` num arquivo `_test.go` | `go test` |
| TypeScript | `test("three days late", () => expect(fine(...)).toBe(150))` com Jest ou Vitest | `npx vitest` |

Uma diferença pega quem passa de uma para outra: o `assertEquals` do JUnit recebe o valor esperado
primeiro, enquanto o `assertEqual(first, second)` do Python não tem opinião e imprime
`first != second`. Esta lição sempre põe primeiro o valor que o código devolveu, então uma falha se
lê como *obtido* `!=` *desejado*.
