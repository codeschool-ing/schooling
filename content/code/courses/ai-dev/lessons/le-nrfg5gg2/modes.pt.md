---
title: Completar, chat e agente
version: 2
---

Assistentes de editor vêm em três modos, e o jeito útil de separá-los não é o que conseguem fazer,
mas **quanto fazem antes de você olhar**. Cada degrau acima entrega mais do trabalho, e muda a sua
parte de escrever código para revisá-lo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Três modos de um assistente no editor, de menos para mais autonomia. Completar: você revisa uma linha ou um bloco quando aparece. Chat: você revisa uma resposta ou um diff antes de aplicar. Agente: ele edita arquivos e roda comandos, e você revisa a mudança inteira como um pull request.\"><defs><marker id=\"md-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"30\" y=\"150\" width=\"210\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"135.0\" y=\"169.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">completar</text><text x=\"135.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sugere no cursor</text><text x=\"135.0\" y=\"201.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">você revisa: uma linha ou um bloco</text><rect x=\"255\" y=\"100\" width=\"210\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"119.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">chat</text><text x=\"360.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">responde, propõe</text><text x=\"360.0\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">você revisa: uma resposta ou um diff</text><rect x=\"480\" y=\"50\" width=\"210\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"585.0\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">agente</text><text x=\"585.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">edita arquivos, roda comandos</text><text x=\"585.0\" y=\"101.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">você revisa: a mudança inteira</text><path d=\"M40 236 L680 236\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#md-ah)\"></path><text x=\"360\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o que ele faz antes de você olhar</text></svg>", "caption": "Cada degrau faz mais antes de você olhar, e a revisão passa de uma linha a um pull request.", "same": ["chat"]}
```

## Completar no editor

O texto fantasma que aparece enquanto você digita, aceito com uma tecla. É o modo da aula 3 seções
02 e 04: uma requisição de preencher o meio montada a partir do arquivo em volta do cursor, mandada
depois de uma pausa na digitação, muitas vezes por minuto. **A unidade de revisão é uma linha ou
um bloco**, pequena o bastante para você ler enquanto aparece, e é o modo em que um erro é mais
barato de pegar, porque você está olhando para o lugar exato onde ele cai.

Ele é ruim em qualquer coisa que exija uma decisão fora do arquivo atual. Vê o contexto que o
editor juntou, e só.

## Chat

Um painel onde você faz perguntas e recebe respostas, código e diffs, como na aula 3 seções 06 e
07. Você escolhe o contexto (a seleção, os arquivos abertos, os arquivos que cita), e **nada muda no
projeto até você aplicar**. A unidade de revisão é uma resposta, e o hábito que importa é o da aula
3 seção 06: leia a mudança como um diff, contra o código que ela substitui.

O chat também é onde um assistente é mais útil sem escrever nada: explicar um módulo desconhecido,
ler um stack trace com você, listar os casos que uma função não trata. A resposta a uma pergunta é
mais fácil de conferir que um código.

## Agente

O assistente planeja, abre arquivos, edita vários deles e **roda comandos**: os testes, o linter,
um script, o `git`. Ele trabalha num laço do tipo que a aula 7 constrói, e pode dar muitos passos
antes de voltar a você. A unidade de revisão é a mudança inteira, como num pull request.

Duas coisas tornam o modo agente seguro o bastante para usar, e as duas são ajustes que você
escolhe:

- **Permissões.** Se cada edição de arquivo e cada comando precisam da sua aprovação, ou só alguns,
  ou nenhum. Aprovar todo comando é lento e é o padrão certo num projeto que você não conhece.
  "Permitir o comando dos testes sem perguntar" é um passo razoável. "Permitir qualquer comando"
  deixa o texto que o agente leu decidir o que roda na sua máquina, e a aula 11 mostra que esse
  risco é real.
- **Um lugar de onde desfazer.** Trabalhe num branch, faça commit antes de começar, e revise com
  `git diff` quando ele terminar. Um agente que editou doze arquivos se revisa como o pull request
  de doze arquivos de um colega: devagar, com os testes rodando.

## Escolhendo

Use o menor modo que resolve. Uma linha que falta é um completar. Uma pergunta sobre o código é um
chat. Uma mudança em vários arquivos com um jeito claro de conferir (os testes têm de passar, o
linter tem de ficar limpo) é onde um agente economiza tempo de verdade. Quanto mais um modo faz
sozinho, mais o resultado depende de essa checagem existir antes de você começar.
