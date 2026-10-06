---
title: Como o texto vira voz
version: 1
---

**Um sistema de texto para fala transforma caracteres em som por etapas**, e a primeira etapa é a que dá errado. As etapas são as mesmas há décadas; o que os modelos modernos mudaram foi como as últimas são feitas.

1. A **normalização do texto** transforma o que está escrito no que se diz: dígitos em palavras, abreviações no que elas significam, símbolos em nomes.
2. A **fonemização** transforma palavras em **fonemas**, os sons de uma língua, para que *though* e *tough* não sejam lidas igual.
3. O **modelo acústico** transforma fonemas numa descrição do som ao longo do tempo: altura, duração, timbre.
4. O **vocoder** transforma essa descrição numa forma de onda, os números que um alto-falante toca.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Quatro caixas em fila, ligadas por setas. Texto: M-1042. Palavras normalizadas: M one thousand forty-two. Fonemas, como o espeak-ng os escreve: &#x27;Em w&#x27;Vn T&#x27;aUz@nd f&#x27;o@t#i t&#x27;u:. Forma de onda: 22.050 números por segundo. Sob as duas últimas caixas, uma chave diz que o modelo VITS do Piper faz os dois passos numa só rede.\"><defs><marker id=\"l06stg-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"150\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">texto</text><text x=\"30\" y=\"66.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">M-1042</text><line x1=\"172\" y1=\"58\" x2=\"193\" y2=\"58\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#l06stg-ah-phosphor)\"></line><rect x=\"195\" y=\"30\" width=\"150\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"205\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">palavras</text><text x=\"205\" y=\"66.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">one thousand forty-two</text><line x1=\"347\" y1=\"58\" x2=\"368\" y2=\"58\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#l06stg-ah-phosphor)\"></line><rect x=\"370\" y=\"30\" width=\"150\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"380\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">fonemas</text><text x=\"380\" y=\"66.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">'Em w'Vn T'aUz@nd</text><line x1=\"522\" y1=\"58\" x2=\"543\" y2=\"58\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#l06stg-ah-phosphor)\"></line><rect x=\"545\" y=\"30\" width=\"150\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"555\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">forma de onda</text><text x=\"555\" y=\"66.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">22.050 por segundo</text><text x=\"199\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">o passo que dá errado</text><path d=\"M 370 120 L 370 132 L 695 132 L 695 120\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><text x=\"532\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o modelo VITS do Piper: uma rede só</text><text x=\"20\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">O espeak-ng faz os dois primeiros passos por regra; o modelo aprende os dois últimos.</text></svg>", "caption": "Uma voz só acerta tanto quanto as palavras que recebeu, e a entrega é feita por regras que uma pessoa consegue ler."}
```

As vozes do laboratório são vozes **Piper**, que são modelos VITS: uma rede neural que faz as etapas 3 e 4 juntas, de fonemas direto para forma de onda. As etapas 1 e 2 são feitas antes da rede pelo **espeak-ng**, um programa de fala de código aberto cujas regras para várias línguas o Piper empresta (cada voz carrega a própria cópia dos dados do espeak-ng). Como essas regras são um programa, dá para perguntar diretamente a elas o que vão entregar à voz:

```
ana@lab:~/mm$ espeak-ng -q -x -v en-us "Your order M-1042 arrived on 24/09/2026."
jU@r- 'O@d3r- 'Em _ w'Vn T'aUz@nd f'o@t#i t'u: 3r'aIvd ,O2n tw'Ent2i f'o@ sl'aS z'i@roU n'aIn sl'aS t'u: T'aUz@nd tw'Ent2i s'Iks
ana@lab:~/mm$ espeak-ng -q -x -v en-us "Your refund of R\$ 34,80 is on its way."
jU@ r'i:fVnd Vv 'A@ d'0l3 T'3:t#i f'o@r 'eIt#i; Iz ,O2n Its w'eI
ana@lab:~/mm$ espeak-ng -q -x -v en-us "Dom Casmurro, by Machado de Assis."
d'0m kazm'3:roU
baI matS'A:doU d@ a#s'Is
ana@lab:~/mm$ espeak-ng -q -x -v pt-br "Dom Casmurro, de Machado de Assis."
d'oN k,azm'uxU
dZy m,aS'adU dZj as'is
```

A saída está na notação de fonemas do próprio espeak-ng, escrita com letras e símbolos comuns: `T` é o *th* de *thousand*, `@` a vogal fraca de *the*, e `'` marca uma sílaba tônica. Não é preciso lê-la com fluência para ver três problemas.

**O número do pedido virou uma quantidade**: `'Em _ w'Vn T'aUz@nd f'o@t#i t'u:`, "M mil e quarenta e dois". Ninguém lê um número de pedido assim, e um cliente que o anotasse escreveria 1000 e 42, como o Whisper fez com a ligação de suporte na aula 1.

**A data foi lida caractere por caractere**: "vinte e quatro barra zero nove barra dois mil e vinte e seis". O dinheiro virou "R dólar trinta e quatro oitenta", porque `$` é *dollar* e a vírgula é uma pausa.

**O nome brasileiro foi lido com regras do inglês** na voz em inglês: `matS'A:doU` para Machado, com o *ch* de *match*. As regras da voz em português dão `m,aS'adU`, com o som de *x* que o português do Brasil usa. Nenhum dos dois é defeito do espeak-ng: cada um leu o texto pelas regras da sua língua, que é exatamente o que lhe pediram.

**Nada disso é culpa da voz**, e nada disso se resolveria com uma voz melhor. Uma rede neural melhor pronuncia as palavras erradas com mais beleza. A correção é a etapa 1, feita por você, antes de a voz ver o texto: seção 04.
