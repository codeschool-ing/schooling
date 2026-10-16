---
title: Escolhendo a suíte
version: 1
---

A definição tentadora de teste de regressão é "rodar todo teste de novo", e ela tem nome, **retestar
tudo**. É a escolha mais segura e raramente cabe no orçamento: um produto com algumas centenas de
casos e uma versão por semana não pode gastar três dias de cada semana rodando todos à mão. Então a
suíte de regressão é escolhida, versão a versão, e **a escolha é a habilidade**: uma suíte que roda
tudo termina depois que a versão já saiu, e uma que roda o que for mais rápido deixa passar o
defeito que importava.

## Três jeitos de reduzi-la

**Por risco.** A aula 1 ordenou o que pode dar errado no boxoffice por probabilidade e impacto, e
essa ordem já diz o que merece ser rodado de novo primeiro. Do topo para baixo: A, um preço errado; B, um espetáculo
vendido além dos lugares; C, um reembolso que não devia acontecer; D, um e-mail de confirmação que
nunca chega; E, uma tabela de espetáculos difícil de ler no celular. Quando o tempo aperta, os casos
do fim da lista são os que ficam de fora.

**Pela mudança.** O que esta versão mexeu, e o que depende do que ela mexeu? Esta é a **análise de
impacto** da mudança, e as fontes dela são as notas de versão, uma conversa com o desenvolvedor e,
quando o testador consegue ler, a própria mudança. Uma parte em que ninguém mexeu e da qual nada
depende pode pular uma versão; uma parte que foi reescrita, não.

**Pelo histórico.** Áreas que já quebraram quebram de novo: código complicado continua complicado,
e os motivos de ele ter saído errado também. Todo defeito encontrado é evidência sobre a
probabilidade, como disse a aula 1, e as partes com a lista mais longa de defeitos passados ganham
lugar em toda rodada.

Nenhum dos três basta sozinho. Só o risco roda de novo os mesmos casos seja qual for a mudança; só a
mudança deixa passar a regressão que vem do ambiente; só o histórico protege os problemas de ontem.
Na prática eles se combinam: **a mudança decide o que provavelmente quebrou, e o risco decide o
quanto vale conferir cada parte**.

## A suíte da 1.1

As notas do Rui citam duas mudanças: `discount` foi reescrita, e a verificação de quantidade agora
aceita seis. Lidas contra a ordem de riscos da aula 1, elas dão esta suíte:

| área | mudou na 1.1? | decisão | casos |
|---|---|---|---|
| A, preço | sim: `discount` reescrita | toda regra da tabela de desconto da aula 5 | 8 |
| quantidade na reserva, R4 | sim: o limite mudou | os limites da aula 4, e a entrada que não é número | 5 |
| B, lugares | não, mas um pedido agora pode levar seis | lugares tomados por um pedido, devolvidos por um cancelamento | 2 |
| C, estados do pedido | não | o caminho principal do R6, e o reembolso de um pedido usado | 3 |
| D, e-mail de confirmação | não | um cadastro, e o e-mail dele na caixa de saída | 2 |
| E, layout no celular | não | fora desta versão: nenhuma página mudou | 0 |

Vinte verificações, cerca de uma hora à mão. Três decisões nela merecem uma frase cada.

**A área de preço recebe as oito regras**, e não só as duas que a aula 9 já conferiu. Três
descontos podem valer ou não, o que dá oito combinações, e todas passam pela função reescrita. A
aula 5 montou a tabela; a suíte de regressão a reaproveita em vez de inventar uma menor, porque a
tabela é exatamente a lista do que a função antiga tratava.

**Dois casos da suíte devem falhar**: a entrada que não é número, e o reembolso de um pedido usado,
que são os dois defeitos conhecidos das notas do Rui. Eles continuam na suíte porque o dia em que
passarem é o dia em que alguém os corrigiu, e o dia em que um deles falhar de outro jeito também vale
saber. O resultado esperado deles nesta rodada é "falha como relatado", e a rodada o registra
assim.

**O E fica de fora, e o motivo está escrito.** Nada na 1.1 mudou o layout de uma página, e o defeito
de celular que a aula 7 encontrou continua aberto e igual. Se a 1.1 tivesse mexido no modelo de
página, a mesma decisão iria para o outro lado. Uma linha com zero casos e um motivo é uma decisão
que alguém pode contestar; uma linha ausente é uma lacuna, como a aula 1 disse do escopo.

## A ordem da rodada

A suíte roda na ordem dos riscos, para que, se a hora for cortada para vinte minutos, o que ficar sem
teste seja o que menos importa: as oito regras de preço primeiro, depois quantidade, depois lugares,
estados e e-mail. Uma exceção prática vem antes de tudo: a segunda conta. A tabela de desconto
precisa de um cliente que não seja sócio, e a única conta com que o boxoffice começa é a da Bia
Souza, que é. Então a rodada começa criando uma, que é também a verificação de cadastro da linha D,
feita cedo porque tudo o que vem depois depende dela.

Todo caso da tabela já existe. As aulas 4 e 5 os escreveram para a 1.0, e a aula 9 acrescentou os
retestes. **Uma suíte de regressão é, na maior parte, casos que você já escreveu, escolhidos de
novo**, e a próxima seção roda esta na 1.1.
