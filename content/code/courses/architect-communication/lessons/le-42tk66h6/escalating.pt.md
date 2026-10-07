---
title: Quando escalar, e como
version: 1
---

**Escale quando as pessoas na discordância não têm autoridade para resolvê-la, ou quando esperar
custa mais do que decidir; e escale juntos, nunca como emboscada.** Escalar não é um fracasso da
mediação. É o movimento certo quando a pergunta está acima de quem está na sala, e o errado quando
é usado para ganhar.

## Quando chega a hora

Três situações justificam levar uma discordância para cima:

1. **Nenhum dos lados é dono da decisão.** Se checkout e logística discordam sobre o que importa
   mais em novembro, a Black Friday ou a qualidade das rotas, nenhum tech lead pode decidir isso; é
   uma prioridade do negócio.
2. **O custo de não decidir está crescendo.** Uma discordância que trava um release, ou que mantém
   dois times construindo coisas incompatíveis, fica mais cara a cada dia.
3. **A mediação foi tentada e empacou**, com interesses e critérios na mesa e ainda assim sem
   acordo.

E uma situação em que nunca é a resposta: **fugir de uma conversa que você poderia ter tido.** Ir
ao head de engenharia falar de um colega antes de falar com o colega não é escalar; é uma queixa, e
estraga a relação mais do que a discordância original.

## O caminho

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Três passos da esquerda para a direita. As duas pessoas conversam direto, fora do canal; a maioria dos desacordos acaba aqui. Os dois donos se reúnem com mediação, passando por interesses e critérios. Quem responde pelos dois decide, a partir de uma página escrita junto.\"><defs><marker id=\"escpath-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"50\" width=\"200\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"120\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">as duas pessoas</text><text x=\"120\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">conversam direto, fora do canal</text><path d=\"M222 85 L256 85\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#escpath-ah)\"></path><rect x=\"260\" y=\"50\" width=\"200\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">os dois donos</text><text x=\"360\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">com mediação: interesses, critérios</text><path d=\"M462 85 L496 85\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#escpath-ah)\"></path><rect x=\"500\" y=\"50\" width=\"200\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"600\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">quem responde pelos dois</text><text x=\"600\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">uma página, escrita junto</text><text x=\"20\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">a maioria dos desacordos acaba aqui</text><text x=\"20\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">cada passo só depois de tentar o anterior; nunca direto ao topo</text></svg>", "caption": "O caminho de escalonamento. A página do último passo traz os fatos com que os dois lados concordam, para quem decide ouvir uma só versão deles."}
```

Cada degrau acima só é subido depois de o de baixo ter sido tentado. A maioria das discordâncias
termina no primeiro ou no segundo degrau. As que chegam ao terceiro chegam com um documento, que é o
próximo ponto.

## Escale juntos, com uma página

Quando Bruna e Henrique não conseguiram concordar sobre as prioridades de novembro, não foram cada
um ao head de engenharia com a própria versão. Lívia pediu que escrevessem uma página juntos:

> **A pergunta.** Em novembro, o congelamento de versões da logística deve acompanhar o do checkout,
> a partir do dia 16, ou começar no dia 23, para que as rotas do novo depósito saiam antes?
>
> **Fatos em que concordamos.** A Black Friday é no dia 27. As rotas do depósito economizam cerca de
> 40 minutos de motorista por rota. Um release da logística quebrou o checkout uma vez este ano, em
> 6 de março.
>
> **A visão da Bruna.** Congelar a partir do dia 16: uma janela de release a mais é uma chance a
> mais de outro março.
>
> **A visão do Henrique.** Congelar a partir do dia 23: o depósito abre no dia 21 e os motoristas
> precisam das rotas.
>
> **O que precisamos de você.** Uma decisão até sexta.

**Os fatos combinados são a parte mais importante.** Escrevê-los juntos obriga os dois lados a
separar aquilo de que discordam daquilo de que não discordam, e faz quem decide ouvir uma versão dos
fatos, e não duas. O head de engenharia decidiu em dez minutos: congelamento a partir do dia 23, com
um teste de carga do release do depósito no dia 19. Nenhum lado ficou exatamente com a sua posição;
os dois tinham sido ouvidos, com as próprias palavras, no mesmo documento.

## Depois da decisão

O lado que não ganhou se compromete, como a aula 8 descreveu. Quem mediou publica o resultado onde o
conflito começou, neste caso o canal da plataforma, para que a thread de sessenta mensagens termine
com uma decisão em vez de se arrastar até sumir.
