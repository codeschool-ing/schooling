---
title: A primeira ligada, e a tela preta que significa nove coisas
version: 1
---

Aperte o botão e acontece uma de três coisas: ele desenha uma imagem, não acontece nada, ou **as
ventoinhas giram e a tela continua preta.** A terceira é a comum e é a que parece um desastre.

Não é. É uma lista.

## Teste sobre a caixa, antes de estar no gabinete

O hábito mais útil em montagem de computadores: **ligue a placa fora do gabinete**, apoiada sobre
a própria caixa de papelão, com só o processador, o cooler, um módulo de memória e a fonte
conectados.

Duas razões, e a segunda é a importante. Um gabinete acrescenta uma dúzia de jeitos de estar
errado — um espaçador sob furo nenhum, um painel frontal em curto, um parafuso atrás da placa — e
o teste de bancada elimina todos de uma vez. E se funcionar sobre a caixa e não no gabinete, **o
gabinete é o defeito**, que é uma frase a que não se chega de nenhum outro jeito.

Não há botão de ligar numa placa nua. Encoste brevemente uma chave de fenda nos dois pinos
`PWR_SW`; é só isso que o botão faz.

## O que é o POST, e o que ele te diz

Quando a energia chega, o firmware roda um **autoteste de ligação** antes que qualquer outra coisa
exista. Ele acha o processador, mede a memória, e procura algo em que desenhar. Se falha, ele
reporta antes que qualquer sistema operacional pudesse ter carregado.

Três jeitos de ele reportar, e você quer pelo menos um deles:

- **Um visor de depuração** — dois dígitos nas placas melhores, e o manual lista cada código.
- **LEDs de depuração** — quatro luzes rotuladas `CPU`, `DRAM`, `VGA`, `BOOT`. A que continua
  acesa é a etapa em que ele parou, que é o diagnóstico mais útil de uma placa moderna.
- **Bipes**, se houver um alto-falante instalado. Um bipe curto normalmente é sucesso; um padrão
  que se repete é um código.

Uma placa sem nenhum dos três não te diz nada, e é por isso que instalar o alto-falante vale os
trinta segundos.

## Percorrendo a tela preta

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" aria-label=\"Seis verificações numeradas, cada uma com o que ela elimina ao lado. Na ordem: alguma coisa gira, o EPS de oito pinos está ligado, um módulo de memória no soquete dois, o monitor na placa-mãe e não na de vídeo, limpe os ajustes do firmware, e fora do gabinete sobre a caixa. Uma nota diz que cada verificação remove uma família inteira de causas em vez de testar uma peça.\"><text x=\"24\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Uma tela preta, percorrida em vez de adivinhada</text><text x=\"76\" y=\"46\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o que conferir</text><text x=\"680\" y=\"46\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">e o que isso elimina</text><rect x=\"24\" y=\"62\" width=\"672\" height=\"34\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"42\" y=\"79\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">1</text><text x=\"76\" y=\"79\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">alguma coisa gira?</text><text x=\"680\" y=\"79\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">a fonte e o botão de ligar</text><rect x=\"24\" y=\"104\" width=\"672\" height=\"34\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"42\" y=\"121\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">2</text><text x=\"76\" y=\"121\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o EPS de 8 pinos está ligado?</text><text x=\"680\" y=\"121\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">o cabo mais esquecido de todos</text><rect x=\"24\" y=\"146\" width=\"672\" height=\"34\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"42\" y=\"163\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">3</text><text x=\"76\" y=\"163\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">um módulo de memória, no soquete 2</text><text x=\"680\" y=\"163\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">um módulo, ou um soquete</text><rect x=\"24\" y=\"188\" width=\"672\" height=\"34\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"42\" y=\"205\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">4</text><text x=\"76\" y=\"205\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o monitor na placa-mãe, não na de vídeo</text><text x=\"680\" y=\"205\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">a placa de vídeo</text><rect x=\"24\" y=\"230\" width=\"672\" height=\"34\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"42\" y=\"247\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">5</text><text x=\"76\" y=\"247\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">limpe os ajustes do firmware</text><text x=\"680\" y=\"247\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">algo que alguém salvou</text><rect x=\"24\" y=\"272\" width=\"672\" height=\"34\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"42\" y=\"289\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">6</text><text x=\"76\" y=\"289\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">fora do gabinete, sobre a caixa</text><text x=\"680\" y=\"289\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">um espaçador sob furo nenhum</text><text x=\"24\" y=\"326\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Cada linha remove uma família inteira de causas. Chutar uma peça testa uma peça.</text></svg>", "caption": "A ordem importa tanto quanto a lista: cada passo é escolhido para que o seguinte signifique alguma coisa."}
```

**Um módulo de memória, no segundo soquete a partir do processador**, é a verificação que as
pessoas pulam e é a que encontra mais defeitos que o resto da lista. Uma placa se recusa a fazer
POST com um módulo ruim, com um módulo no soquete errado, e ocasionalmente com dois módulos que
funcionam sozinhos.

**O monitor no soquete da própria placa-mãe** separa a placa de vídeo de todo o resto num
movimento só — e se o processador não tem vídeo integrado, essa verificação não existe para você,
o que vale saber antes de precisar dela.

## Dois ruídos que não são defeito

Uma montagem nova muitas vezes **liga, roda dois segundos, desliga e parte de novo.** Isso é
treino de memória: a placa está medindo os módulos e acertando os tempos. Acontece na primeira
partida e depois de mexer nos ajustes de memória, e pode levar trinta segundos.

Um cooler a toda no primeiro par de segundos também é normal. A placa roda todas as ventoinhas
no máximo até ter lido uma temperatura.

## O que fazer quando funciona

Nada ainda. **Deixe o gabinete aberto**, confira que a ventoinha do processador está girando e que
as da placa de vídeo não estão travadas contra um cabo, e entre no firmware. A próxima seção é o
que mudar lá, e a resposta é menos do que você imagina.
