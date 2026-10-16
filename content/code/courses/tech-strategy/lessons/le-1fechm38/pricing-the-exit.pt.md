---
title: Precificar a saída antes de entrar
version: 1
---

A saída é a linha mais deixada em branco, e o motivo dado é sempre o mesmo: não estamos planejando
sair. **Esse motivo confunde um plano com um preço.** Ninguém planeja sair de um fornecedor no dia
em que assina. As empresas saem mesmo assim — o fornecedor sobe o preço, é comprado, fica para trás,
ou as necessidades da própria empresa mudam —, e o custo de sair foi definido muito antes, por
decisões tomadas durante a integração.

## Do que é feita a saída da Coreto

Sair do serviço de observabilidade hospedado custaria à Coreto **R$ 49.650**, em duas partes:

| parte | como foi estimada | custo |
|---|---|---|
| levar painéis, alertas e agentes para o que vier depois | 280 horas a R$ 150 | R$ 42.000 |
| rodar os dois enquanto a mudança acontece | um mês de licença | R$ 7.650 |
| | | R$ 49.650 |

As 280 horas são um pouco menos que as 320 da integração original, porque a segunda mudança parte
de um time que já fez uma, e de um inventário de painéis que a primeira produziu. A Coreto conta a
saída inteira no TCO de três anos, como se fosse sair no fim do ano 3. É a leitura cautelosa. A
aula 10 pergunta quão provável é sair de fato e pondera o custo por isso; aqui o ponto é mais
estreito, e vem antes: **não dá para ponderar um custo que você nunca precificou.**

## Por que na entrada, e não na saída

Três motivos, e cada um se perde no dia em que o contrato é assinado.

**O poder de negociação está no começo.** Antes de assinar, a Coreto é um cliente que o fornecedor
quer. Ela pode pedir exportação de dados num formato aberto, um aviso prévio com que consiga viver
e o direito de guardar os dados por um tempo depois do fim do contrato. Um fornecedor concede
cláusulas assim para ganhar o negócio, e recusa acrescentá-las depois que o ganhou. O preço da saída
está em parte escrito no contrato, e o contrato é escrito uma vez.

**A integração decide a saída.** Cada painel feito na linguagem de consulta proprietária do
fornecedor, e cada serviço instrumentado com a biblioteca do próprio fornecedor, aumenta o que sair
vai custar. Instrumentar os serviços com uma biblioteca neutra e guardar painéis e regras de alerta
como arquivos num repositório, e não só na interface do fornecedor, custa um pouco mais na
integração e diminui as 280 horas. Essa troca só pode ser feita durante a integração.

**Um preço escrito pode ser acompanhado.** Uma saída estimada em R$ 49.650 no ano 1 pode ser
reestimada a cada ano. Se ela cresceu porque os times fizeram dezenas de painéis a mais na linguagem
do fornecedor, alguém consegue ver isso e decidir se importa. Uma saída que ninguém precificou
cresce sem ser vista, e é descoberta no dia em que a empresa mais precisa que ela seja pequena.

## A lista

Uma estimativa de saída não precisa ser precisa. Precisa ter cada parte nomeada, porque a parte que
ninguém nomeia é a que fica faltando:

| parte da saída | a pergunta a fazer antes de assinar |
|---|---|
| os dados | Conseguimos exportar tudo, num formato que outra ferramenta leia, e quanto tempo leva? |
| a integração | Quanto do nosso código e da nossa configuração fala a língua do fornecedor? |
| rodar em paralelo | Por quanto tempo vamos pagar os dois, e quanto custa um mês dos dois? |
| o contrato | Que aviso prévio devemos, e o que acontece com nossos dados quando o contrato acaba? |
| as pessoas | Quem precisa aprender o substituto, e quantas horas isso dá? |

## A saída como linha de toda proposta

A saída custa R$ 49.650 dos R$ 452.250 da opção hospedada, e incluí-la não muda a resposta da
Coreto: hospedar sai mais barato com a saída contada inteira. Esse é o caso comum, e é o motivo de
incluí-la mesmo assim. **Uma linha de saída que não muda a decisão custa uma linha para escrever.**
Uma linha de saída deixada de fora é uma afirmação, feita em silêncio, de que a empresa nunca vai
sair — e a decisão em que essa afirmação se mostra falsa é justamente aquela em que a linha ausente
custa mais.

O Davi acrescentou uma frase à recomendação de observabilidade:

> **Saída:** R$ 49.650, incluída acima. Antes de assinar, pedimos exportação de todos os dados num
> formato aberto e um prazo para recuperá-los depois do fim do contrato; os serviços são
> instrumentados com uma biblioteca neutra e os painéis ficam como arquivos no nosso repositório.

A frase é curta porque o trabalho foi feito antes dela. A aula 10 dá o passo seguinte: põe uma
probabilidade ao lado de custos como este, para que um aprisionamento possa ser pesado contra o
quanto custaria evitá-lo.
