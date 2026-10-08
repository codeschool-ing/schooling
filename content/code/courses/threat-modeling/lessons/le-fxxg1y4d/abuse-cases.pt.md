---
title: Casos de abuso
version: 1
---

Um caso de uso diz o que alguém faz com o sistema para conseguir o que quer: *um paciente agenda
uma sessão*. Um **caso de abuso**, ou **caso de mau uso**, é a mesma funcionalidade vista por alguém
que quer algo que ela não foi feita para dar: *um paciente agenda e cancela em sequência para que a
Vereda pague cem mensagens de texto*. A ideia foi publicada por Guttorm Sindre e Andreas Opdahl no
começo dos anos 2000, e Gary McGraw a tornou parte padrão de construir com segurança. É a ponte mais
útil que existe entre um modelo de ameaças e quem escreve funcionalidades, porque **é escrita na
língua que essas pessoas já usam.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" data-fig=\"l07-misuse\" aria-label=\"Um diagrama de casos de uso com casos de abuso. O paciente executa agendar uma sessão e receber lembrete. Um abusador executa dois casos de abuso, desenhados escuros: agendar e cancelar em sequência, que ameaça receber lembrete inundando de SMS, e ler o exame de outro paciente, que ameaça ver os meus exames. Dois casos de uso de mitigação, desenhados com borda verde: limitar agendamentos por conta por hora, que mitiga a sequência, e conferir que o exame pertence ao paciente logado, que mitiga o segundo.\"><defs><marker id=\"l07-misuse-tm-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l07-misuse-tm-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"15.0\" y=\"83.0\" width=\"90.0\" height=\"34.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"60.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Paciente</text><rect x=\"615.0\" y=\"143.0\" width=\"90.0\" height=\"34.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"660.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Abusador</text><ellipse cx=\"250\" cy=\"60\" rx=\"88\" ry=\"24\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.6\"></ellipse><text x=\"250.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">agendar uma sessão</text><ellipse cx=\"250\" cy=\"140\" rx=\"88\" ry=\"24\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.6\"></ellipse><text x=\"250.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">receber lembrete</text><ellipse cx=\"250\" cy=\"220\" rx=\"88\" ry=\"24\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.6\"></ellipse><text x=\"250.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">ver os meus exames</text><ellipse cx=\"480\" cy=\"110\" rx=\"88\" ry=\"24\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></ellipse><text x=\"480.0\" y=\"103.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">agendar e cancelar</text><text x=\"480.0\" y=\"116.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">em sequência</text><ellipse cx=\"480\" cy=\"230\" rx=\"88\" ry=\"24\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></ellipse><text x=\"480.0\" y=\"223.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">ler o exame de</text><text x=\"480.0\" y=\"236.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">outro paciente</text><ellipse cx=\"480\" cy=\"30\" rx=\"88\" ry=\"24\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></ellipse><text x=\"480.0\" y=\"23.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">limitar agendamentos</text><text x=\"480.0\" y=\"36.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">por conta por hora</text><ellipse cx=\"250\" cy=\"280\" rx=\"88\" ry=\"24\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></ellipse><text x=\"250.0\" y=\"273.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">conferir que o exame é</text><text x=\"250.0\" y=\"286.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">do paciente logado</text><path d=\"M105.0 95.0 L162.0 64.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M105.0 105.0 L162.0 136.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M100.0 117.0 L165.0 210.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M615.0 155.0 L568.0 120.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M615.0 168.0 L568.0 222.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M392.0 118.0 L338.0 134.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l07-misuse-tm-ah-amber)\"></path><text x=\"372.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--amber)\">ameaça</text><path d=\"M392.0 228.0 L338.0 222.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l07-misuse-tm-ah-amber)\"></path><text x=\"366.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--amber)\">ameaça</text><path d=\"M480.0 54.0 L480.0 86.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l07-misuse-tm-ah-phosphor)\"></path><text x=\"488.0\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--phosphor)\">mitiga</text><path d=\"M338.0 268.0 L420.0 248.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l07-misuse-tm-ah-phosphor)\"></path><text x=\"392.0\" y=\"272.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--phosphor)\">mitiga</text></svg>", "caption": "Um caso de abuso fica na mesma figura que a funcionalidade que ele ataca, para quem é dono da funcionalidade enxergá-lo."}
```

A notação acrescenta três coisas a um diagrama de casos de uso comum:

- um **abusador**, desenhado como um ator, representando um dos atores da seção anterior;
- **casos de abuso**, desenhados como ovais escuras, cada uma algo que o abusador faz;
- duas relações: um caso de abuso **ameaça** um caso de uso, e um caso de uso de **mitigação**, uma
  funcionalidade acrescentada por causa da ameaça, mitiga o caso de abuso.

A última é o ponto. Uma mitigação desenhada como caso de uso é uma funcionalidade com dono, lugar
no backlog e critérios de aceite, e não uma nota de segurança que ninguém agenda.

### Escrevendo um

Um caso de abuso é uma história curta em quatro partes, que são a ameaça da aula 3 contada pelo lado
do ator:

| parte | exemplo |
|---|---|
| **o ator** | um paciente logado |
| **o que ele faz, nos termos da própria funcionalidade** | abre "meus exames" e muda o número do exame no endereço |
| **o que ele consegue** | o laudo do exame de outro paciente |
| **o que o sistema deveria fazer** | responder como se o exame não existisse, e registrar a tentativa |

A quarta linha é o que faz de um caso de abuso mais que uma ameaça. Ela diz como é o *certo*, e
essa frase já é metade de um requisito. A aula 8 termina o trabalho.

### De onde eles vêm

De três lugares, mais ou menos nesta ordem de rendimento:

1. **Cada caso de uso, cruzado com cada ator.** "Um paciente agenda uma sessão" perguntado ao
   testador de senhas vazadas, à pessoa próxima de um paciente e à recepcionista curiosa dá três
   casos de abuso diferentes.
2. **Cada ponto de entrada da aula 6** que qualquer um alcança.
3. **O que aconteceu em outros lugares**: as notas do estágio 4 da carla, relatos de incidentes em
   clínicas parecidas, as reclamações que a recepção recebe.
