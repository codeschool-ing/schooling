---
title: Para que serve uma senha, de fato
version: 1
---

Uma senha protege contra dois ataques completamente diferentes, e quase todo conselho que as
pessoas lembram mira naquele que menos importa.

## Adivinhação, e por que comprimento é a resposta

Alguém testando senhas contra a sua conta, uma atrás da outra, é barrado por haver testes demais
a fazer. O que decide quantos existem é o **comprimento**, de forma esmagadora, e o alfabeto de
onde você tirou, de forma fraca.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 304\" role=\"img\" aria-label=\"Uma tabela de quatro senhas com duas estimativas cada. Uma palavra curta com letras trocadas por números: minutos se fosse aleatória, na hora na prática. Uma palavra com maiúscula, símbolo e ano: meses se fosse aleatória, minutos na prática. Quatro palavras sem relação: séculos nas duas colunas. Uma sequência aleatória de dezesseis caracteres vinda de um gerenciador: séculos nas duas colunas.\"><text x=\"24\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Quatro senhas, e os dois números que diferem</text><text x=\"44\" y=\"48\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a senha</text><text x=\"360\" y=\"48\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">se ninguém adivinhasse o formato</text><text x=\"552\" y=\"48\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o que de fato acontece</text><rect x=\"24\" y=\"64\" width=\"300\" height=\"44\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"44\" y=\"86\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">s3nh4</text><rect x=\"344\" y=\"64\" width=\"176\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"86\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">minutos</text><rect x=\"536\" y=\"64\" width=\"160\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"552\" y=\"86\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">na hora</text><rect x=\"24\" y=\"116\" width=\"300\" height=\"44\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"44\" y=\"138\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Senha@2024</text><rect x=\"344\" y=\"116\" width=\"176\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"138\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">meses</text><rect x=\"536\" y=\"116\" width=\"160\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"552\" y=\"138\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">minutos</text><rect x=\"24\" y=\"168\" width=\"300\" height=\"44\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"44\" y=\"190\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">cavalo grampo bateria sela</text><rect x=\"344\" y=\"168\" width=\"176\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"190\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">séculos</text><rect x=\"536\" y=\"168\" width=\"160\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"552\" y=\"190\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">séculos</text><rect x=\"24\" y=\"220\" width=\"300\" height=\"44\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"44\" y=\"242\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">k7Qv2mXz9RtL4pWd</text><rect x=\"344\" y=\"220\" width=\"176\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"242\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">séculos</text><rect x=\"536\" y=\"220\" width=\"160\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"552\" y=\"242\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">séculos</text><text x=\"24\" y=\"286\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">A coluna do meio é aritmética. A da direita é o que uma ferramenta de adivinhação faz, que é testar primeiro os formatos que ensinaram as pessoas a fazer.</text></svg>", "caption": "A segunda linha é o conselho que todo mundo aprendeu, e a distância entre as duas colunas dela é a razão inteira de o conselho ter mudado."}
```

É essa a aritmética inteira, e é por isso que o conselho que todo mundo aprendeu — uma maiúscula,
um número, um símbolo — produz `Senha@2024`, que é curta, e que toda ferramenta de adivinhação
testa cedo exatamente por ter o formato que ensinaram as pessoas a fazer.

**Quatro palavras sem relação ganham de uma torcida.** `cavalo grampo bateria sela` é mais longa,
mais fácil de lembrar e enormemente mais difícil de adivinhar que `C@v@l0!23`. A única regra sobre
as palavras é que elas não podem ser uma frase que alguém já escreveu — um verso de música não são
quatro palavras aleatórias, é uma coisa só.

## E o ataque que de fato acontece

**Reúso.** Um site em que você se cadastrou em 2015 é invadido, e a lista de endereços e senhas
dele é publicada. Ninguém está adivinhando nada: pegam o seu endereço e a sua senha e os testam no
banco, no e-mail e no marketplace, automaticamente, em questão de horas.

É assim que gente comum perde conta, e é por isso que a senha mais forte do mundo não vale nada no
instante em que ela é a senha de duas coisas.

Então a regra que importa não é *faça complicada.* É **nunca use duas vezes**, que é impossível de
memória e trivial com a próxima seção.

## Gerenciadores de senha, com honestidade

Um gerenciador de senhas gera uma senha longa e aleatória diferente para cada site, guarda tudo
criptografado atrás de uma senha que você sabe, e preenche para você.

A objeção que todo mundo levanta é a de verdade: **isso põe tudo atrás de um único ponto de
falha.** É verdade, e ainda assim é a troca certa, por dois motivos. A alternativa na prática não
são cinquenta senhas decoradas — é uma senha usada cinquenta vezes, que é um único ponto de falha
sem criptografia nenhuma. E a proteção do próprio gerenciador pode ser muito forte, porque é a
única que você precisa lembrar.

Três notas práticas:

- **A senha-mestra é uma que você digita**, então ela quer ser longa e memorável: a regra das
  quatro palavras, e nada mais que você use em outro lugar.
- **Preencher também é um recurso de segurança**, e essa é a parte que ninguém menciona: um
  gerenciador preenche uma senha só no endereço para o qual ela foi salva. Uma cópia convincente da
  página do seu banco não recebe nada, porque o gerenciador não a reconhece — e *o gerenciador não
  se ofereceu para preencher* é o melhor aviso que você vai receber na vida.
- **Anote a senha-mestra e ponha num lugar físico.** Não na mesa. No lugar onde se guardam os
  papéis importantes.

## E a que não é uma senha

Três perguntas cujas respostas são fatos públicos — o sobrenome da sua mãe, a cidade em que você
nasceu, a sua primeira escola — não são uma segunda senha. Onde um site insiste nelas, **a resposta
não precisa ser verdadeira**, e o gerenciador pode guardar uma inventada.
