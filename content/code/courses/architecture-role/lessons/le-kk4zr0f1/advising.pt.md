---
title: Perguntas antes de respostas
version: 1
---

Quando alguém do desenvolvimento leva uma pergunta de design à arquiteta, a ajuda óbvia é uma
resposta. **Uma resposta resolve o problema de hoje e ensina o time a voltar com o próximo**, e uma
arquiteta que responde a todas as perguntas vira a fila onde todo design espera. A aula 17 tem um
nome para onde isso termina: a arquiteta como gargalo. Esta seção trata do hábito que evita esse
fim, que é perguntar antes de responder e ajudar um time a decidir em vez de decidir por ele.

## A pergunta que Kátia trouxe

Três semanas depois de assumir o papel, Renata foi parada no corredor por Kátia Lemos, tech lead do
Matching. O Matching oferece cada carga aos motoristas adequados e, para isso, precisa saber quais
motoristas estão livres e onde estão. Cada oferta fazia duas chamadas ao Tracking, e no pico da
manhã de segunda-feira as ofertas ficavam lentas. "Queremos pôr um cache Redis na frente do Tracking.
Tudo bem?"

Renata teve uma opinião em dez segundos. Era engenheira staff da Carreto havia seis anos, conhecia o
serviço de Tracking, e um cache era uma ideia razoável. "Pode ir em frente" teria levado uma frase e
rendido um obrigado. Em vez disso, ela fez quatro perguntas.

1. **Que número vocês querem mudar?** "Lento" virou uma medida: no pico de segunda, montar a lista de
   motoristas candidatos para uma carga levava 1,8 s no percentil 95, e Kátia queria abaixo de
   400 ms.
2. **O que acontece quando a posição em cache está errada?** Um motorista que aceitou outra carga
   dois minutos antes ainda pareceria livre. Kátia não tinha pensado nisso; o time dela pensou e
   concluiu que uma oferta a um motorista que já não está livre custa uma oferta recusada e uns
   trinta segundos, o que dava para aceitar.
3. **Quem mais lê essas posições?** O app do Shipper mostra os caminhões num mapa. Se o Matching
   guardasse posições em cache e o mapa não, um embarcador poderia ver um caminhão num lugar e
   receber uma oferta calculada a partir de outro.
4. **O que vocês tentariam primeiro se cache não fosse permitido?** O time olhou de novo e descobriu
   que uma das duas chamadas buscava o histórico inteiro do motorista quando o Matching só precisava
   da última posição.

A quarta pergunta foi a que mais trabalhou. Tirar a chamada desperdiçada derrubou o percentil 95
para 650 ms. O cache, que o time acrescentou mesmo assim, levou a 280 ms, com uma expiração de
sessenta segundos escolhida pelo time por causa da pergunta 2. **O time de Kátia tomou a decisão, e
ela foi melhor que a resposta de dez segundos de Renata**, porque agora eles sabiam coisas sobre o
próprio sistema que um sim nunca os teria feito procurar.

## Por que perguntar funciona melhor que mandar

São três motivos, e o terceiro é o que conta ao longo de um ano.

**O time sabe coisas que a arquiteta não sabe.** Renata conhecia o desenho do Tracking. O time de
Kátia sabia qual chamada era cara, com que frequência um motorista muda de status e quanto custa uma
oferta recusada. A resposta da arquiteta se apoia na informação da arquiteta, e numa empresa de 50
engenheiros essa informação é sempre parcial.

**As pessoas carregam uma decisão a que elas mesmas chegaram.** Um time mandado pôr um cache põe o
cache e, quando ele se comporta mal às três da manhã, lembra de quem foi a ideia. Um time que
escolheu entende a troca que fez e conserta.

**As perguntas se reaproveitam, e as respostas não.** "O que acontece quando isto estiver
desatualizado?" serve para o próximo cache, a próxima réplica de leitura e a próxima cópia dos dados
de qualquer pessoa. O time de Kátia hoje faz essa pergunta sem Renata por perto, e esse era o
objetivo. Uma resposta ajuda uma vez; uma pergunta que o time aprendeu a fazer ajuda todas as vezes
depois.

## Perguntas que ajudam, e uma que só finge

Nem toda pergunta faz isso. As úteis vêm em três tipos.

- **De esclarecimento**: qual é o objetivo, que número, para quem, até quando. Elas transformam um
  pedido num problema, como a aula 7 faz com o negócio.
- **De sondagem**: o que acontece quando isto falha, o que acontece com dez vezes a carga, quem mais
  depende disto. Elas acham os casos que o design ainda não encontrou.
- **De ampliação**: o que mais vocês consideraram, o que fariam se esta opção não fosse permitida,
  qual é a menor coisa que poderia funcionar. Elas impedem que o time compare a opção favorita com o
  nada.

**A que só finge é a pergunta que conduz**: "Você não acha que uma fila seria melhor aqui?" É uma
resposta com ponto de interrogação, e quem desenvolve reconhece na hora. É pior que uma resposta
honesta, porque soma um jogo de adivinhação à instrução. Se Renata tem uma opinião, ela a diz com
clareza e diz que tipo de opinião é.

## Diga qual chapéu você está usando

Esse último ponto pesa muito. A aula 3 descreveu o processo de aconselhamento: qualquer pessoa pode
tomar uma decisão de arquitetura, desde que antes busque conselho de quem será afetado e de quem tem
a experiência relevante, e quem decide não é obrigado a seguir o conselho. Isso só funciona quando
todo mundo sabe qual destas três coisas a arquiteta está fazendo.

| o que Renata está fazendo | como soa | quem decide |
|---|---|---|
| dando um conselho | "Meu conselho é medir antes de pôr cache. A decisão é de vocês." | o time |
| apontando um padrão | "Serviços leem os dados de outro time pela API dele, nunca pelas tabelas. Isso é um padrão." | já decidido, pelo padrão (aula 9) |
| tomando uma decisão | "Isto muda o contrato com o Tracking, então quem decide é a liderança do Tracking e eu, e escrevemos um ADR." | a arquiteta, com quem é afetado |

**Misturar essas três coisas custa confiança nos dois sentidos.** Um conselho que depois se revela
uma ordem ensina os times a parar de perguntar. Uma ordem entregue como sugestão é ignorada e depois
vira discussão. Renata fecha a maior parte das conversas dizendo em que linha dessa tabela elas
estavam.

## Quando simplesmente responder

Perguntar nem sempre é o certo, e tratar isso como regra produz uma arquiteta que responde a "que
horas são?" com "o que você acha?". Renata responde direto em quatro situações.

- **É um fato, não um julgamento**: qual versão do leiaute do CT-e a autoridade fiscal aceita, onde
  está documentado o contrato de Payments, o que um padrão diz.
- **Alguma coisa está pegando fogo.** Durante um incidente o time precisa de uma decisão em minutos,
  e o aprendizado acontece na revisão depois.
- **A decisão é uma porta de mão única** (aula 5) e o time nunca enfrentou uma desse tipo. Aprender
  errando custa caro demais, então ela dá a resposta e explica o raciocínio enquanto dá.
- **O time já fez o raciocínio** e quer uma segunda opinião. Aí a opinião dela, com os motivos, é
  exatamente a ajuda que pediram.

Mesmo nesses casos, um curto "o motivo é este" transforma a resposta em algo que o time pode
reaproveitar. O que separa isso de uma palestra é o tamanho: uma ou duas frases de raciocínio, não
um seminário.

## O formato da conversa

As conversas de Renata com os times se acomodaram num padrão que leva cerca de meia hora:

1. **Reformular o problema** com as próprias palavras até o time concordar que ela entendeu.
2. **Perguntar pelo objetivo e pelo número** antes de olhar qualquer solução.
3. **Perguntar o que acontece quando as coisas falham**, e o que mais o time considerou.
4. **Dar a opinião dela**, marcada como conselho, com o motivo.
5. **Dizer quem decide**, e o que ela gostaria de ver escrito, se for o caso.

É mais lento que responder no corredor. No primeiro trimestre dela, foi também o motivo de o número
de perguntas de design que chegavam a Renata cair enquanto o número de decisões de design na Carreto
não caía. A aula 10 descreveu o fórum de arquitetura, onde essas decisões ficam visíveis para todos;
isto é a versão de uma pessoa para outra da mesma ideia.
