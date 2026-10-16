---
title: Escrevendo um: o registro da reserva de assento
version: 1
---

A decisão mais cara da estratégia da Coreto é a terceira ação da aula 1: o novo time de Reservas
passa dois trimestres tirando as travas de linha do caminho de reserva de assento. Em abril, com o
teste de carga da abertura de vendas rodando e um design acordado, Mateus Araújo e o time de
Reservas registraram a decisão. Este é o registro como entrou no `coreto-core`, e o resto da seção o
desmonta.

> **ADR-0006: Reservar assentos sem travas de linha**
>
> **Status:** Aceito, abril. Substitui o ADR-0002.
>
> **Contexto**
>
> Uma reserva de assento segura um assento para um comprador enquanto ele paga. O módulo de reservas
> faz a reserva travando a linha do assento dentro de uma transação no banco e mantém a trava até o
> pagamento dar certo ou o comprador sair (ADR-0002). Numa hora comum, ninguém percebe. Numa grande
> abertura de vendas, muitos compradores querem os mesmos assentos no mesmo minuto: as travas fazem
> fila, as requisições de checkout estouram o tempo, e os compradores veem assentos sumirem e
> voltarem. A Coreto faz cerca de doze grandes aberturas de vendas por ano, e o registro de
> incidentes atribui as falhas delas a este caminho.
>
> O caminho de reserva também custa tempo a cada sprint. Mudanças que mexem nele levam cerca de 31
> horas de engenharia a mais por sprint do que levariam em código limpo, pelos registros de horas
> mantidos desde fevereiro.
>
> Consideramos três abordagens. Manter as travas e encurtar a transação é a mais barata, e o teste de
> carga da abertura (ADR-0004) ainda mostra a fila se formando com o tráfego de abertura. Levar o
> módulo de reservas para um serviço próprio é a migração para microsserviços que a estratégia adiou
> por um ano, e não tiraria a trava por si só. Fazer reservas sem travas muda o modelo de dados e
> todo relatório que conta assentos reservados.
>
> **Decisão**
>
> Vamos registrar cada reserva como uma linha própria com horário de expiração, e obtê-la com um
> único insert que o banco recusa quando já existe uma reserva viva para aquele assento. Nada espera
> por uma trava. As leituras ignoram reservas expiradas, e um job de limpeza as remove.
>
> Vamos passar as casas para o caminho novo uma de cada vez, atrás de uma flag, e nenhuma mudança no
> caminho de reserva entra sem uma execução do teste de carga anexada ao pull request.
>
> **Consequências**
>
> - Um comprador que perde um assento para outra pessoa fica sabendo na hora, em vez de esperar um
>   timeout.
> - A duração de uma reserva vira uma configuração explícita. Escolhê-la é uma decisão de produto; o
>   time de Júlia Sato é dono dela, e este registro não a define.
> - O job de limpeza agora faz parte do caminho da abertura e precisa de alerta próprio.
> - Os relatórios de assentos reservados do time de Dados leem outra tabela e precisam mudar.
> - Os dois primeiros trimestres do time de Reservas vão para isto; nada mais da lista dele começa
>   antes.
> - Enquanto a flag existir, a mudança pode ser revertida. Depois que o caminho antigo for apagado,
>   voltar atrás exige um registro novo.

Cabe numa página, e cada linha dele poderia ser conferida por alguém que não estava na sala.

## O título nomeia a decisão

"Reservar assentos sem travas de linha" é uma decisão. **"Desempenho da reserva de assento" seria um
tema**, e um log de temas diz a quem lê onde procurar e nada sobre o que foi escolhido. Nygard pedia
uma frase nominal curta, e a versão útil disso é a própria decisão, curta o bastante para ser lida
de relance numa lista longa. O número na frente é a identidade do registro; o título pode ser
melhorado depois, e o número nunca muda.

## O contexto é justo com as opções que perderam

O defeito mais comum num primeiro ADR é um contexto escrito depois da decisão, defendendo-a. O teste
é se um engenheiro que preferia outra opção leria o contexto e o acharia justo. O ADR-0006 passa
porque dá a cada abordagem rejeitada a vantagem real dela: a correção na transação é a mais barata, e
o registro diz isso antes de dizer por que ela não bastava.

**O contexto também é onde vão os fatos do momento.** "A estratégia adiou os microsserviços por um
ano" não vai ser verdade para sempre. Quando deixar de ser, quem lê vê que um dos motivos por trás
desta decisão sumiu e pode perguntar se a decisão ainda se sustenta. Sem essa frase, a escolha parece
um julgamento contra microsserviços, o que ela nunca foi.

## A decisão diz "vamos"

Frases completas, na voz ativa. "Vamos registrar cada reserva como uma linha própria" pode ser
conferido na revisão: um pull request faz isso ou não faz. "As reservas idealmente deveriam evitar
travas" não pode, e deixa espaço para o próximo engenheiro ler como opcional.

Uma decisão pode trazer como é implantada quando a implantação faz parte do que foi decidido. Aqui
faz: casa por casa atrás de uma flag, com uma execução do teste de carga em toda mudança. Deixe de
fora o cronograma, os nomes dos engenheiros e os números de tíquete. Isso pertence ao plano, e o
plano muda toda semana.

## As consequências incluem as ruins

Uma lista de consequências só com benefícios soa como discurso de vendas, e os revisores param de
confiar nela. O ADR-0006 lista um job novo que pode falhar, um conjunto de relatórios que quebra e
dois trimestres de um time. **Essas linhas são o motivo de o registro merecer crédito.**

A linha mais valiosa é a segunda. Ela diz que a duração da reserva agora é uma decisão de produto e
nomeia quem é dono dela. A aula 16 mostrou como uma mudança técnica pode entregar ao produto uma
escolha que ele nem sabia que tinha; este registro a entrega por escrito, no dia em que a escolha
aparece.

## Escrevendo o seu

Abra o editor de texto simples que você preparou na aula 1. Crie uma pasta chamada `adr` ao lado da
estratégia de uma página que você escreveu na aula 3, e nela um arquivo chamado
`0001-record-architecture-decisions.md`. Esse primeiro registro declara a própria prática: que este
time registra suas decisões arquiteturalmente significativas, neste formato, neste lugar.

Depois escreva um segundo, para uma decisão real que seu time tomou no último ano e sobre a qual
alguém já perguntou "por quê". Use as cinco partes, na ordem. Duas verificações antes de dar por
pronto:

1. Entregue a um colega que não participou da decisão. Ele deve conseguir dizer que opções foram
   rejeitadas e o motivo de cada uma, sem perguntar a você.
2. Leia as consequências em voz alta. Se nenhuma delas é um custo, ficou algo de fora.

Conte com o contexto levando mais tempo que a decisão. É a parte que ninguém consegue escrever
depois.
