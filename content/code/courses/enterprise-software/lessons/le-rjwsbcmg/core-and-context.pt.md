---
title: Núcleo, contexto e a resposta padrão
version: 1
---

A regra que a maioria dos engenheiros traz para esta decisão é curta: construa o que importa, compre
o que não importa. Soa como prudência e ordena do jeito errado. A folha de pagamento importa demais —
erre nela e 3.200 pessoas recebem atrasado, e algumas deixam de vir trabalhar — e quase nenhuma empresa
no mundo escreve a sua. **Importância não é o eixo que decide entre comprar e construir.** O eixo é se
o trabalho diferencia a empresa dos concorrentes, e a importância é uma segunda pergunta, separada,
sobre o cuidado com que o trabalho tem de ser feito, seja qual for a origem.

Esta seção dá os dois eixos, um terceiro jeito de fatiar o parque de sistemas que uma empresa grande
vai reconhecer, e a resposta padrão que sai deles. Mostra também Joana errando o primeiro passo, do
jeito que erra quem passou oito anos construindo.

## Núcleo e contexto

Geoffrey Moore dá à distinção a forma mais completa em *Dealing with Darwin* (2005). **Núcleo** (*core*) é todo trabalho
que cria uma diferença pela qual o cliente paga ou escolhe você: feito melhor que os concorrentes, ele
ganha negócio. **Contexto** (*context*) é todo o resto que a empresa precisa fazer — trabalho que tem
de ser feito, e bem feito, mas que não rende nada a mais por ser feito acima do padrão do setor. O
argumento de Moore era sobre onde pôr talento e atenção, que são escassos: no núcleo, enquanto o
contexto é padronizado, simplificado e entregue a quem o faz melhor e mais barato.

Ele acrescentou o segundo eixo porque o primeiro, sozinho, convida ao erro acima. O trabalho também é
**crítico para a missão** ou não, conforme errar nele cause dano sério e imediato. Folha de pagamento
é contexto e crítica. Emitir uma NF-e para cada venda também: um laticínio que não fatura não
despacha. Nenhuma das duas rende à Serra Alta um litro de leite a mais ou uma gôndola de supermercado
a mais por ser excelente; as duas fechariam a empresa se falhassem.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 360\" role=\"img\" data-fig=\"l15-core-context\" aria-label=\"Uma grade dois por dois do trabalho da Serra Alta. O eixo horizontal vai de contexto, à esquerda, o trabalho que toda empresa faz, a núcleo, à direita, o trabalho que diferencia a Serra Alta. O eixo vertical vai de apoio, embaixo, a crítico para a missão, em cima. Em cima à esquerda, contexto e crítico: folha de pagamento, contabilidade no SAP, emissão de NF-e e o cálculo do pagamento aos produtores. Em cima à direita, núcleo e crítico: a política de pagamento por qualidade do leite e os técnicos de campo que ajudam as fazendas a cumpri-la. Embaixo à esquerda, contexto e apoio: e-mail e Teams, reembolso de despesas. Embaixo à direita, núcleo e apoio: experimentos no Portal B2B. Uma caixa tracejada em cima à direita, o pagamento aos produtores onde Joana o pôs primeiro, tem uma seta que o divide em dois: a política fica no núcleo, e o cálculo passa para o contexto.\"><defs><marker id=\"l15-core-context-es-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"90.0\" y=\"20.0\" width=\"610.0\" height=\"290.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><path d=\"M395.0 20.0 L395.0 310.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M90.0 165.0 L700.0 165.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"242.5\" y=\"334.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">contexto: toda empresa faz</text><text x=\"547.5\" y=\"334.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">núcleo: diferencia a Serra Alta</text><text x=\"46.0\" y=\"85.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">crítico</text><text x=\"46.0\" y=\"98.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">para a missão</text><text x=\"44.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">apoio</text><rect x=\"103.0\" y=\"32.0\" width=\"150.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"178.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">folha de pagamento</text><rect x=\"103.0\" y=\"64.0\" width=\"150.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"178.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">contabilidade no SAP</text><rect x=\"103.0\" y=\"96.0\" width=\"150.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"178.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">emissão de NF-e</text><rect x=\"254.0\" y=\"115.0\" width=\"132.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"125.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">cálculo do</text><text x=\"320.0\" y=\"138.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pagamento</text><rect x=\"420.0\" y=\"108.0\" width=\"156.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"498.0\" y=\"121.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">política de pagamento</text><text x=\"498.0\" y=\"134.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">por qualidade</text><rect x=\"560.0\" y=\"44.0\" width=\"128.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"624.0\" y=\"57.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">técnicos de campo</text><text x=\"624.0\" y=\"70.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">nas fazendas</text><rect x=\"404.0\" y=\"42.0\" width=\"132.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"470.0\" y=\"51.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">pagamento, onde</text><text x=\"470.0\" y=\"64.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Joana o pôs</text><path d=\"M498.0 75.0 L498.0 106.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l15-core-context-es-ah-phosphor)\"></path><path d=\"M430.0 82.0 L346.0 113.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l15-core-context-es-ah-phosphor)\"></path><rect x=\"103.0\" y=\"202.0\" width=\"150.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"178.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">e-mail e Teams</text><rect x=\"103.0\" y=\"238.0\" width=\"150.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"178.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">reembolso de despesas</text><rect x=\"460.0\" y=\"212.0\" width=\"176.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"548.0\" y=\"225.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">experimentos</text><text x=\"548.0\" y=\"238.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">no Portal B2B</text></svg>", "caption": "Duas perguntas, não uma. Se o trabalho diferencia a empresa decide entre comprar e construir; se ele é crítico decide o cuidado com que qualquer dos dois é feito."}
```

**Contexto crítico para a missão é o lugar natural de um produto comprado.** É justamente o trabalho
em que você quer o que milhares de outras empresas já usam, testado pelos erros delas e mantido em dia
com a lei por alguém cujo negócio inteiro é mantê-lo em dia. Um laticínio que escreve a própria folha
de pagamento está se oferecendo para acompanhar cada mudança nas regras trabalhistas e tributárias
brasileiras com um time cujo trabalho de verdade é outro.

Dois testes ajudam quando uma função é difícil de classificar:

| teste | é núcleo se… |
|---|---|
| o olhar do cliente | as pessoas que você disputa notariam, e se importariam, se você fizesse exatamente como o concorrente |
| o teste da cópia | um concorrente que comprasse o mesmo software ainda não teria a sua vantagem |

O segundo teste é o que mais economiza dinheiro. Se um concorrente pudesse obter a sua vantagem
instalando o mesmo produto, a vantagem era do produto e não sua, e você também pode comprá-la. Se ele
pudesse instalar o produto e ainda assim não tê-la, a vantagem mora em outro lugar — nos seus dados,
nas suas pessoas, nas suas regras — e pode sobreviver a rodar no software de outra pessoa.

## Camadas de ritmo

A Gartner publicou em 2012 um modelo parecido, a estratégia de aplicações em camadas de ritmo
(*pace-layered application strategy*). Ele ordena as aplicações pela velocidade com que precisam
mudar, porque esse ritmo decide como devem ser governadas, financiadas e obtidas:

| camada | muda | na Serra Alta | tende a ser obtida como |
|---|---|---|---|
| sistemas de registro | devagar; anos entre mudanças de verdade | finanças, compras e estoque do SAP ECC; folha de pagamento; NF-e | um pacote padrão, configurado, mantido perto da versão do fornecedor |
| sistemas de diferenciação | a cada poucos meses, conforme a empresa compete | como as fazendas são pagas pela qualidade; as rotas do Rota para os caminhões de leite | um pacote estendido ao lado, ou uma construção, quando nenhum pacote serve |
| sistemas de inovação | semanas; a maioria dos experimentos fracassa | ideias novas testadas no Portal B2B | construídos depressa e jogados fora sem dó |

**As camadas não são um ranking.** Os sistemas de registro são onde o dinheiro é contado e a lei é
cumprida; mudam devagar porque precisam estar certos, não porque importem menos. O que o modelo
acrescenta é que uma governança só para as três camadas está errada para duas delas. Uma aprovação de
mudança de seis semanas serve ao razão contábil e mata um experimento. O hábito de publicar toda
semana serve ao portal, e deixaria muito nervosos os auditores do fechamento do mês da aula 1.

## O primeiro rascunho de Joana

A primeira nota de Joana sobre o substituto do pagamento aos produtores o pôs no canto superior
direito da figura, e a conclusão veio na frase seguinte: núcleo, então construir. O raciocínio dela
não foi descuidado. **O jeito como a Serra Alta paga pela qualidade do leite é como ela segura as
melhores fazendas.** Uma fazenda com baixa contagem de células somáticas e proteína alta é cortejada
por todos os laticínios da Zona da Mata, e as tabelas de bonificação que a recompensam são uma arma
comercial. O RPG de Sebastião guarda essas regras, 46 delas, e cada uma foi discutida por alguém.

Cláudia Mendes, cujo time de qualidade escreve as tabelas, fez a pergunta que partiu a caixa. Duas
vezes por ano o comitê dela revisa a bonificação por gordura, proteína, células somáticas e contagem
bacteriana. O que as fazendas notam são as tabelas, a rapidez com que o dinheiro cai no dia 10 e os
técnicos de campo que as visitam para ajudar a chegar à próxima faixa. Nenhuma fazenda jamais notou
como a multiplicação é feita.

Passada pelo teste da cópia, a função se divide em duas:

- **a política** — as faixas, as bonificações, as penalidades, o programa dos técnicos — é núcleo. Um
  concorrente que comprasse qualquer software ainda não teria as tabelas da Serra Alta, nem os trinta
  anos de histórico de laboratório de cada fazenda que a Coleta guarda, nem os técnicos dela;
- **o cálculo** — pegar os litros, pegar os resultados de laboratório, aplicar as tabelas, produzir o
  valor de cada fazenda, entregá-lo ao SAP para pagar — é contexto. Todo laticínio do Brasil faz isso,
  e vários produtos já fazem por eles.

**O que diferencia é a política, e uma política é dado.** A pergunta para um produto, então, não é "o
pagamento aos produtores é núcleo?", e sim "este produto consegue expressar a nossa política, e deixar
o comitê de Cláudia mudá-la duas vezes por ano sem um projeto?". Essa pergunta tem uma resposta
mensurável, e Joana a mediu. Um *fit-gap* contra o produto SaaS que ela pré-selecionou concluiu que 41
das 46 regras podiam ser configuradas nas próprias tabelas de regras do produto. As outras cinco
precisam de uma extensão escrita ao lado do produto, pela interface publicada dele. Uma delas é uma
bonificação paga retroativamente, por seis meses, à fazenda que mantém a contagem de células
somáticas abaixo de um limite por esse tempo todo. Estender ao lado é o anel do meio dos três da aula
1: configurar, estender ao lado, nunca modificar.

O primeiro rascunho de Joana é um erro comum por um bom motivo. **Quem constrói bem vê um problema
interessante e um diferencial no mesmo lugar, e eles não são a mesma coisa.** O cálculo é interessante
de construir. A política é o que ganha fazendas.

## O padrão, e o ônus da prova

Junte os dois eixos e o padrão aparece: **para contexto, compre; construir precisa de um motivo, e o
motivo vai por escrito.** O padrão não afirma que comprar é mais barato; a seção 06 desta aula
encontra um horizonte em que a construção ganharia. Ele afirma que contexto comprado é contexto que
outra pessoa mantém em dia, e as pessoas que a Serra Alta paga para construir podem gastar o tempo
delas no que é núcleo.

Motivos que justificam construir contexto, e cada um pode ser verificado:

- nenhum produto consegue expressar uma regra de que a empresa não abre mão, e a lacuna é grande demais
  para estender ao lado;
- o dado é a vantagem, e um produto o guardaria onde a Serra Alta não consegue usá-lo;
- o volume torna absurdo qualquer preço por unidade na escala da empresa;
- os produtos do mercado não atendem a uma exigência legal que vale para a Serra Alta.

Motivos que soam como motivos e não são:

- "a gente faria melhor" — quase certamente verdade na parte que se vê, e uma afirmação sobre quem
  constrói, não sobre o negócio;
- "não queremos depender de fornecedor" — toda opção depende de alguém, e a seção 05 desta aula põe um
  preço na dependência em vez de um slogan;
- "o nosso processo é único" — às vezes. O "fit to standard" da aula 1 pergunta se o processo é único
  porque ganha negócio, ou único porque ninguém nunca o arrumou.

## Uma terceira resposta

O parque da Serra Alta oferece algo que a pergunta de duas vias deixa de fora. A empresa vai sair do
SAP ECC para o S/4HANA de qualquer jeito, então o pagamento aos produtores poderia ser construído
**dentro do sistema de registro que ela já tem**, como uma extensão do SAP. Essa é a opção B no resto
desta aula, ao lado de A (comprar o produto SaaS) e C (construir internamente). Edson Prado prefere
essa, e o argumento dele é sério: as fazendas já são cadastros de fornecedor no SAP, o SAP já as paga
pelos arquivos do banco, e um sistema a menos é uma integração a menos.

Núcleo e contexto não escolhem entre A, B e C. Eles fixam o ponto de partida — o cálculo é contexto,
então a construção precisa merecer o lugar — e dizem o que qualquer opção tem de proteger: a
capacidade de Cláudia de mudar a política duas vezes por ano. Tudo depois desta seção é sobre
dinheiro, tempo e risco, e o primeiro trabalho é contar o dinheiro direito.
