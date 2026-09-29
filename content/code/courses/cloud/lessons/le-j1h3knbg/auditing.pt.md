---
title: Quem fez o quê, e quem ainda pode fazer
version: 1
---

Políticas decidem o que pode acontecer. Elas não dizem nada sobre o que aconteceu, e duas perguntas
aparecem cedo ou tarde em toda conta: quem apagou isto, e quem ainda poderia fazer de novo? A primeira
se responde com um log, a segunda com uma revisão, e as duas precisam existir antes do dia em que
alguém pergunta.

## O log de toda chamada

Cada provedor registra as chamadas feitas à sua API. Na AWS é o **CloudTrail**; no Google Cloud, o
Cloud Audit Logs; no Azure, o Activity Log, com o Entra ID mantendo um registro próprio dos logins.
As entradas têm o formato com que esta aula começou, porque registram o pedido:

- quem: o principal e, para uma role, a sessão que a assumiu, de modo que uma chamada feita por uma
  role compartilhada ainda pode ser rastreada até a pessoa ou máquina que a assumiu;
- o quê: a ação, como `DeleteObject` ou `TerminateInstances`;
- sobre o quê: o recurso;
- quando, e de qual endereço;
- o resultado, **inclusive as recusas**. Uma sequência de `AccessDenied` vinda de uma identidade é o
  jeito como uma chave roubada tentando a sorte aparece vista de dentro.

O que fica registrado sem ninguém pedir é mais estreito do que se imagina. Os três guardam as
chamadas que *mudam* coisas, como criar, apagar ou conceder, e guardam por um tempo limitado: a AWS e o
Azure guardam noventa dias disso por conta própria. Leituras dos dados em si, como cada `GetObject`
num bucket, são outro tipo de evento que a AWS não registra a menos que alguém configure, e os logs de
acesso a dados do Google Cloud vêm desligados por padrão na maioria dos serviços. Qualquer coisa além
da retenção padrão, ou qualquer registro de quem leu o quê, é uma decisão que alguém toma e paga.

**O log precisa morar num lugar que as pessoas auditadas não conseguem apagar.** Um administrador que
pode remover o log pode remover o registro do que fez. O arranjo comum é mandar o log para um
armazenamento numa conta separada, que só um grupo pequeno de segurança alcança, com uma configuração
de retenção que proíbe apagar entradas antes de uma data, o que o S3 oferece como Object Lock. Aí a
identidade mais poderosa da conta auditada ainda consegue impedir que novas entradas sejam gravadas,
e impedir é, por si só, uma das entradas já guardadas.

## A revisão

O log responde perguntas sobre o passado. A revisão é como o presente se mantém honesto. Com data na
agenda — a cada trimestre é um ritmo comum —, alguém percorre as identidades e pergunta, para cada
uma:

1. Esta pessoa ou programa ainda precisa existir? Quem saiu e serviços aposentados primeiro.
2. Que grupos e roles ela tem, e o trabalho ainda precisa de cada um?
3. Quando ela usou cada permissão pela última vez? Uma concessão sem uso desde a última revisão é
   candidata a remoção, e os dados de último uso do provedor são a evidência.
4. Há chaves de longa duração, e cada uma tem um motivo e uma rotação recente?

**Uma revisão é uma pessoa decidindo, com o dono do time junto**, porque só ele sabe se a permissão
do incidente de dezoito meses atrás ainda é necessária. Remover um acesso que alguém usa provoca um
pedido recusado e uma mensagem na mesma tarde; manter um acesso que ninguém usa não provoca nada até
o dia em que é abusado. Por causa dessa assimetria, quando ninguém sabe dizer por que uma permissão
existe, a resposta padrão é removê-la.

::: track devsecops security
Na sua trilha esta aula é o piso. O `cloud-security` vem em seguida e parte dela: federação montada
na prática, chaves e a rotação delas, e os caminhos de escalada que ninguém revogou. Um deles é o
`iam:PassRole`, que deixa uma identidade entregar uma role a uma máquina que ela lança e então agir
com tudo o que aquela role pode fazer. Guarde as três regras de avaliação e a cadeia de credenciais;
aquele curso assume as duas.
:::

::: track *
Para este curso, isto basta para desenhar quem pode fazer o quê numa conta: pessoas federadas com
segundo fator, máquinas com roles, políticas escritas do nada para cima e um log que alguém revisa. O
`cloud-security` vai mais fundo se o seu trabalho pedir, dos caminhos de escalada que ninguém revogou
a como as chaves são trocadas.
:::
