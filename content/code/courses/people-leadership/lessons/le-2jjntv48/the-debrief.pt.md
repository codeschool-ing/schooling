---
title: Conduzir a conversa de decisão, e calibrar quem entrevista
version: 1
---

A conversa de decisão é onde a evidência de quatro entrevistas vira uma decisão. **Uma boa conversa é
curta, discute evidências e não impressões, e termina com uma decisão e os motivos dela por escrito.**
Uma ruim é um bate-papo sobre se as pessoas gostaram da candidata, vencido por quem falou primeiro.

## A conversa sobre o Lucas

O Lucas era um de seis candidatos na rodada final do Agenda. Quando a conversa começou, as quatro
pessoas entrevistadoras tinham enviado os registros escritos, e todo mundo os tinha lido. As notas
eram:

| quem entrevistou | área | nota | a evidência numa linha |
|---|---|---|---|
| Diego | operar um serviço em produção | 3 | descreveu com clareza um incidente real, incluindo o que mudou depois |
| Yara | escrever e testar código | 4 | escreveu um teste que falhava antes de mexer no bug, explicou cada passo |
| Helena | explicar um trade-off | 2 | exemplo real, mas ficou técnico e não checou o entendimento |
| Renata | trabalhar com outras pessoas | 3 | exemplo específico de discordar numa revisão e mudar de ideia |

## Como a Renata conduziu

**Ela começou pela discordância.** A sala não precisava discutir o 4 da Yara; a evidência era clara e
ninguém duvidava. Precisava discutir o 2 da Helena, porque era a nota mais baixa, num obrigatório, e a
decisão podia depender dela.

**Ela pediu evidência, não opinião.** "O que ele disse que deixou em 2 e não em 3?" A Helena leu das
notas: o Lucas tinha explicado uma decisão de cache a uma colega do suporte em termos de invalidação de
cache e tempo de vida, e quando perguntado como sabia que ela tinha entendido, disse que ela não tinha
feito perguntas.

**Ela perguntou se alguém tinha evidência sobre o mesmo ponto na própria entrevista.** O Diego tinha:
ao descrever o incidente, o Lucas tinha explicado o impacto para os donos de clínica em termos simples,
no que o Diego anotou como "o lembrete saiu uma hora atrasado para uns duzentos pacientes". Não era a
pergunta da Helena, mas era evidência sobre o mesmo obrigatório, e foi para as notas.

**Ela decidiu contra a regra escrita de antemão.** A regra da Caju para essa vaga era: uma proposta
precisa de pelo menos 3 em dois dos três obrigatórios e nenhum 1 em nenhum. O Lucas tinha 3 e 4 em dois
obrigatórios e 2 no terceiro, com alguma evidência contrária. A Renata decidiu fazer a proposta, e
escreveu no registro da decisão que o terceiro obrigatório era a área a apoiar nos primeiros meses
dele, que o plano de integração da aula 18 retomou.

**Ela falou por último**, como a regra da seção anterior pedia, e só depois de todo mundo dizer se
concordava. A Helena disse que ainda tinha dúvidas e que daria 2 de novo; isso também foi para o
registro. Uma decisão com uma discordância registrada é mais honesta do que uma unânime alcançada por
ancoragem.

## Calibrar quem entrevista

A conversa de decisão decide uma candidata. A calibragem olha para muitas. Depois da rodada, a Renata
dispôs todas as notas de todas as pessoas entrevistadoras para os seis candidatos.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l17-calibration\" aria-label=\"Um gráfico de pontos com quatro entrevistadoras nas linhas e notas de 1 a 4 na horizontal. Cada linha tem seis pontos, um por candidata da rodada final. Os pontos da Yara, da Helena e da Renata também se espalham pela parte baixa da escala. Os do Diego ficam só em 3 e 4, e são mais altos que os dos outros para cinco das seis candidatas.\"><path d=\"M160.0 40.0 L160.0 230.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"160.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">1</text><path d=\"M313.3 40.0 L313.3 230.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"313.3\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">2</text><path d=\"M466.7 40.0 L466.7 230.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"466.7\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">3</text><path d=\"M620.0 40.0 L620.0 230.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"620.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">4</text><text x=\"390.0\" y=\"272.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">nota na escala, seis candidatas por linha</text><text x=\"130.0\" y=\"60.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Diego</text><circle cx=\"454.7\" cy=\"60.0\" r=\"5.5\" fill=\"var(--amber)\"></circle><circle cx=\"466.7\" cy=\"60.0\" r=\"5.5\" fill=\"var(--amber)\"></circle><circle cx=\"478.7\" cy=\"60.0\" r=\"5.5\" fill=\"var(--amber)\"></circle><circle cx=\"608.0\" cy=\"60.0\" r=\"5.5\" fill=\"var(--amber)\"></circle><circle cx=\"620.0\" cy=\"60.0\" r=\"5.5\" fill=\"var(--amber)\"></circle><circle cx=\"632.0\" cy=\"60.0\" r=\"5.5\" fill=\"var(--amber)\"></circle><text x=\"130.0\" y=\"110.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Yara</text><circle cx=\"307.3\" cy=\"110.0\" r=\"5.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"620.0\" cy=\"110.0\" r=\"5.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"160.0\" cy=\"110.0\" r=\"5.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"460.7\" cy=\"110.0\" r=\"5.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"472.7\" cy=\"110.0\" r=\"5.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"319.3\" cy=\"110.0\" r=\"5.5\" fill=\"var(--phosphor)\"></circle><text x=\"130.0\" y=\"160.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Helena</text><circle cx=\"295.3\" cy=\"160.0\" r=\"5.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"307.3\" cy=\"160.0\" r=\"5.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"160.0\" cy=\"160.0\" r=\"5.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"319.3\" cy=\"160.0\" r=\"5.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"466.7\" cy=\"160.0\" r=\"5.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"331.3\" cy=\"160.0\" r=\"5.5\" fill=\"var(--phosphor)\"></circle><text x=\"130.0\" y=\"210.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Renata</text><circle cx=\"301.3\" cy=\"210.0\" r=\"5.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"454.7\" cy=\"210.0\" r=\"5.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"313.3\" cy=\"210.0\" r=\"5.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"466.7\" cy=\"210.0\" r=\"5.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"325.3\" cy=\"210.0\" r=\"5.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"478.7\" cy=\"210.0\" r=\"5.5\" fill=\"var(--phosphor)\"></circle></svg>", "caption": "O 3 do Diego e o 3 da Helena podem não significar a mesma coisa. O padrão é invisível de dentro de uma conversa de decisão.", "same": ["Diego", "Helena", "Renata", "Yara"]}
```

Um padrão saltou. As notas do Diego eram mais altas que as de todo mundo para cinco dos seis
candidatos, e nunca abaixo de 3. Isso não queria dizer que o Diego estava errado. Queria dizer que o 3
dele e o 3 da Helena talvez não significassem a mesma coisa, e que a chance de uma candidata receber
proposta dependia em parte de quem a entrevistou.

Três coisas ajudam, e a Caju faz todas:

- **Acompanhar.** Uma pessoa nova assiste a algumas entrevistas antes de conduzir as próprias, e uma
  experiente assiste às primeiras da pessoa nova, e depois as duas comparam as notas.
- **Sessões de calibragem.** Duas vezes por ano, quem entrevista para um cargo pontua as mesmas
  respostas escritas de forma independente e compara. As discordâncias mostram onde a redação da escala
  está pouco clara.
- **Olhar para trás.** Depois de um ano, a Renata compara as notas de entrevista com como as pessoas
  contratadas se saíram de fato. Em muitas contratações, uma pessoa entrevistadora cujas notas não
  preveem nada merece atenção; em uma ou duas, é acaso.

A Renata mostrou o gráfico ao Diego, em particular. Ele não sabia. Releu os próprios registros e
concordou que vinha pontuando o quanto tinha gostado de conversar com a pessoa. **Ninguém enxerga a
própria leniência sem os números ao lado dos de todo mundo**, e é por isso que a comparação precisa ser
feita por alguém, de propósito.

## A sua tarefa

Para uma decisão tomada por um grupo de que você fez parte, no trabalho ou em outro lugar, anote no
caderno a ordem em que as pessoas falaram e se alguém mudou de opinião durante a discussão. Depois
confira:

- Quem falou primeiro, e a decisão final bateu com a opinião dessa pessoa?
- A opinião da pessoa mais sênior era conhecida antes de as outras falarem?
- Alguma discordância foi registrada, ou sumiu dentro da decisão?
