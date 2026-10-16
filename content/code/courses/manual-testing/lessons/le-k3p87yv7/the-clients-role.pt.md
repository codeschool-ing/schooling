---
title: A tarde da cliente
version: 1
---

O erro comum sobre o papel do cliente no UAT vai para um de dois lados. Ou o cliente é tratado como
alguém a quem se mostra uma demonstração, mantido longe de tudo o que possa dar errado, ou como um
testador de reserva que vai rodar os casos do time mais devagar. **O cliente está na sala pelo que
só ele sabe**: como o trabalho é feito de verdade, numa noite cheia, pelas pessoas que o fazem. Uma
sessão é planejada para tirar isso dele.

Esta seção acompanha uma sessão. A gerente do teatro reservou uma tarde para aceitar o boxoffice
1.1, a build que a aula 10 testou. A Ana preparou tudo.

## O que o testador prepara

**O ambiente.** A versão 1.1, iniciada do zero poucos minutos antes de a gerente chegar, para que os
lugares estejam todos livres e os pedidos comecem em 1001. Um notebook que ela consiga usar sem os
atalhos da Ana, e o celular dela, porque metade dos clientes do teatro reserva por um.

**As contas e os dados.** A conta de membro, `member@example.org`, e a senha num cartão. Um cadastro
feito de antemão para uma conta ainda não confirmada, para que a gerente não gaste dez minutos da
tarde na caixa de saída.

**Os casos, nas palavras dela.** Os quatro critérios da seção 03 desta aula, impressos um por
página. E cinco tarefas escritas do jeito que ela falaria, como "vender dois ingressos para Hamlet
a um estudante" e "uma cliente no balcão quer cancelar o pedido que fez de manhã". Uma tarefa diz o
que alcançar e deixa os cliques com ela, porque o jeito como ela faz é parte do que está sendo
testado.

**Uma folha de anotações**, com colunas para a hora, a tarefa, o que ela fez, o que ela disse e o que
aconteceu. A penúltima coluna é a que mais importa.

## Como a sessão corre

A gerente conduz e a Ana senta ao lado. A Ana não pega o mouse, não explica como a tela funciona a
não ser que perguntem, e não defende o produto. Quando a gerente hesita, a Ana anota onde. Uma
hesitação é dado: uma cliente que não acha a caixa de estudante em dez segundos contou algo que
nenhum teste de sistema mediu.

Três coisas aconteceram naquela tarde, e elas são os três tipos de achado que um UAT produz.

**Um defeito que o time já conhecia.** Em "vender dois ingressos para Hamlet a um estudante", ela
marcou a caixa, apertou Book e leu o pedido: 10% de desconto, R$ 144,00. Ela disse: "Não. Estudante
paga meia; são quarenta reais cada." É a regressão que a aula 10 achou e relatou. Nada de novo para
a ferramenta de defeitos, e mesmo assim vale anotar, porque a gerente acabou de dar a ele um
**impacto no negócio**, com as palavras dela: "as escolas reservam na terça; se isso estiver no ar,
vou reembolsar sessenta pessoas na mão."

**Um requisito certo como está escrito e errado para o teatro.** Ao ler em voz alta o quarto
critério, aquele em que a reserva fecha às 19:01, ela parou. "Isso é online. No balcão a gente
vende até a cortina abrir." Os atendentes também vendem no balcão pelo boxoffice, então o R4 fecha
o balcão junto, uma hora antes de cada espetáculo. O programa faz exatamente o que o R4 diz, então
isto **não é um defeito**. É uma lacuna no requisito, achada porque quem sabe como o balcão funciona
leu a frase, e vai para o cliente e o desenvolvedor como um **pedido de mudança**.

**Uma pergunta que ninguém na sala sabe responder.** No celular dela, a tabela de espetáculos
passava da borda direita da tela, o defeito que a aula 7 achou e relatou. Ela perguntou se os sete
espetáculos da nova temporada piorariam isso. A Ana não chutou. Anotou a pergunta para o Rui, com o
nome da gerente ao lado.

## O que a Ana faz com as anotações

No fim, a Ana lê as anotações em voz alta e a gerente confirma cada uma; um achado que o cliente não
reconhece nas anotações é um achado que vai ser contestado depois. Então as anotações viram três
listas: defeitos, cada um num relatório escrito do jeito que a aula 15 ensina; pedidos de mudança,
cada um numa frase para o cliente e o desenvolvedor decidirem; e perguntas, cada uma com o nome de
alguém ao lado.

**O que a Ana não faz é decidir o que tudo isso significa para a versão.** O desconto de estudante é
um defeito que a gerente não vai aceitar, nas palavras dela, e o balcão fechando cedo é uma mudança
que ela quer. Dois achados, e pesar os dois cabe a ela. A próxima seção trata de como essa pesagem
termina.
