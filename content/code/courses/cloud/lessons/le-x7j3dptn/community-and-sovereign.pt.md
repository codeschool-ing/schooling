---
title: Nuvens comunitárias e nuvens soberanas
version: 1
---

Uma **nuvem comunitária** fica entre as outras duas. Ela é provisionada para um grupo de organizações
com interesses comuns — uma missão, exigências de segurança, uma política, um regulador — e pode ser
operada por uma delas, por várias, ou por um terceiro, dentro ou fora das instalações delas. Os
inquilinos não são qualquer um que se cadastre, e também não são uma organização só: **pertencer ao
grupo é a fronteira**.

Os exemplos grandes mais claros são as regiões de governo dos grandes provedores. A AWS GovCloud (US)
e a Azure Government são regiões separadas para órgãos do governo americano e para as empresas que
trabalham para eles, separadas física e logicamente das regiões comerciais dos provedores, e operadas
sob regras sobre quem pode fazer parte da equipe. Elas rodam o software do provedor e não estão
abertas ao público: a organização precisa se qualificar antes de entrar. É o modelo comunitário em
escala continental. Existem menores onde quer que um setor junte infraestrutura, como universidades
dividindo uma nuvem de pesquisa.

## Soberana: um rótulo, não um modelo

*Nuvem soberana* não é uma das quatro da NIST, e não existe uma definição única dela. É um rótulo que
provedores e governos usam para ofertas que prometem **controle sobre jurisdição e sobre quem opera**,
e as promessas se dividem em perguntas separadas:

- onde os dados e as máquinas estão fisicamente;
- quem pode operá-las e alcançar os dados: uma equipe de qual nacionalidade, morando onde;
- os tribunais de qual país podem mandar o provedor entregar os dados;
- quem guarda as chaves de criptografia, assunto que o `cloud-security` trata a fundo.

A primeira pergunta é a que vem à cabeça, e uma região responde a ela: dado em `sa-east-1` está em
São Paulo. **A terceira pergunta é a que uma região não responde.** Um provedor constituído num país
está sujeito à lei desse país onde quer que fiquem seus datacenters. O CLOUD Act dos Estados Unidos,
de 2018, é o exemplo de sempre: ele permite que autoridades americanas exijam de um provedor americano
dados em sua posse ou controle, inclusive dados guardados fora dos Estados Unidos. Uma empresa que
precisa que a resposta seja "só os tribunais do nosso país" está perguntando sobre a pessoa jurídica
que opera o serviço, e nenhuma escolha de região muda isso.

Por isso as ofertas soberanas têm formatos diferentes: uma região operada por uma empresa local
separada, uma parceria em que uma firma local roda o software do provedor, equipe restrita a cidadãos
ou residentes, chaves guardadas fora do provedor. Cada uma resolve algumas das quatro perguntas e não
necessariamente as outras. **Leia o que uma oferta específica garante**, e não o que a palavra sugere,
e confira contra a regra que você de fato precisa cumprir. A seção sobre residência de dados faz isso
para a regra brasileira.
