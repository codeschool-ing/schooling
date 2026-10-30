---
title: Online-first e offline-first
version: 1
---

**Um app construído online-first pede ao servidor cada tela e trata o aparelho como uma janela. Um
app construído offline-first lê cada tela do próprio banco e trata o servidor como alguém com quem
concordar depois.** Os dois parecem iguais numa boa conexão. Eles se separam no momento em que a
conexão some.

A imagem comum é a de que suporte offline é um recurso que se acrescenta: um cache na frente das
requisições, ligado quando a rede falha. Não é um recurso. Ele decide **onde mora a verdade enquanto
a pessoa usa o app**, e essa decisão muda o caminho que toda escrita percorre.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l07-two-ways\" aria-label=\"Duas linhas. Online-first: a tela pede ao servidor, pela rede, cada leitura e cada escrita, e quando a rede some a tela não tem o que desenhar. Offline-first: a tela lê e grava no banco do aparelho, e uma etapa separada de sincronização leva as mudanças ao servidor depois, quando houver rede.\"><defs><marker id=\"l07-two-ways-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">online-first</text><rect x=\"20\" y=\"40\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a tela</text><rect x=\"550\" y=\"40\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"625.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o servidor</text><path d=\"M170 62 L550 62\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l07-two-ways-ah-paper-dim)\" marker-start=\"url(#l07-two-ways-ah-paper-dim)\"></path><text x=\"360\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">toda leitura e escrita</text><text x=\"360\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">sem rede: nada a desenhar</text><text x=\"20\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">offline-first</text><rect x=\"20\" y=\"144\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a tela</text><rect x=\"270\" y=\"144\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"345.0\" y=\"159.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o banco</text><text x=\"345.0\" y=\"172.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">no aparelho</text><rect x=\"550\" y=\"144\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"625.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o servidor</text><path d=\"M170 166 L270 166\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l07-two-ways-ah-paper-dim)\" marker-start=\"url(#l07-two-ways-ah-paper-dim)\"></path><text x=\"220\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--phosphor)\">lê e grava, na hora</text><path d=\"M420 166 L550 166\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l07-two-ways-ah-paper-dim)\" marker-start=\"url(#l07-two-ways-ah-paper-dim)\"></path><text x=\"485\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">sincroniza, depois</text></svg>", "caption": "O online-first põe o servidor entre a pessoa e cada tela. O offline-first põe ali o banco do aparelho, e envia ao servidor numa etapa separada.", "same": ["online-first", "offline-first"]}
```

## Online-first

A tela pergunta ao servidor, espera e desenha o que voltou. Uma sessão nova é um `POST`; a lista a
mostra quando o servidor diz sim. Num trem, o botão gira até estourar o tempo, e a pessoa aprende
que o planner não funciona debaixo da terra. Nada se perde, porque nada jamais foi guardado.

## Offline-first

A tela lê o banco do aparelho. Uma sessão nova é uma linha gravada ali, e a lista a mostra na hora,
porque a lista foi desenhada a partir desse banco desde o começo. **Enviá-la ao servidor é uma etapa
separada que acontece depois**, quando houver rede, e a linha carrega uma marca dizendo se essa
etapa já aconteceu.

O que o offline-first custa é tudo de que este curso trata da aula 8 à aula 15. O aparelho e o servidor guardam cada um uma cópia, então alguém precisa fazer quatro trabalhos. Levar as mudanças de um para o outro (uma caixa de saída, aula 8), sobreviver à rede caindo no meio (aulas 9 e 10), saber o que mudou do
outro lado (aulas 11 e 12) e decidir o que acontece quando os dois lados mudaram a mesma coisa
(aulas 13 a 15).

## Qual dos dois um planner quer

A pergunta é quem sai prejudicado por esperar. O saldo de um banco tem de ser o número do banco, e
mostrar um número que o servidor não confirmou seria uma mentira. Um planner de estudos é o oposto:
a sessão que a pessoa digitou é dela, e nada que o servidor saiba a torna mais verdadeira. **Gravar
localmente primeiro não perde nada e tira da tela todos os indicadores de carregamento.** É esse o
planner que esta aula constrói.

A maioria dos apps é uma mistura, e a divisão é por tela, não por app. A lista de cursos à venda no
planner pode ser online-first, já que um preço é do servidor dizer; as sessões são offline-first.
