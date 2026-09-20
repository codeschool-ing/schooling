---
title: O documento não é um arquivo, e tudo decorre disso
version: 1
---

Um documento do Word é um objeto num disco. Um Google Doc é **algo num servidor que você está
olhando através de um navegador**, e o navegador é uma janela e não um programa segurando uma
cópia.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 274\" role=\"img\" aria-label=\"Dois painéis comparando onde um documento está. O da esquerda, um arquivo num disco, é endereçado por um caminho, salvo apertando salvar, desfeito pela pilha de desfazer, e compartilhado anexando uma cópia. O da direita, um documento num servidor, é endereçado por uma URL, salvo a cada tecla, desfeito a partir de um histórico completo de versões, e compartilhado dando a alguém o mesmo endereço.\"><text x=\"24\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Onde o documento está, e tudo que decorre disso</text><rect x=\"24\" y=\"36\" width=\"322\" height=\"196\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"44\" y=\"58\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">um arquivo num disco</text><text x=\"44\" y=\"90\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o endereço dele</text><text x=\"326\" y=\"90\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">um caminho</text><text x=\"44\" y=\"122\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">salvar</text><text x=\"326\" y=\"122\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">você aperta salvar</text><text x=\"44\" y=\"154\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">desfazer</text><text x=\"326\" y=\"154\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">esta sessão</text><text x=\"44\" y=\"186\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">compartilhar</text><text x=\"326\" y=\"186\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">anexar uma cópia</text><rect x=\"374\" y=\"36\" width=\"322\" height=\"196\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"394\" y=\"58\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">um documento num servidor</text><text x=\"394\" y=\"90\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o endereço dele</text><text x=\"676\" y=\"90\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">uma URL</text><text x=\"394\" y=\"122\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">salvar</text><text x=\"676\" y=\"122\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">cada tecla</text><text x=\"394\" y=\"154\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">desfazer</text><text x=\"676\" y=\"154\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">cada versão</text><text x=\"394\" y=\"186\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">compartilhar</text><text x=\"676\" y=\"186\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">o mesmo endereço</text><text x=\"24\" y=\"256\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Uma coluna é uma coisa que você tem. A outra é uma coisa que você está olhando.</text></svg>", "caption": "Toda diferença desta aula é consequência da primeira linha, e é na última que os erros acontecem."}
```

## Não existe salvar, e as consequências disso

Cada tecla é enviada conforme você a aperta. Não há botão de salvar, não há aviso de *alterações
não salvas* e não há como fechar sem guardar o que você fez.

**Isso elimina uma categoria inteira de perda e cria outra.** Você não perde uma tarde para uma
queda, e você também não consegue decidir, uma hora depois, que o trabalho de hoje foi um erro e
fechar sem salvar.

O substituto dessa decisão é o **histórico de versões** — *Arquivo, Histórico de versões, Ver
histórico de versões* — que guarda cada estado pelo qual o documento passou, nomeado pela hora e
por quem estava editando. Ele é melhor que a coisa que substitui: dá para nomear uma versão,
restaurar uma, e ver exatamente qual pessoa escreveu qual frase.

Duas coisas sobre ele valem saber antes de você precisar:

- **Ele não é infinito numa conta pessoal.** Versões detalhadas antigas são consolidadas; as
  nomeadas são mantidas.
- **Um documento na lixeira ainda existe por trinta dias**, e um documento apagado pelo dono
  desaparece para todos com quem ele foi compartilhado — que é o modo de falha de depender do
  documento de outra pessoa.

## Offline, que funciona e precisa ser arranjado antes

Habilitar o acesso offline baixa para o navegador uma cópia dos documentos que você abriu
recentemente, e as edições feitas sem conexão são enviadas quando houver uma.

Tem de ser ligado **antes** de você precisar, nas configurações do Drive, e funciona no Chrome e
no Edge e não em todo navegador. Arranjar isso dentro do avião não é possível, que é a razão
inteira de arranjar agora.

## As duas coisas que genuinamente se foram

**Você não tem uma cópia.** O documento existe onde a empresa o guarda, sob uma conta que pode ser
suspensa, num serviço que pode mudar. O argumento da aula oito vale exatamente: uma cópia que você
não tem não é um backup, e a resposta é a exportação no fim desta aula.

**Não há arquivo para anexar.** Enviar um Google Doc é ou mandar um link — o que exige uma decisão
sobre quem pode abrir — ou exportar uma cópia, que é um instantâneo e deixa de ser o documento no
instante em que alguém edita.

Esse segundo ponto é a origem de quase toda confusão em escritórios mistos, e a próxima seção é
sobre a decisão que ele obriga.
