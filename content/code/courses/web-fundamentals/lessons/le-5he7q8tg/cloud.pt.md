---
title: Três tamanhos de responsabilidade
version: 1
---

*A nuvem* não é uma tecnologia. São as máquinas de outra pessoa, alugadas por hora, com uma interface
que deixa você pedir mais uma sem falar com ninguém.

Essa última parte é a inovação inteira. Comprar um servidor era uma compra e uma entrega; agora é uma
chamada que volta em noventa segundos, e que pode ser desfeita igualmente rápido. Todo o resto desta
leitura decorre dessa única mudança.

## As três camadas, pelo que continua sendo seu

As categorias têm nomes pouco úteis, então leia como uma linha em que a sua responsabilidade encolhe.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Três camadas com a responsabilidade encolhendo: com infraestrutura o sistema operacional, o runtime e a aplicação são seus; com uma plataforma apenas a aplicação é; com funções apenas um pedaço de código é, e nada roda entre as chamadas.\"> <text x=\"128\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">infraestrutura</text> <text x=\"360\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">plataforma</text> <text x=\"592\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">funções</text> <rect x=\"20\" y=\"34\" width=\"216\" height=\"34\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".22\" stroke=\"var(--phosphor)\"></rect> <text x=\"128\" y=\"51\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">seu código</text> <rect x=\"252\" y=\"34\" width=\"216\" height=\"34\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".22\" stroke=\"var(--phosphor)\"></rect> <text x=\"360\" y=\"51\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">seu código</text> <rect x=\"484\" y=\"34\" width=\"216\" height=\"34\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".22\" stroke=\"var(--phosphor)\"></rect> <text x=\"592\" y=\"51\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">um pedaço do seu código</text> <rect x=\"20\" y=\"76\" width=\"216\" height=\"34\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".22\" stroke=\"var(--phosphor)\"></rect> <text x=\"128\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o runtime, seu</text> <rect x=\"252\" y=\"76\" width=\"216\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\"></rect> <text x=\"360\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o runtime, deles</text> <rect x=\"484\" y=\"76\" width=\"216\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\"></rect> <text x=\"592\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o runtime, deles</text> <rect x=\"20\" y=\"118\" width=\"216\" height=\"34\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".22\" stroke=\"var(--phosphor)\"></rect> <text x=\"128\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o sistema operacional, seu</text> <rect x=\"252\" y=\"118\" width=\"216\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\"></rect> <text x=\"360\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">deles</text> <rect x=\"484\" y=\"118\" width=\"216\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\"></rect> <text x=\"592\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">deles</text> <rect x=\"20\" y=\"160\" width=\"216\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\"></rect> <text x=\"128\" y=\"177\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o hardware, deles</text> <rect x=\"252\" y=\"160\" width=\"216\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\"></rect> <text x=\"360\" y=\"177\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">deles</text> <rect x=\"484\" y=\"160\" width=\"216\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\"></rect> <text x=\"592\" y=\"177\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">deles, e ocioso não custa</text> <text x=\"360\" y=\"238\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\">a mesma troca em cada passo: menos controle, menos trabalho</text> <text x=\"360\" y=\"268\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">e mais da sua arquitetura decidida por alguém cujos interesses não são os seus</text> </svg>", "caption": "Leia os nomes como posições numa linha: quanto da máquina continua sendo problema seu."}
```

**Infraestrutura** — uma máquina, um disco, uma rede, por hora. É a leitura anterior com um botão em
vez de uma nota fiscal. O sistema operacional, as atualizações, o servidor web e a aplicação são
todos seus.

**Plataforma** — você entrega seu código e o provedor o roda. Ele constrói, dá um runtime, põe atrás
de um balanceador, e emite o certificado. Você deixa de escolher um sistema operacional e deixa de
aplicar atualizações; também deixa de conseguir instalar o que quiser.

**Funções**, muitas vezes vendidas como serverless — você entrega um único pedaço de código e ele é
executado quando algo o chama. Não há máquina nenhuma no seu modelo mental: nenhum processo que fique
de pé, nenhum disco em que confiar entre chamadas, e nada rodando quando ninguém está pedindo.

A troca é a mesma em cada passo. Menos controle, menos trabalho, e mais da sua arquitetura decidida
por alguém cujos interesses não são idênticos aos seus.

## O que alugar por hora de fato muda

Duas coisas, e elas importam mais que a camada que você escolheu.

**Capacidade virou uma decisão que dá para mudar.** A alternativa a adivinhar quanta máquina você
precisa ano que vem é comprar o que precisa esta semana e acrescentar mais no dia em que precisar. É
por isso que o modelo venceu, e é a razão de uma empresa sobreviver a sair no noticiário.

**O custo virou uma variável**, o que não é automaticamente uma melhoria. Um servidor mensal fixo tem
uma conta que dá para prever. A cobrança por hora tem uma conta que segue seu tráfego — e,
ocasionalmente, seu erro. Um laço que chama um serviço pago, uma tarefa que busca um arquivo quarenta
mil vezes, uma cópia de segurança mal configurada: o número que chega no fim do mês é real, e existe
um gênero bem gasto de histórias sobre isso.

Qualquer um trabalhando assim deveria configurar um **alarme de orçamento** antes de escrever código.
Dez minutos, uma vez, e isso converte uma catástrofe numa mensagem.

## Onde o serverless se paga, e onde não

Vale ser concreto, porque é a camada mais supervendida.

Ele é genuinamente bom em trabalho **ocasional e em rajada**: um formulário enviado duas vezes por
hora, uma imagem redimensionada no envio, uma tarefa agendada. Nada roda entre as chamadas, então nada
é pago entre as chamadas, e dez mil de uma vez é problema do provedor em vez de seu.

Ele serve mal para trabalho **constante**, onde um servidor pequeno é mais barato e mais simples; para
qualquer coisa que precise guardar estado entre chamadas, já que não há lugar confiável para pô-lo; e
para qualquer coisa com uma conexão de vida longa, para a qual o modelo não tem formato.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Trabalho ocasional e em rajada combina com funções, porque nada é pago entre as chamadas. Trabalho constante, com estado ou de vida longa não combina, porque um servidor pequeno sai mais barato e o modelo não tem formato para isso.\"> <text x=\"180\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">serve bem</text> <rect x=\"20\" y=\"36\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"180\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">um formulário enviado duas vezes por hora</text> <rect x=\"20\" y=\"82\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"180\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">uma imagem redimensionada no envio</text> <rect x=\"20\" y=\"128\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"180\" y=\"147\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">dez mil de uma vez, de vez em quando</text> <text x=\"540\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--amber)\">serve mal</text> <rect x=\"380\" y=\"36\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect> <text x=\"540\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">carga constante, onde um servidor sai mais barato</text> <rect x=\"380\" y=\"82\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect> <text x=\"540\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">qualquer coisa que guarde estado entre chamadas</text> <rect x=\"380\" y=\"128\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect> <text x=\"540\" y=\"147\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">uma conexão de vida longa</text> <text x=\"360\" y=\"204\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">e a partida a frio, que cai em quem chegar primeiro</text> <text x=\"360\" y=\"232\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">num serviço calmo, isso é cada visitante</text> </svg>", "caption": "Nada roda entre as chamadas. Essa é a vantagem inteira e a limitação inteira."}
```

E ele tem uma propriedade que vale conhecer pelo nome: a **partida a frio**. Quando nada roda há um
tempo, a primeira chamada espera um runtime ser criado. Em geral é uma fração de segundo e às vezes
bem pior, e cai em quem chegar primeiro — que, num serviço calmo, é cada visitante.

## As partes que você aluga em vez de operar

A parte disto que mais muda o trabalho diário não é a computação. É que tudo que um servidor tinha
dentro pode ser alugado à parte: um banco de dados, armazenamento de objetos, uma fila, um cache, um
enviador de e-mail.

Um banco gerenciado é o caso mais claro. Outra pessoa tira as cópias, aplica as atualizações, e mantém
uma segunda cópia pronta. Custa várias vezes o que o mesmo banco custa na sua própria máquina, e o
jeito honesto de comparar é contra as horas que você gastaria nessas três coisas — e contra o custo de
descobrir, durante um incidente, que você não fez nenhuma.

## Aprisionamento, dito com franqueza

A palavra é usada como acusação, e a realidade é um espectro que vale enxergar com clareza.

Uma máquina rodando seu próprio software é portátil: a mesma configuração constrói a mesma coisa em
outro provedor numa tarde. Um banco gerenciado é portátil com esforço — os dados saem, e os arranjos ao
redor são reconstruídos. O sistema de build de uma plataforma, as funções de um provedor, e as filas e
serviços de identidade deles são os que viram a arquitetura, e mudar quer dizer reescrever.

Nada disso é razão para recusar a coisa conveniente. É razão para saber, de cada peça que você adota,
mais ou menos quanto custaria sair — e para gastar os compromissos mais profundos nas partes de que
você está mais convencido.
