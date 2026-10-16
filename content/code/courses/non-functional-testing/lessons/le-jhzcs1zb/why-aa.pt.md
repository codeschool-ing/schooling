---
title: Por que o AA é o alvo de costume
version: 1
---

Quase todo requisito de acessibilidade que chegar a você vai dizer "WCAG 2.x AA". **O AA é o nível
para o qual apontam as leis, as compras públicas e as normas construídas sobre elas**, e essa é a
razão inteira de ele ser o padrão: uma equipe raramente o escolhe, ela o herda de um contrato ou de
uma regulação. Um testador não precisa ser advogado, e nada aqui é aconselhamento jurídico. O que
um testador precisa é saber de que documento veio o requisito, porque é esse documento que decide a
versão, o nível e quais páginas estão no escopo.

Três jurisdições cobrem quase tudo que você vai encontrar, e cada uma chega à WCAG por um caminho
diferente.

## A União Europeia

**O European Accessibility Act**, a Diretiva (UE) 2019/882, vale desde 28 de junho de 2025 para uma
lista definida de produtos e serviços vendidos na UE: entre eles comércio eletrônico, serviços
bancários ao consumidor, livros eletrônicos, e sites e aplicativos que vendem passagens de
transporte de passageiros. Microempresas que prestam serviços estão isentas. O Act em si não cita
a WCAG. Ele declara requisitos, presume-se que um produto os atende quando atende às normas
europeias harmonizadas, e a referência usada para a web é a **EN 301 549**, cujas cláusulas para a
web incorporam a WCAG 2.1 no nível AA. Uma diretiva mais antiga, a (UE) 2016/2102, já aplicava a
mesma norma aos sites de órgãos públicos.

A página de reserva de uma empresa de trens está nomeada na lista. Se a bilheteria de um teatro
pequeno está coberta é o tipo de pergunta a entregar para alguém qualificado, antes de o plano de
teste ser escrito, e não depois.

## Os Estados Unidos

**A Section 508 do Rehabilitation Act** se aplica à tecnologia de informação e comunicação das
agências federais: o que elas constroem, compram e usam. Sua revisão de 2017 incorpora a WCAG 2.0
nos níveis A e AA por referência, para páginas web e também, por extensão, para documentos e
software. Uma empresa que vende software para uma agência federal a cumpre pelo contrato, e é por
isso que fornecedores publicam relatórios de conformidade. Outras leis americanas, como o Americans
with Disabilities Act, também alcançam sites, e até onde é assunto de tribunais e de regulações que
este curso não tenta resumir.

## O Brasil

**A Lei Brasileira de Inclusão**, Lei 13.146/2015, também chamada de Estatuto da Pessoa com
Deficiência, torna obrigatória no seu artigo 63 a acessibilidade nos sites mantidos por empresas
com sede ou representação comercial no país e por órgãos de governo, "conforme as melhores práticas
e diretrizes de acessibilidade adotadas internacionalmente". Ela não cita versão nem nível, e a
WCAG é a diretriz para a qual essa expressão é lida como apontando.

**O eMAG**, o Modelo de Acessibilidade em Governo Eletrônico, é o modelo do próprio governo federal
para os seus sites. A versão 3.1 é construída sobre a WCAG 2.0 e adaptada aos serviços públicos
brasileiros, com recomendações próprias, como um conjunto fixo de teclas de atalho de
acessibilidade. Ele obriga os sites do governo; uma loja privada cumpre a LBI, não o eMAG.

## O que isso significa num plano de teste

Os três caminhos chegam a versões diferentes: 2.0 na Section 508, 2.1 pela EN 301 549, e uma
"diretriz internacional" sem nome no Brasil. **Testar contra a WCAG 2.2 AA cobre todas elas**,
porque cada versão contém a anterior no mesmo nível. É por isso que a aula 1 escreveu 2.2 AA no
requisito, e por isso a plataforma em que este curso é servido segura cada uma das próprias telas
na mesma linha.

Escreva o escopo junto com o nível:

> O fluxo de reserva (`book.html` e a confirmação que ele mostra) está conforme à WCAG 2.2 no nível
> AA, conferido com uma auditoria automática e à mão, com teclado e leitor de tela, antes da
> entrega.

A última oração é a metade que as pessoas esquecem. Um requisito que só cita o nível convida a
equipe a rodar uma ferramenta e chamar o resultado de conformidade, e a aula 13 mostra o quanto uma
ferramenta deixa de ver.
