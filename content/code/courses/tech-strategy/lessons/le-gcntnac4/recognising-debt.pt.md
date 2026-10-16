---
title: Distinguindo dívida de todo o resto
version: 1
---

Peça a um time de engenharia a sua dívida técnica e muitas vezes você recebe um rótulo no
rastreador com uma lista longa embaixo: um bug do ano passado, uma biblioteca duas versões atrás, um
módulo que alguém acha feio, uma funcionalidade que produto nunca priorizou. **Uma lista assim não
tem como ser precificada, porque a maior parte dela não é dívida.** Antes de uma dívida ser
classificada, como fez a seção anterior, ou precificada, como faz a aula 5, ela precisa ser separada
das outras coisas que usam o nome dela.

## Duas perguntas

Uma parte do sistema é dívida técnica, no sentido que este curso usa, quando a resposta a estas duas
perguntas é sim.

1. Você consegue nomear um desenho melhor agora? Não "isto está ruim", mas "se segurássemos os
   assentos com um registro de reserva de vida curta em vez de uma trava de linha, a fila sumiria".
   Se ninguém sabe dizer qual é o desenho melhor, ainda não há nada a pagar.
2. O desenho atual custa algo cada vez que alguém muda esta área? Uma mudança mais longa, uma
   revisão a mais, um contorno, um incidente. Isso é juro, e sem ele não há nada a ganhar pagando.

As duas respostas separam tudo o que está na lista longa em quatro grupos.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 345\" role=\"img\" aria-label=\"Uma grade de dois por dois. No alto: dá para nomear um desenho melhor agora, sim ou não. Na lateral: cada mudança custa algo, sim ou não. Sim e sim, em destaque: dívida com juros, registrar, a aula 5 precifica; as quatro dívidas da Coreto. Sem desenho melhor mas com custo: o próprio problema, testes e documentação melhores; regras de meia-entrada. Com desenho melhor mas sem custo: dívida que não cobra nada, deixar; as telas de cadastro de casas. Não e não: código que funciona, nada a fazer.\"><text x=\"455\" y=\"26\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Dá para nomear um desenho melhor agora?</text><text x=\"325.0\" y=\"60\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">sim</text><text x=\"585.0\" y=\"60\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">não</text><text x=\"85\" y=\"187\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Cada</text><text x=\"85\" y=\"203\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">mudança</text><text x=\"85\" y=\"219\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">custa algo?</text><text x=\"172\" y=\"142.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">sim</text><text x=\"172\" y=\"272.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">não</text><rect x=\"200\" y=\"78\" width=\"250\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"325.0\" y=\"112\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">dívida com juros</text><text x=\"325.0\" y=\"138\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">registrar; a aula 5 precifica</text><text x=\"325.0\" y=\"168\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">as quatro dívidas da Coreto</text><rect x=\"460\" y=\"78\" width=\"250\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"585.0\" y=\"112\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">o próprio problema</text><text x=\"585.0\" y=\"138\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">testes e documentação melhores</text><text x=\"585.0\" y=\"168\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">regras de meia-entrada</text><rect x=\"200\" y=\"208\" width=\"250\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"325.0\" y=\"242\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">dívida que não cobra nada</text><text x=\"325.0\" y=\"268\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">deixar, e olhar de novo depois</text><text x=\"325.0\" y=\"298\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">as telas de cadastro de casas</text><rect x=\"460\" y=\"208\" width=\"250\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"585.0\" y=\"242\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">código que funciona</text><text x=\"585.0\" y=\"268\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">nada a fazer</text></svg>", "caption": "As duas perguntas que separam a dívida de todo o resto numa lista de dívidas. Só a caixa do alto à esquerda vai para o registro."}
```

**Sim e sim é dívida com juros**, e vai para o registro. As quatro da Coreto se encaixam: cada uma
tem um desenho que o time sabe descrever, e cada uma cobra algo toda vez que um time trabalha perto
dela.

**Um desenho melhor mas nenhum custo é dívida que não cobra nada.** As telas administrativas da
Coreto para cadastrar uma casa de shows nova foram feitas num estilo que ninguém escolheria hoje, e
mudam tão raramente que o estilo quase não custa nada. Pagar esse principal não compraria nada de
volta. Deixe como está, e olhe de novo se as telas começarem a mudar com frequência.

**Um custo mas nenhum desenho melhor é o próprio problema.** As regras brasileiras de meia-entrada
para estudantes e outros públicos variam entre estados e mudam com a lei, então toda mudança no
código de preços da Coreto é lenta e exige cuidado. Ninguém sabe nomear um desenho que torne a lei
simples. Essa dificuldade pertence ao domínio; chamá-la de dívida manda um time atrás de uma
refatoração que não existe.

**Não e não** é código comum que funciona, seja o que for que alguém ache do estilo dele.

## O que usa o nome emprestado

Cinco coisas aparecem nas listas de dívida com mais frequência e são outra coisa.

| na lista | o que é de fato | para onde vai |
|---|---|---|
| um bug | comportamento errado | a fila de bugs, corrigido como qualquer outro |
| uma funcionalidade que falta | trabalho de produto que ninguém priorizou | o roadmap de produto |
| código num estilo de que alguém não gosta | uma preferência | lugar nenhum, a menos que também cobre juros |
| uma dependência fora do período de suporte | um risco com data marcada | manter as luzes acesas, como na aula 2; a aula 6 trata de uma base que está indo embora |
| um domínio difícil | o próprio problema | testes e documentação melhores, não uma refatoração |

**O bug é o impostor mais comum.** "O checkout mostra a taxa errada para meia-entrada" é um bug mesmo
que o código em volta esteja bagunçado. Corrigi-lo não paga nada, e pô-lo na lista de dívidas faz a
lista parecer maior do que a dívida é.

## Onde procurar a dívida de verdade

Os juros deixam rastros, e dá para achar a dívida seguindo-os em vez de ler código.

- Mudanças numa área demoram mais que mudanças parecidas em outros lugares. Acrescentar um campo à
  reserva de assento levou muito mais tempo ao Checkout que acrescentar um campo em qualquer outro
  ponto do checkout.
- Uma mudança exige edições em muitos lugares. Todo layout novo de casa de shows na Coreto exige uma
  mudança dentro do gerador de PDF, além do próprio layout.
- O mesmo tipo de incidente volta. Abertura após abertura, a análise do incidente apontava esperas
  por trava nas tabelas de reserva.
- As pessoas contornam. Os engenheiros rodam de novo a suíte ponta a ponta até ela ficar verde, e
  alguns pararam de ler as falhas dela.
- Tudo espera por uma pessoa. Cada mudança de schema no `coreto-core` esperava pelo único engenheiro
  de Dados que sabia quais relatórios liam quais tabelas da réplica.

Cada rastro aponta para uma área. As duas perguntas decidem, então, se o que há nessa área é dívida.

## Pondo no papel

O resultado é um **registro de dívidas**: uma linha por dívida, curto o bastante para as pessoas
lerem. O do Davi para a Coreto tinha quatro linhas:

| dívida | onde | caixa | o que custa a cada vez | quem a conhece melhor |
|---|---|---|---|---|
| travamento das reservas de assento | módulo de reservas | prudente, inadvertida | incidentes nas aberturas; mudanças lentas e arriscadas nas reservas | time de Reservas |
| gerador de ingressos em PDF | emissão de ingressos | prudente, deliberada | uma mudança de código para cada layout novo de ingresso | Bilheteria |
| suíte ponta a ponta instável | pipeline de testes | imprudente, deliberada | novas execuções a cada merge; falhas em que ninguém confia | Plataforma |
| réplica de relatórios | Dados | imprudente, inadvertida | relatórios quebrados depois de mudanças de schema; um revisor em cada mudança | time de Dados |

A coluna de custo está em palavras, de propósito. **A aula 5 a transforma em horas por sprint e em
reais**, e é ali que as quatro linhas deixam de ser igualmente sérias.

Dois hábitos mantêm um registro útil. O primeiro é **mantê-lo curto**: quatro dívidas com que os
times concordam valem mais que cem tickets que ninguém lê, e uma dívida ganha sua linha passando nas
duas perguntas. O segundo é manter a evidência ao lado de cada linha, um link para os incidentes ou
para as mudanças lentas, para que a linha possa ser contestada e defendida. Um registro é a entrada
de uma discussão de orçamento, e uma entrada que não pode ser conferida não sobrevive a uma.
