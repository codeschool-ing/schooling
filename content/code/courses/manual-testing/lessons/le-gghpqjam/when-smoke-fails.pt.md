---
title: Quando a fumaça falha
version: 1
---

Uma rodada de fumaça que falhou convida a dois erros opostos: seguir em frente com as partes que
parecem funcionar, ou escrever um relatório de defeito para cada linha que diz `FAIL`. **Uma rodada
de fumaça que falhou é um achado só sobre a versão, e o plano já diz o que acontece em seguida**: o
teste para naquilo que ela atinge, o desenvolvedor fica sabendo na hora, e nada recomeça até uma
versão nova passar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 300\" role=\"img\" data-fig=\"l08-smoke-gate\" aria-label=\"Um fluxo. Uma versão nova vai para a fumaça, cinco checagens que levam um minuto. Se todas passam, a aplicação é reiniciada e o teste planejado começa: casos, sanidade, regressão. Se alguma falha, a primeira pergunta é se a causa é o seu laboratório ou a versão. Se for o laboratório, conserte e rode a fumaça de novo. Se for a versão, suspenda o teste e avise o desenvolvedor uma vez, e então espere a próxima versão, que vai de novo para a fumaça.\"><defs><marker id=\"mt-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"mt-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"mt-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"30.0\" width=\"140.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"53.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">uma versão nova</text><rect x=\"220.0\" y=\"26.0\" width=\"170.0\" height=\"54.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"305.0\" y=\"45.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">fumaça</text><text x=\"305.0\" y=\"60.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">cinco checagens, um minuto</text><rect x=\"450.0\" y=\"26.0\" width=\"230.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"565.0\" y=\"45.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">reiniciar, e então o teste planejado</text><text x=\"565.0\" y=\"60.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">casos, sanidade, regressão</text><path d=\"M162.0 53.0 L216.0 53.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><path d=\"M392.0 53.0 L446.0 53.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-phosphor)\"></path><text x=\"419.0\" y=\"43.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">todas passam</text><rect x=\"220.0\" y=\"130.0\" width=\"170.0\" height=\"42.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"305.0\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">seu laboratório, ou a versão?</text><path d=\"M305.0 82.0 L305.0 126.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-amber)\"></path><text x=\"298.0\" y=\"104.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">alguma falha</text><rect x=\"450.0\" y=\"126.0\" width=\"230.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"565.0\" y=\"143.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">seu laboratório: conserte</text><text x=\"565.0\" y=\"158.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">e rode a fumaça de novo</text><path d=\"M392.0 151.0 L446.0 151.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><text x=\"419.0\" y=\"141.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o laboratório</text><path d=\"M565 124 L565 104 L360 104 L360 84\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#mt-ah-paper-dim)\"></path><rect x=\"220.0\" y=\"226.0\" width=\"170.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"305.0\" y=\"243.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">suspender, e avisar</text><text x=\"305.0\" y=\"258.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o desenvolvedor uma vez</text><path d=\"M305.0 174.0 L305.0 222.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-amber)\"></path><text x=\"312.0\" y=\"198.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">a versão</text><rect x=\"20.0\" y=\"230.0\" width=\"140.0\" height=\"42.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"251.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">esperar a próxima versão</text><path d=\"M218.0 251.0 L164.0 251.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><path d=\"M90.0 228.0 L90.0 80.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path></svg>", "caption": "A fumaça como portão. Nada depois dela começa numa versão que não passou por ela, e uma versão nova passa por ela desde o início."}
```

## Cinco linhas, uma causa

Rui avisa que uma versão nova está pronta; Ana a inicia e roda a lista de fumaça. Para ver o que ela
viu, pare o boxoffice com Ctrl-C no terminal dele e rode o script de novo:

```
ana@laptop:~/boxoffice$ sh smoke.sh; echo $?
FAIL  the server answers
FAIL  the home page lists three shows
FAIL  the sign-up page loads
FAIL  one booking goes through
FAIL  the outbox opens
5 of 5 checks failed
1
```

Cinco falhas e um código 1. Não são cinco defeitos. Quando todas as checagens falham, inclusive a
primeira, a explicação mais provável é que nada está respondendo, e um pedido só confirma:

```
ana@laptop:~/boxoffice$ curl http://127.0.0.1:8000/health
curl: (7) Failed to connect to 127.0.0.1 port 8000 after 0 ms: Couldn't connect to server
```

Nada está escutando na porta 8000. É a primeira checagem falhando, e as outras quatro falhando por
causa dela.

## Primeiro, descarte o seu laboratório

Antes de dizer a alguém que a versão está quebrada, Ana se certifica de que é a versão. `Couldn't
connect to server` é uma das falhas que a seção 05 da aula 1 cobre: o servidor nunca foi iniciado,
foi parado, ou parou com um erro. O terminal onde o boxoffice roda responde qual. Se a última linha
é o Ctrl-C da própria Ana, ou se o programa foi iniciado em outro diretório, o problema é o
laboratório, e a correção é dela. Na sua própria rodada acima foi exatamente isso, o Ctrl-C que você
apertou. No caso de Ana a versão foi iniciada direito e o terminal dela mostra o programa terminando
com um traceback, então **a versão não inicia**, e isso é notícia para Rui.

O mesmo hábito vale para uma falha isolada. Uma checagem de reserva que falha enquanto as outras
quatro passam merece uma segunda rodada e uma olhada no navegador antes de ser relatada. Se a
checagem reserva um espetáculo cujas reservas já fecharam, a checagem está errada. Se ela passa na
segunda rodada sem nada mudar, isso é um achado à parte, uma versão que falha às vezes.

## Depois, o plano

O plano da aula 1 dá o critério de suspensão do boxoffice: **a versão não inicia, ou um quarto dos
casos de uma área falha**. Uma versão que não inicia cumpre a primeira metade, então o teste para
nela inteira. Uma versão em que só a checagem de reserva falha cumpre o espírito da segunda: a
reserva é a área por onde passa a maior parte dos casos, entre eles os casos de desconto do risco A e
os de pedido do risco C, então essas áreas param. Casos de cadastro que nunca reservam nada podem
continuar, e o plano é onde esse julgamento fica escrito, em vez de ser feito do zero numa manhã
tensa.

Suspensão não é ficar parado. Ana volta ao trabalho que não precisa de uma versão: escrever os casos
da próxima funcionalidade, revisar requisitos como a aula 6 fez, preparar dados.

## Depois, avise Rui uma vez

Uma mensagem, mandada na hora, com o que Rui precisa para agir e nada sobre o que ele tenha de
perguntar:

- qual versão: o número e de onde ela veio, já que o `/health` não consegue dizer quando está fora do
  ar;
- a saída da fumaça, colada como foi impressa, cinco linhas e a contagem;
- o que Ana conferiu do lado dela, aqui que o servidor foi iniciado a partir do arquivo novo em
  `~/boxoffice` e parou com o traceback no terminal, que ela também cola;
- o que está suspenso, e que o teste recomeça na próxima versão que passar na fumaça.

Isso é um relatório sobre um problema. A aula 15 trata de escrever relatórios de defeito em geral, e
a mesma regra vale lá: uma causa, um relatório, por mais checagens que ela tenha derrubado.

## E quando a próxima versão chega

**A retomada também tem um critério**, a outra metade da suspensão: uma versão nova que passa na
lista de fumaça inteira. Ana reinicia o boxoffice a partir do arquivo novo, roda a lista, vê cinco
aprovações e um código 0, e reinicia mais uma vez para limpar o pedido que a checagem de fumaça
deixou. Aí o teste que tinha parado continua de onde estava, começando pelos casos que estavam
bloqueados.

O que ela não faz é remendar a versão por conta própria para passar da falha, nem reiniciá-la até
uma rodada passar por acaso. As duas coisas produzem uma versão que não é a que Rui mandou, e todo
resultado depois disso é um resultado sobre algo que ninguém entregou.
