---
title: Missões
version: 1
---

Uma **missão**, o *charter* em inglês, é o objetivo de uma sessão, escrito antes de ela começar: o
que explorar, com o quê, e o que você está tentando descobrir. Ela é curta, uma ou duas frases, e faz
dois trabalhos. Mantém a sessão apontada para algum lugar, para que noventa minutos não escorram
para o que quer que estivesse na tela. E diz a todo mundo o que a sessão cobriu, para que uma folha
dizendo "quatro sessões sobre pedidos" signifique alguma coisa.

## Um modelo

O livro *Explore It!*, de Elisabeth Hendrickson, dá às missões uma forma em três partes que a maioria
das equipes usa hoje:

> **Explore** *um alvo* **com** *recursos* **para descobrir** *uma informação*.

O **alvo** é a parte do produto: uma funcionalidade, uma página, um requisito, um tipo de dado. Os
**recursos** são o que você leva: uma ferramenta, um conjunto de dados, uma técnica, uma heurística,
outra conta. A **informação** é a pergunta que a sessão deve responder, e é a parte mais esquecida e
a que mais vale escrever, porque é ela que diz quando a sessão cumpriu o seu papel.

Esta é a missão da Ana para a sessão da seção 05 desta aula:

> Explore **a vida de um pedido**, com **toda ação a partir de todo estado, no navegador e com o
> curl**, para descobrir **o que a aplicação permite e diz que o R6 e o R7 não explicitam**.

O alvo são os estados de pedido do R6. Os recursos são as quatro ações e dois jeitos de enviá-las. A
informação é a distância entre o que os requisitos dizem e o que a aplicação faz, que é exatamente o
que um roteiro escrito a partir desses requisitos não consegue ver.

## Larga demais, estreita demais

Uma missão pode errar em duas direções, e as duas são comuns.

**Larga demais**: *Explore o boxoffice.* Nada nela diz por onde começar, quando parar ou o que uma
boa sessão teria encontrado, então a sessão vai para onde a primeira tela interessante a levar, e a
folha depois não diz nada que um gerente possa usar.

**Estreita demais**: *Confira que dá para reservar seis ingressos.* Isso é um caso de teste com a
palavra "explore" na frente. Tem um resultado esperado e não deixa nada para descobrir; pertence a
uma suíte, e a aula 9 já o rodou.

Uma boa missão é larga o bastante para exigir julgamento e estreita o bastante para ser concluída.
Mais algumas para o boxoffice 1.1, cada uma valendo uma sessão:

- Explore **o cadastro** com **nomes e endereços no limite do R2 e além dele, e caracteres de outros
  idiomas**, para descobrir como ele trata entradas que ninguém digitou de propósito.
- Explore **a reserva perto do horário de fechamento de um espetáculo** com **o `BOXOFFICE_NOW`
  ajustado para momentos em volta dele**, para descobrir o que muda quando um espetáculo se aproxima.
- Explore **a contagem de lugares** com **muitos pedidos pequenos, cancelamentos e reembolsos**, para
  descobrir se o número na página Shows sempre bate com o que foi vendido.

## De onde vêm as missões

As missões ficam numa lista, e a lista é alimentada pelos mesmos lugares que o resto do teste: os
riscos da aula 1, que dizem onde uma sessão vale mais; os requisitos, especialmente aqueles cujos
casos roteirizados pareceram ralos; os defeitos, porque um defeito novo é motivo para explorar a
vizinhança dele; e as sessões anteriores, cujas conversas finais terminam com perguntas que não
estavam na missão. Em geral é o testador quem as escreve, e o líder decide com ele quais rodam nesta
semana.

## O tempo fixo

Uma sessão tem duração fixa, escolhida antes de começar. A gestão de teste baseada em sessões usa
cerca de 90 minutos como sessão normal, com sessões curtas de cerca de uma hora e longas de cerca de
duas, e o objetivo do tempo fixo é ser **sem interrupção**: sem reuniões, sem mensagens, uma missão.
Uma sessão interrompida a cada dez minutos são várias sessões curtas, cada uma gastando os primeiros
minutos para se achar de novo.

**A missão é uma direção, e a sessão pode sair dela.** Quando aparece algo interessante fora da
missão, o testador anota como uma *oportunidade* e decide: seguir agora, se valer mais que o resto da
missão, ou deixar para uma missão própria. A folha da sessão diz quanto tempo foi para a missão e
quanto para oportunidades, para que uma sessão gasta quase toda em outro lugar fique visível em vez
de escondida.
