---
title: Pedaços de texto numerados
version: 1
---

É natural supor que um modelo lê como você, letra por letra ou palavra por palavra. Ele não lê de
nenhum dos dois jeitos. **Antes de o modelo ver qualquer texto, um tokenizador corta esse texto em
pedaços tirados de uma lista fixa e troca cada pedaço pelo número dele nessa lista.** Os pedaços
são os tokens, a lista é o vocabulário, e os números são tudo o que o modelo recebe.

O `tok` é um tokenizador de verdade, o mesmo código que sistemas em produção rodam antes de um
pedido chegar ao modelo. O `tok show` imprime os pedaços entre aspas, depois os números deles,
depois a contagem:

```
ana@lab:~/pe$ tok show "The kitchen stops taking hot food orders thirty minutes before closing."
"The" " kitchen" " stops" " taking" " hot" " food" " orders" " thirty" " minutes" " before" " closing" "."
976 10084 29924 6167 3648 4232 12528 37650 5438 2254 23436 13
12 tokens, 71 characters (o200k_base)
```

Doze palavras e um ponto final, doze tokens. Cada palavra é um pedaço, e **o espaço antes de uma
palavra faz parte do token**: o pedaço é `" kitchen"`, com espaço, e o número dele é 10084. `"The"`
não tem espaço porque abre o texto. Os números não significam nada por si; 976 é só a posição de
`"The"` na lista.

A mesma frase em português:

```
ana@lab:~/pe$ tok show "A cozinha para de aceitar pedidos de comida quente trinta minutos antes de fechar."
"A" " cozinha" " para" " de" " aceitar" " pedidos" " de" " comida" " quente" " tr" "inta" " minutos" " antes" " de" " fechar" "."
32 66509 1209 334 136247 88184 334 46215 109042 498 11405 22491 13290 334 128464 13
16 tokens, 82 characters (o200k_base)
```

Dezesseis tokens. A maioria das palavras continua sendo um pedaço só, mas `trinta` saiu como
`" tr"` e `"inta"`. O vocabulário tem um token para `" cozinha"` e nenhum para `" trinta"`, então o
tokenizador soletrou a palavra com dois pedaços menores que ele tem.

## O comum fica inteiro, o raro é soletrado

Quais palavras ganham um token próprio depende de quão comuns elas eram no texto a partir do qual o
tokenizador foi construído. Uma palavra que não é comum o bastante é cortada em pedaços que são:

```
ana@lab:~/pe$ tok show "sourdough"
"s" "ourd" "ough"
82 43170 1870
3 tokens, 9 characters (o200k_base)
ana@lab:~/pe$ tok show "https://example.com/menu?day=sunday"
"https" "://" "example" ".com" "/menu" "?" "day" "=s" "unday"
4172 1684 18582 1136 90042 30 1635 32455 8514
9 tokens, 35 characters (o200k_base)
ana@lab:~/pe$ tok show "if price > 100: approve()"
"if" " price" " >" " " "100" ":" " approve" "()"
366 3911 1424 220 1353 25 45828 416
8 tokens, 25 characters (o200k_base)
```

`sourdough` é uma palavra comum do inglês e mesmo assim dá três pedaços. O endereço dá nove,
cortado onde endereços costumam ser cortados, em `://` e `.com`, até `sunday` chegar grudado no
`=` de antes e sair como `"=s"` e `"unday"`. A linha de código dá oito, e um deles é um espaço
sozinho.

**O corte depende dos caracteres exatos**, inclusive dos que você nem pensaria em ver como
diferentes:

```
ana@lab:~/pe$ tok show "seven"; tok show "SEVEN"
"seven"
153671
1 tokens, 5 characters (o200k_base)
"SE" "VEN"
1529 70318
2 tokens, 5 characters (o200k_base)
ana@lab:~/pe$ tok show " strawberry"; tok show "strawberry"
" strawberry"
101830
1 tokens, 11 characters (o200k_base)
"st" "raw" "berry"
302 1618 19772
3 tokens, 10 characters (o200k_base)
```

`seven` é um token e `SEVEN` são dois. `" strawberry"`, com o espaço, é um token, o número 101830,
e `strawberry` sem espaço são três. Para você é a mesma palavra; para o modelo são sequências de
números diferentes, que ele aprendeu separadamente.

## Por que pedaços, e não palavras ou letras

Há duas alternativas óbvias, e as duas falham. **Um vocabulário de palavras inteiras** precisaria
de um número para cada palavra de cada língua, cada nome e cada erro de digitação, e mesmo assim
encontraria palavras que nunca viu. **Um vocabulário de letras soltas** soletraria qualquer coisa,
e deixaria todo texto várias vezes mais longo, o que importa porque tudo o que um modelo faz é
cobrado por token.

Os pedaços ficam entre os dois. O método que a maioria dos tokenizadores usa, o byte-pair encoding,
começa de bytes soltos e junta, repetidamente, o par que mais aparece num grande volume de texto,
até a lista chegar ao tamanho que lhe foi dado. Palavras frequentes acabam inteiras; as raras são
soletradas com fragmentos; e como os bytes soltos continuam na lista, **qualquer texto pode ser
escrito, por mais incomum que seja**. Nada fica "fora do vocabulário". O pior caso é custar mais
tokens.

## Dois vocabulários, duas contagens

A codificação que o `tok` usa, a menos que você peça outra, é a `o200k_base`. A OpenAI a publica
junto com uma mais antiga, a `cl100k_base`, e o número em cada nome é mais ou menos o tamanho do
vocabulário: uns duzentos mil pedaços e uns cem mil. Dá para ver isso nos ids acima, que passam de
150.000. Eis a frase em português cortada pelo vocabulário menor:

```
ana@lab:~/pe$ tok show "A cozinha para de aceitar pedidos de comida quente trinta minutos antes de fechar." -e cl100k_base
"A" " coz" "inha" " para" " de" " ace" "itar" " ped" "idos" " de" " comida" " qu" "ente" " tr" "inta" " minutos" " antes" " de" " fe" "char" "."
32 85920 44338 3429 409 27845 12635 10696 13652 409 98878 934 6960 490 34569 52762 34435 409 1172 1799 13
21 tokens, 82 characters (cl100k_base)
```

Vinte e um tokens onde a `o200k_base` precisou de dezesseis. `cozinha`, `aceitar`, `pedidos`,
`quente` e `fechar` perderam o lugar de palavras inteiras. A frase em inglês não mudou:

```
ana@lab:~/pe$ tok show "The kitchen stops taking hot food orders thirty minutes before closing." -e cl100k_base
"The" " kitchen" " stops" " taking" " hot" " food" " orders" " thirty" " minutes" " before" " closing" "."
791 9979 18417 4737 4106 3691 10373 27219 4520 1603 15676 13
12 tokens, 71 characters (cl100k_base)
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"A frase A cozinha para de aceitar pedidos de comida quente trinta minutos antes de fechar, mostrada duas vezes como fileiras de caixas, uma caixa por token. Com o o200k_base são 16 pedaços: cada palavra é um pedaço, menos trinta, cortada em tr e inta. Com o cl100k_base são 21 pedaços: cozinha, aceitar, pedidos, quente, trinta e fechar são cortadas em duas.\"><text x=\"14\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">o200k_base</text><text x=\"110\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">16 pedaços</text><rect x=\"14\" y=\"42\" width=\"13.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"20.5\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">A</text><rect x=\"33.0\" y=\"42\" width=\"49.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"57.5\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">cozinha</text><rect x=\"88.0\" y=\"42\" width=\"31.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"103.5\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">para</text><rect x=\"125.0\" y=\"42\" width=\"19.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"134.5\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">de</text><rect x=\"150.0\" y=\"42\" width=\"49.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"174.5\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">aceitar</text><rect x=\"205.0\" y=\"42\" width=\"49.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"229.5\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">pedidos</text><rect x=\"260.0\" y=\"42\" width=\"19.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"269.5\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">de</text><rect x=\"285.0\" y=\"42\" width=\"43.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"306.5\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">comida</text><rect x=\"334.0\" y=\"42\" width=\"43.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"355.5\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">quente</text><rect x=\"383.0\" y=\"42\" width=\"19.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"392.5\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">tr</text><rect x=\"403.5\" y=\"42\" width=\"31.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"419.0\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">inta</text><rect x=\"440.5\" y=\"42\" width=\"49.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"465.0\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">minutos</text><rect x=\"495.5\" y=\"42\" width=\"37.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"514.0\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">antes</text><rect x=\"538.5\" y=\"42\" width=\"19.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"548.0\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">de</text><rect x=\"563.5\" y=\"42\" width=\"43.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"585.0\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">fechar</text><rect x=\"612.5\" y=\"42\" width=\"13.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"619.0\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">.</text><text x=\"14\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">cl100k_base</text><text x=\"118\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">21 pedaços</text><rect x=\"14\" y=\"112\" width=\"13.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"20.5\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">A</text><rect x=\"33.0\" y=\"112\" width=\"25.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"45.5\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">coz</text><rect x=\"59.5\" y=\"112\" width=\"31.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"75.0\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">inha</text><rect x=\"96.5\" y=\"112\" width=\"31.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"112.0\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">para</text><rect x=\"133.5\" y=\"112\" width=\"19.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"143.0\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">de</text><rect x=\"158.5\" y=\"112\" width=\"25.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"171.0\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">ace</text><rect x=\"185.0\" y=\"112\" width=\"31.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"200.5\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">itar</text><rect x=\"222.0\" y=\"112\" width=\"25.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"234.5\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">ped</text><rect x=\"248.5\" y=\"112\" width=\"31.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"264.0\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">idos</text><rect x=\"285.5\" y=\"112\" width=\"19.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"295.0\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">de</text><rect x=\"310.5\" y=\"112\" width=\"43.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"332.0\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">comida</text><rect x=\"359.5\" y=\"112\" width=\"19.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"369.0\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">qu</text><rect x=\"380.0\" y=\"112\" width=\"31.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"395.5\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">ente</text><rect x=\"417.0\" y=\"112\" width=\"19.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"426.5\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">tr</text><rect x=\"437.5\" y=\"112\" width=\"31.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"453.0\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">inta</text><rect x=\"474.5\" y=\"112\" width=\"49.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"499.0\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">minutos</text><rect x=\"529.5\" y=\"112\" width=\"37.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"548.0\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">antes</text><rect x=\"572.5\" y=\"112\" width=\"19.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"582.0\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">de</text><rect x=\"597.5\" y=\"112\" width=\"19.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"607.0\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">fe</text><rect x=\"618.0\" y=\"112\" width=\"31.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"633.5\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">char</text><rect x=\"655.0\" y=\"112\" width=\"13.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"661.5\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">.</text><rect x=\"14\" y=\"166\" width=\"14\" height=\"12\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"34\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">uma palavra inteira, com o espaço</text><rect x=\"300\" y=\"166\" width=\"14\" height=\"12\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"320\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">uma palavra, cortada</text></svg>", "caption": "Uma frase em português, cortada pelas duas codificações. O vocabulário maior mantém mais palavras inteiras; o mais antigo as soletra com pedaços menores, e a frase custa cinco tokens a mais."}
```

**Um vocabulário maior, construído com mais texto em mais línguas, fecha parte da diferença para
as línguas que não são o inglês**, e não fecha toda: o português ainda levou dezesseis tokens onde
o inglês levou doze. A próxima seção conta arquivos inteiros, e lá a diferença vira dinheiro.

No momento em que este curso foi escrito (2026), os modelos mais novos da OpenAI usam a
`o200k_base` e os mais antigos, a `cl100k_base`. Outros provedores usam tokenizadores próprios;
alguns os publicam, e outros só contam os tokens para você pela API. **A contagem de um tokenizador
é uma estimativa para qualquer outro**, e é por isso que as contagens deste curso sempre dizem de
qual codificação vieram. Para saber qual um modelo usa, procure na documentação do provedor sobre
aquele modelo, e confira a data da página.
