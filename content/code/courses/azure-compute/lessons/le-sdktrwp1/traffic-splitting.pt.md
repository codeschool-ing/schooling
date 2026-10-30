---
title: "Divisão de tráfego: blue/green e canário"
version: 1
---

A imagem errada de uma divisão 90/10 é a de um porteiro contando: nove clientes para a versão
antiga, o décimo para a nova, e começa de novo. **Um peso é uma parte das requisições que chegam ao
endereço do app, e nada na documentação da Microsoft promete como cada requisição é atribuída.** Ao
longo de um dia as partes saem como foram escritas; em vinte requisições podem sair bem diferentes, e
o fim desta seção calcula o quanto. Um peso também não é um número de réplicas: cada revisão escala
pela sua própria parte do tráfego, pela sua própria regra. E ao lado dos pesos há um segundo
mecanismo, o **rótulo**, que dá a uma revisão um endereço próprio em que nenhum peso toca. Esta seção
lê os dois da documentação, compila um erro que o compilador deixa passar e faz a aritmética.

## Pesos

Com o ingress ligado e nada dito, todo o tráfego vai para a revisão mais recente. No modo múltiplo, a
lista `traffic` do ingress diz outra coisa. Cada entrada nomeia uma revisão, por `revisionName`, por
`label` ou como `latestRevision: true`, e lhe dá um `weight`. O arquivo da loja nomeia as duas
revisões:

```bicep
traffic: [
  { revisionName: 'shop--v1-0', weight: 90 }
  { revisionName: 'shop--v1-1', weight: 10, label: 'canary' }
]
```

**Os pesos têm de somar 100**, diz a documentação. O compilador não os soma:

```
ana@laptop:~/azure$ sed 's/weight: 10,/weight: 20,/' shop-app.bicep > sum.bicep
ana@laptop:~/azure$ bicep build sum.bicep
ana@laptop:~/azure$ jq -c '[.resources[1].properties.configuration.ingress.traffic[].weight]' sum.json
[90,20]
```

Um template pedindo 110 por cento do tráfego, compilado sem uma palavra, e só o Azure o recusaria. Na
linha de comando a mesma divisão é um comando só, com a ajuda descrevendo os dois jeitos de nomear
uma revisão:

```
ana@laptop:~/azure$ az containerapp ingress traffic set --help | sed -n '/^Arguments/,/^$/p'
Arguments
    --label-weight                : A list of label weight(s) for the container app. Space-separated
                                    values in 'label_name=weight' format.
    --revision-weight             : A list of revision weight(s) for the container app. Space-
                                    separated values in 'revision_name=weight' format. For latest
                                    revision, use 'latest=weight'.
    --traffic-weight [Deprecated] : A list of revision weight(s) for the container app. Space-
                                    separated values in 'revision_name=weight' format. For latest
                                    revision, use 'latest=weight'.
        WARNING: Option '--traffic-weight' has been deprecated and will be removed in a future
        release. Use '--revision-weight' instead.
```

Numa assinatura, a divisão da loja seria definida com
`az containerapp ingress traffic set --name shop --resource-group shop --revision-weight shop--v1-0=90 shop--v1-1=10`,
não executado neste curso. `latest` representa a revisão mais nova, qualquer que seja. Isso serve a
um app em que toda implantação deve receber todo o tráfego de uma vez, e é a escolha errada para um
canário, em que a mais nova é justamente a revisão em que você ainda não confia para tudo.

**Cada revisão escala separadamente.** O bloco de escala da seção 03 pertence ao template, então as
duas revisões têm o seu, e cada uma conta só as requisições que recebe. Durante a divisão, a revisão
antiga pode rodar até 10 réplicas e a nova até mais 10, e a nova, com um décimo do tráfego, chega a
zero com mais frequência. Os clientes dela encontram mais cold starts que os outros, o que vale saber
antes de comparar os tempos de resposta das duas revisões.

## Rótulos

Um rótulo é um nome numa revisão, e vem com um endereço. A página de blue-green da Microsoft alcança
uma revisão rotulada no nome do app, três traços e o rótulo, sob o domínio do ambiente:
`shop---canary.` seguido do domínio. **O endereço de um rótulo chega à revisão dele sejam quais forem
os pesos**, inclusive com peso 0, então uma revisão pode ser testada no endereço real, no ambiente
real, pelos três desenvolvedores, antes que qualquer cliente seja mandado para lá.

Três regras vêm junto. Um rótulo fica numa revisão de cada vez, e uma revisão leva um rótulo;
acrescentar um rótulo a uma revisão que já tem um o substitui. Mover um rótulo para outra revisão
mantém o endereço, então quem testa guarda o mesmo favorito de uma versão para a outra. E um rótulo
não precisa de peso nenhum. Numa assinatura, o rótulo acima seria acrescentado com
`az containerapp revision label add --revision shop--v1-1 --label canary`, com o grupo de recursos,
não executado aqui.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 304\" role=\"img\" aria-label=\"O container app da loja durante um canário. Os clientes chamam o endereço do app, que manda 90 por cento das requisições para a revisão shop--v1-0, com quatro réplicas, e 10 por cento para a revisão shop--v1-1, com uma. Os três desenvolvedores chamam o endereço do rótulo, shop---canary, que chega à shop--v1-1 sejam quais forem os pesos. Tudo fica dentro do ambiente shop-env.\"><rect x=\"12\" y=\"52\" width=\"130\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"77\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">clientes</text><rect x=\"12\" y=\"196\" width=\"130\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"77\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">os três desenvolvedores</text><rect x=\"160\" y=\"12\" width=\"548\" height=\"280\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"174\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o ambiente</text><text x=\"694\" y=\"30\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">shop-env</text><rect x=\"180\" y=\"50\" width=\"200\" height=\"46\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"192\" y=\"65\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o endereço do app</text><text x=\"192\" y=\"83\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop.&lt;domain&gt;</text><rect x=\"180\" y=\"194\" width=\"200\" height=\"46\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"192\" y=\"209\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o endereço do rótulo</text><text x=\"192\" y=\"227\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop---canary.&lt;domain&gt;</text><rect x=\"500\" y=\"46\" width=\"196\" height=\"92\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"512\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">shop--v1-0</text><text x=\"512\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">SHOP_VERSION=1.0</text><rect x=\"512\" y=\"96\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"538\" y=\"96\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"564\" y=\"96\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"590\" y=\"96\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"624\" y=\"107\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">4 réplicas</text><rect x=\"500\" y=\"170\" width=\"196\" height=\"92\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"512\" y=\"188\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">shop--v1-1</text><rect x=\"616\" y=\"178\" width=\"70\" height=\"20\" rx=\"3\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"651\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">canary</text><text x=\"512\" y=\"206\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">SHOP_VERSION=1.1</text><rect x=\"512\" y=\"220\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"546\" y=\"231\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1 réplica</text><path d=\"M142 72 L172 72\" stroke=\"var(--paper-dim)\" stroke-width=\"1.8\" fill=\"none\"></path><path d=\"M180 72 L172 67.5 L172 76.5 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><path d=\"M142 216 L172 216\" stroke=\"var(--paper-dim)\" stroke-width=\"1.8\" fill=\"none\"></path><path d=\"M180 216 L172 211.5 L172 220.5 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><path d=\"M380 66 C430 66 450 80 492 80\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\" fill=\"none\"></path><path d=\"M500 80 L492 75.5 L492 84.5 Z\" fill=\"var(--phosphor)\" stroke=\"none\"></path><text x=\"436\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">90%</text><path d=\"M380 86 C440 86 440 196 492 196\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\"></path><path d=\"M500 196 L492 191.5 L492 200.5 Z\" fill=\"var(--amber)\" stroke=\"none\"></path><text x=\"430\" y=\"140\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">10%</text><path d=\"M380 222 L492 222\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\"></path><path d=\"M500 222 L492 217.5 L492 226.5 Z\" fill=\"var(--amber)\" stroke=\"none\"></path><text x=\"440\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">com qualquer peso</text></svg>", "caption": "A loja durante o canário. O endereço do app reparte os clientes entre duas revisões, cada uma escalada pela sua própria parte deles; o endereço do rótulo chega direto à revisão nova, com qualquer peso, inclusive 0.", "same": []}
```

## Blue/green

Blue/green são duas revisões e dois rótulos, e a Microsoft o documenta de ponta a ponta. A revisão
que os clientes usam leva o rótulo `blue` e todo o peso. A nova é implantada com o rótulo `green` e
peso 0. Os desenvolvedores a testam no endereço do rótulo. Quando está certa, uma mudança só leva o
peso inteiro para o outro lado, `--label-weight blue=0 green=100`, e **voltar atrás é o mesmo comando
ao contrário**, enquanto a revisão blue continuar ativa. A versão seguinte fica com o rótulo que a
antiga deixou, então os dois nomes se alternam e ninguém renomeia um favorito.

**O blue/green move todo mundo de uma vez**, e essa é a força e o risco dele. A troca é limpa, e um
rollback é um comando; mas no instante seguinte à troca, todo cliente está numa revisão que só quem
testou usou.

## Canário

Um canário move os clientes em passos, e o arquivo da loja é o segundo passo dele:

1. `shop--v1-0` tem todo o tráfego, e `shop--v1-1` é implantada ao lado com o rótulo `canary` e
   peso 0, e testada no endereço do rótulo;
2. os pesos passam a 90 e 10, e os erros e tempos de resposta das duas revisões são comparados;
3. 50 e 50, se nada piorou;
4. 0 e 100, e a revisão antiga fica ativa por um tempo, para que voltar atrás ainda seja um comando;
5. a revisão antiga é desativada, e daí em diante não custa nada.

Onde o blue/green confia nos testes, um canário confia nos clientes, poucos de cada vez. O que um
canário precisa é de clientes suficientes, e isso é aritmética.

## A aritmética dos dez por cento

A documentação define um peso como uma porcentagem do tráfego e não diz como cada requisição é
escolhida. A suposição segura para planejar é que **cada requisição vai para o canário com
probabilidade de uma em dez, independentemente das outras**. Com ela, o número que o canário recebe
em N requisições tem valor esperado N/10, e uma dispersão que a distribuição binomial dá. Este
programa calcula as duas coisas, para três tamanhos de amostra. Salve-o como `~/azure/split.py`:

```python
# split.py
import math

CANARY = 0.10  # the new revision's weight, as a share

for n in (20, 200, 2000):
    expected = n * CANARY
    spread = 2 * math.sqrt(n * CANARY * (1 - CANARY))
    none = (1 - CANARY) ** n
    print(f'{n:5} requests: {n - expected:5.0f} to v1-0, {expected:4.0f} to v1-1, '
          f'give or take {spread:2.0f}; none to v1-1: {none:.3f}')
```

`spread` são dois desvios-padrão, a distância dentro da qual a contagem cai mais ou menos 95 vezes
em 100. `none` é a chance de o canário não receber nada. Rodando:

```
ana@laptop:~/azure$ python3 split.py
   20 requests:    18 to v1-0,    2 to v1-1, give or take  3; none to v1-1: 0.122
  200 requests:   180 to v1-0,   20 to v1-1, give or take  8; none to v1-1: 0.000
 2000 requests:  1800 to v1-0,  200 to v1-1, give or take 27; none to v1-1: 0.000
```

**Vinte requisições não provam nada sobre um canário.** As duas esperadas podem ser qualquer coisa
de nenhuma a cinco, e uma vez em oito são nenhuma: o canário não foi testado, e o painel mostra uma
versão sem erros. Em 200 requisições, as 20 do canário variam 8 para mais ou para menos, o bastante
para notar uma versão que falha metade das vezes, e não uma que falha uma vez em cinquenta. Em 2.000,
as 200 variam 27, uma amostra que vale comparar. Para a loja, isso quer dizer que um canário é
julgado por um dia de tráfego, e não pelos primeiros minutos.
