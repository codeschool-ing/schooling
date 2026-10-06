---
title: A pirâmide de testes, medida
version: 1
---

A **pirâmide de testes** é um desenho de como uma suíte saudável se distribui: muitos testes
unitários na base, menos testes de integração acima, e um punhado de testes funcionais e de
aceitação no topo. Costuma ser desenhada de intuição. O `shipquote` deixa desenhá-la de medições,
porque cada teste carrega um marcador com o nome da sua camada.

```
ana@laptop:~/shipquote$ python -m pytest -q -m "not integration and not functional and not acceptance"
........................                                                 [100%]
24 passed, 7 deselected in 0.17s
ana@laptop:~/shipquote$ python -m pytest -q -m "integration or functional or acceptance"
.......                                                                  [100%]
7 passed, 24 deselected in 1.21s
ana@laptop:~/shipquote$ python -m pytest -q --durations=4
...............................                                          [100%]
============================= slowest 4 durations ==============================
0.50s teardown tests/test_app.py::test_a_bad_cep_is_a_400_that_says_why
0.50s teardown tests/test_acceptance.py::test_a_basket_of_199_reais_ships_free_to_every_region
0.03s call     tests/test_acceptance.py::test_a_basket_of_199_reais_ships_free_to_every_region

(1 durations < 0.005s hidden.  Use -vv to show these durations.)
31 passed in 1.23s
```

O primeiro comando roda tudo o que **não** está marcado como uma das camadas mais lentas: 24
testes unitários em 0,17 segundo. O segundo roda os outros 7, e eles levam 1,21 segundo. Sete
testes custam sete vezes o que vinte e quatro custam.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A suíte do shipquote desenhada como uma pirâmide de três faixas. A faixa larga de baixo tem 24 testes unitários, que rodam juntos em 0,17 segundo. A faixa do meio tem 3 testes de integração e a faixa estreita do topo 4 testes funcionais e de aceitação; esses 7 rodam juntos em 1,21 segundo.\"><path d=\"M360 30 L440 110 L280 110 Z\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><path d=\"M280 110 L440 110 L520 190 L200 190 Z\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></path><path d=\"M200 190 L520 190 L600 270 L120 270 Z\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><text x=\"360\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--amber)\">4</text><text x=\"360\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor-dim)\">3</text><text x=\"360\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">24</text><path d=\"M420 80 L470 80\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"476\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">funcionais e de aceitação</text><path d=\"M490 150 L530 150\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"536\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">integração</text><path d=\"M570 232 L600 232\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"606\" y=\"232\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">unitários</text><path d=\"M250 34 L240 34 L240 186 L250 186\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"232\" y=\"102\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">1.21 s</text><text x=\"232\" y=\"120\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">para estes 7</text><path d=\"M170 194 L160 194 L160 266 L170 266\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"152\" y=\"222\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">0.17 s</text><text x=\"152\" y=\"240\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">para estes 24</text><text x=\"360\" y=\"292\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">muitos testes rápidos embaixo, poucos lentos em cima</text></svg>", "caption": "Os números da própria suíte. Sete testes no topo custam sete vezes o que vinte e quatro custam na base, e é por isso que a forma é larga embaixo."}
```

## Para onde o tempo vai

`--durations=4` lista as quatro fases mais lentas da execução, e a resposta não é a que a maioria
espera. **As duas entradas mais lentas são desmontagens (teardown), de 0,50 segundo cada**, e não
requisições. Elas pertencem à fixture `base_url`: `server.shutdown()` espera o laço do servidor
perceber que deve parar, e o `serve_forever` do Python confere isso a cada meio segundo por padrão.
A fixture tem escopo de módulo e dois módulos a usam, então a suíte paga o meio segundo duas vezes.
As requisições em si custam 0,03 segundo para o teste de aceitação inteiro, seis cotações incluídas.

É um achado típico. A parte lenta de um teste de alto nível raramente é a verificação; é montar e
desmontar um mundo para o teste rodar: um servidor, um navegador, um banco com esquema. **Esse
custo é por teste ou por módulo, então se multiplica com o número de testes**, e esse é o argumento
inteiro para manter estreito o topo da pirâmide.

## A forma é um orçamento, não uma lei

A pirâmide diz onde gastar testes, e o motivo é custo e precisão:

- **Camadas mais baixas são mais baratas e apontam mais perto da causa.** Um unitário vermelho
  nomeia uma regra; um funcional vermelho nomeia um endpoint.
- **Camadas mais altas veem o que as baixas não veem**, a ligação entre as peças, então uma suíte
  sem nenhuma delas fica verde no dia em que nada sobe.

Duas outras formas têm nome e vale reconhecê-las. O **cone de sorvete** é a pirâmide de cabeça para
baixo: a maioria das verificações é de ponta a ponta, muitas vezes manual, e há poucos testes
unitários. Acontece quando o teste começa depois do código pronto e só o lado de fora é alcançável.
É lento, instável e não aponta para lugar nenhum quando falha. O **troféu de testes** alarga o
meio, com o argumento de que, para código que é quase todo cola entre serviços, testes de
integração compram mais confiança por segundo. Os dois discutem a mesma troca, e para um código com
regras de verdade, como preços com bordas, a base larga compensa.

**O que importa é você conhecer a forma da sua suíte e o porquê.** Contar testes por marcador, como
acima, custa um comando. Se a camada de cima concentra a maior parte do tempo e dos testes, a suíte
vai ser lenta a cada push e a equipe vai começar a pulá-la, e a aula 5 mostra o que um pipeline faz
com uma suíte lenta.

Na trilha `qa`, a aula 21 de `web-automation` olha a mesma pirâmide pelo lado do navegador, onde a
camada de cima custa muito mais do que aqui.
