---
title: Arquitetura de aplicação: o lado de dentro de um sistema
version: 1
---

"Arquitetura" é usada para três trabalhos diferentes, e boa parte das discussões sobre o que um
arquiteto faz são duas pessoas falando de trabalhos diferentes. **Os níveis são aplicação, solução
e corporativo, e eles diferem no escopo, em quão longe olham, em quem lê o resultado e no que fica
escrito.** Não são patentes. Um arquiteto corporativo não é um arquiteto de aplicação promovido, e
uma decisão dentro de um único serviço pode custar mais para desfazer do que qualquer item do
roadmap da empresa.

Esta aula percorre os três níveis na Carreto, o marketplace de frete fictício que este curso
acompanha. Renata Okubo é a arquiteta da empresa há poucas semanas, e a primeira coisa que ela
percebe é que a agenda dela tem os três tipos de trabalho ao mesmo tempo, sem que ninguém tenha
dito qual deles é dela.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 360\" role=\"img\" aria-label=\"Dois eixos. Na horizontal, o horizonte de tempo, de semanas a meses e a anos. Na vertical, o escopo, de um serviço a vários times e à empresa inteira. A arquitetura de aplicação fica embaixo e à esquerda: dentro de um serviço, olhando meses à frente. A arquitetura de solução fica no meio: um resultado atravessando vários times. A arquitetura corporativa fica em cima e à direita: o portfólio inteiro, olhando anos à frente.\"><defs><marker id=\"lvl-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M130 310 L700 310\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#lvl-ah)\"></path><path d=\"M130 310 L130 34\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#lvl-ah)\"></path><text x=\"138\" y=\"28\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">escopo</text><text x=\"700\" y=\"350\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">horizonte de tempo</text><text x=\"200\" y=\"330\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">semanas</text><text x=\"420\" y=\"330\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">meses</text><text x=\"600\" y=\"330\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">anos</text><text x=\"122\" y=\"262\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">um serviço</text><text x=\"122\" y=\"162\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">vários times</text><text x=\"122\" y=\"76\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">a empresa</text><rect x=\"160\" y=\"228\" width=\"190\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"255\" y=\"254\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"15\" font-weight=\"600\" fill=\"var(--phosphor)\">Aplicação</text><text x=\"255\" y=\"276\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">dentro de um serviço</text><rect x=\"330\" y=\"130\" width=\"200\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"430\" y=\"156\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"15\" font-weight=\"600\" fill=\"var(--amber)\">Solução</text><text x=\"430\" y=\"178\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">um resultado, vários times</text><rect x=\"490\" y=\"44\" width=\"200\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"590\" y=\"70\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"15\" font-weight=\"600\" fill=\"var(--paper)\">Corporativa</text><text x=\"590\" y=\"92\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">o portfólio inteiro</text></svg>", "caption": "Os três níveis diferem no escopo e em quão longe olham. Nenhum está acima dos outros; cada um responde a uma pergunta diferente para um leitor diferente."}
```

A figura é a aula num desenho só. Esta seção trata da caixa de baixo, a segunda seção da do meio e
a terceira da de cima, e cada uma termina com o jeito que aquele nível tem na semana da Renata.

## O que a arquitetura de aplicação decide

**Arquitetura de aplicação é a estrutura dentro de um sistema implantável**: os módulos dele e as
regras sobre quem pode chamar quem, as camadas, o modelo de dados, a forma como ele conversa com os
sistemas em volta e o que ele faz quando um deles falha. Na linguagem da aula 1, são os elementos,
as relações e o ambiente de uma única aplicação, vistos de dentro.

Pegue o Pricing, o serviço que cota o frete de cada carga que um embarcador publica. Visto de fora,
é uma caixa com um endpoint: você dá origem, destino, tipo de veículo e peso, e ele responde com um
preço. Por dentro, o time de Pricing tomou um punhado de decisões que moldam tudo o que vai
construir nos próximos dois anos:

- **A cotação é calculada em duas etapas.** Uma etapa de mercado estima quanto a carga renderia a
  partir de ofertas aceitas recentemente em rotas parecidas; uma etapa de piso aplica então o frete
  mínimo da ANTT para aquele veículo e aquela distância, e sobe o preço se a etapa de mercado ficou
  abaixo dele.
- **A etapa de piso é a única saída.** Nenhum caminho do código devolve um preço que não tenha
  passado por ela, então uma cotação abaixo do piso legal não sai do serviço por acidente. Essa
  regra é garantida pela estrutura do código, e não pela memória de cada pessoa.
- **O provedor de distâncias fica atrás de um adaptador.** O Pricing pede distâncias rodoviárias a
  uma interface interna, e o adaptador por trás dela conversa com uma API de rotas de fora. Trocar
  de provedor é reescrever um módulo.
- **A tabela da ANTT é dado, não código.** Quando a agência publica uma nova tabela de piso, o time
  carrega um arquivo e roda os testes; ninguém edita fórmula.

Nenhuma dessas escolhas aparece num diagrama da empresa, e todas são arquitetura pelo teste da
aula 1: cada uma custa caro para mudar depois que o resto do código passa a depender dela. Mudar a
checagem do piso de "a única saída" para "uma etapa que quem chama deve lembrar de rodar" seria um
diff pequeno e uma mudança grande, porque a propriedade que ela protege deixaria de ser garantida.

## Horizonte, público e artefatos

**O horizonte vai de meses a um ou dois anos**: mais ou menos a vida de uma versão principal do
serviço, ou o tempo até o time ter motivo para reestruturá-lo. Uma decisão neste nível supõe que o
propósito do serviço e os vizinhos dele continuam mais ou menos como estão.

**O público é o time que constrói o serviço e os times que o chamam.** Os primeiros precisam do lado
de dentro; os segundos precisam do contrato e do comportamento em falha, e de mais nada. O time
Shipper, que chama o Pricing para cada cotação que mostra, precisa saber que o Pricing responde
dentro do tempo combinado ou devolve um erro explícito. As duas etapas não servem para nada a ele.

**Os artefatos ficam perto do código.** Um diagrama de componentes do interior do serviço (o
terceiro nível do C4, que `architecture-modeling` aula 3 desenha direito e a aula 8 deste curso
apresenta), o contrato da API, as fronteiras entre módulos escritas como regras que um build
consegue checar (a aula 9 mostra um programa que garante uma delas) e os registros de decisão no
próprio repositório do serviço. O Pricing guarda os quatro no repositório dele, e o diagrama é curto
o bastante para ser redesenhado em dez minutos.

## Quem faz, e onde a Renata entra

**Na Carreto, a arquitetura de aplicação pertence aos times.** Cada um dos sete tem um tech lead e
engenheiros seniores que conhecem o próprio serviço melhor do que qualquer outra pessoa, e eles
tomam essas decisões como parte do trabalho. É o processo de aconselhamento da aula 3 fazendo o que
deve fazer: quem vai conviver com a decisão a toma, depois de ouvir as pessoas que ela afeta.

A parte da Renata neste nível é menor do que se imagina. Ela revisa quando pedem, avisa quando uma
escolha interna de um time está prestes a vazar para fora do serviço e fica de olho no punhado de
regras que todo serviço deveria compartilhar. No primeiro mês ela gastou cerca de um dia por semana
nisso, quase tudo em revisões de design que outras pessoas tinham pedido.

O vazamento é a parte que mais importa. **Uma decisão de aplicação vira algo maior quando as
consequências dela atravessam a fronteira do serviço**, e o time que a toma nem sempre vê isso
acontecer. O time de Matching da Kátia Lemos, por exemplo, quis guardar em cache dentro do Matching
as cotações do Pricing por uma hora, para parar de chamar o Pricing toda vez que uma carga era
oferecida a outro motorista. Uma escolha interna razoável, até a Renata perguntar o que acontece
quando a ANTT publica uma nova tabela de piso às nove da manhã: por até uma hora, o Matching estaria
oferecendo cargas a preços que já não respeitavam o mínimo legal.

A correção foi pequena. O Pricing agora devolve um prazo de validade com cada cotação, e o Matching
guarda em cache por no máximo esse tempo. A decisão que importou foi sobre onde a correção devia
morar. Um cache dentro do Matching parece assunto do Matching, enquanto a regra que ele poderia
quebrar pertence ao Pricing, e o contrato entre os dois é algo que nenhum dos times tem sozinho.
**Esse vão entre times é o nível de cima**, e a segunda seção desta aula trata dele.

## Um teste para o nível de uma decisão

Quando uma pergunta chega à mesa da Renata, ela faz três perguntas para situá-la:

1. **A mudança fica dentro de um único sistema implantável?** Se fica, é arquitetura de aplicação,
   e o time decide.
2. **Ela muda aquilo em que outros sistemas podem confiar**, como um contrato, um evento, uma
   garantia ou um tempo? Então é no mínimo arquitetura de solução, mesmo que só um time escreva
   código.
3. **Ela muda o que a empresa roda ou como todos os times trabalham**, como uma plataforma
   compartilhada, um padrão ou um sistema que vai ser desligado? Então é arquitetura corporativa.

O cache do Matching falhou na primeira pergunta e passou na segunda, e por isso uma decisão que
parecia interna a um time terminou numa mudança no contrato do Pricing. A aula 6 volta a essa linha,
entre as decisões que são de arquitetura e as que pertencem ao time, com um teste mais completo.
