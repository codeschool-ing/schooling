---
title: Reaproveitando dados, e voltando ao começo
version: 1
---

Dados que funcionaram uma vez deveriam funcionar de novo, e é aí que a maioria dos dados de teste
dá errado. **Um caso só pode ser repetido se os dados de onde parte forem os mesmos toda vez, e isso
pede duas coisas: dados que saem iguais sempre que são feitos, e um caminho de volta ao estado
anterior a eles.** O boxoffice tem as duas, e é por isso que as transcrições deste curso podem dizer
"pedido 1001" e acertar na sua máquina.

## Rodando a mesma coisa duas vezes

A seção 03 desta aula cadastrou cinco contas. Rode o mesmo programa de novo, sem mexer no boxoffice:

```
ana@laptop:~/boxoffice$ python3 make_accounts.py 5
test001@example.org  There is already an account with that e-mail.
test002@example.org  There is already an account with that e-mail.
test003@example.org  There is already an account with that e-mail.
test004@example.org  There is already an account with that e-mail.
test005@example.org  There is already an account with that e-mail.
```

Nada está errado no boxoffice. As cinco contas já existem desde a primeira execução, e o R2 fala de
um endereço que nenhuma outra conta usa, então as cinco são recusadas, corretamente. Mas um caso
escrito como "rodar make_accounts.py, esperar cinco contas criadas" passou um minuto atrás e falha
agora, e nada no produto mudou nesse meio-tempo. **Os dados da última execução fazem parte do estado
de onde a próxima parte**, e um caso que não os controla está testando a própria história.

## O boxoffice volta ao início ao reiniciar

O boxoffice guarda tudo na memória, como a aula 1 disse, então pará-lo com Ctrl-C no terminal dele e
iniciá-lo de novo com `python3 boxoffice.py` joga fora toda conta, pedido e mensagem que foram
acrescentados. Faça isso e rode o programa mais uma vez:

```
ana@laptop:~/boxoffice$ python3 make_accounts.py 5
test001@example.org  Account created. We sent a link to test001@example.org.
test002@example.org  Account created. We sent a link to test002@example.org.
test003@example.org  Account created. We sent a link to test003@example.org.
test004@example.org  Account created. We sent a link to test004@example.org.
test005@example.org  Account created. We sent a link to test005@example.org.
```

Criadas de novo, as mesmas cinco, porque a semente no `make_accounts.py` faz as mesmas cinco toda vez
e o reinício pôs o boxoffice de volta onde começou. As duas coisas juntas são tudo o que dados de
teste repetíveis são, e cada técnica abaixo é um jeito de obtê-las onde elas não vêm de graça.

## Os valores que precisam ser iguais em toda execução

O acaso é útil para variedade e ruim para repetição. Um caso que cadastra um nome aleatório hoje e
outro amanhã não pode ser comparado consigo mesmo, e uma falha que aconteceu com um nome se perde
quando a próxima execução sorteia outro. A **semente** mantém a variedade e tira a surpresa:
`random.Random(1)` produz uma lista de cara diferente da de `random.Random(2)`, e a mesma lista toda
vez que é chamado.

O boxoffice aplica a mesma ideia a si mesmo em dois lugares, os dois definidos pelo ambiente e os
dois vistos em aulas anteriores. `BOXOFFICE_SEED` faz os links de confirmação saírem iguais em toda
execução, e `BOXOFFICE_NOW` fixa o relógio, o que a aula 13 chamou de relógio falso. As transcrições
deste curso foram gravadas com os dois definidos, e é por isso que as datas e os links delas são os
mesmos em toda gravação. As suas diferem exatamente nessas duas coisas, porque você inicia o
boxoffice sem eles.

## Sistemas reais não voltam ao início ao reiniciar

A maioria das aplicações guarda os dados num banco que sobrevive a um reinício, então o caminho de
volta precisa ser construído. Os times usam três abordagens, muitas vezes juntas:

| abordagem | como funciona | o que custa |
|---|---|---|
| restaurar antes da execução | o banco volta a um estado salvo e conhecido antes de o teste começar | alguém mantém o estado salvo em dia conforme o produto muda |
| cada caso cria o seu | um caso cria a conta ou o pedido de que precisa, com um valor que ninguém mais usa | mais dados se acumulam, e os casos dependem das partes que os criam |
| limpar depois | cada caso apaga o que criou | um caso que falha no meio deixa os dados para a próxima execução |

**Restaurar antes é a mais confiável das três**, porque não depende de a última execução ter
terminado direito. Limpar depois é a mais frágil pelo mesmo motivo: a execução que falha é justamente
a que deixa bagunça.

## Dividindo um ambiente

O problema de dados mais difícil são duas pessoas. A Ana e o Rui testam no mesmo ambiente
compartilhado, os dois reservam com a conta de sócia, e a execução do Rui gasta os últimos lugares
de que o caso da Ana precisava. Nenhum dos dois fez nada errado, e o caso da Ana falha mesmo assim.
As correções são as de cima, aplicadas por pessoa: cada testador tem contas próprias, o que
endereços numerados facilitam, e os casos que precisam de um estado inicial conhecido rodam onde
ninguém mais o está mudando. A aula 21 trata dos próprios ambientes, e de por que um caso que passa
numa máquina falha em outra.
