---
title: Exatamente uma vez, e o que merece o nome
version: 1
---

**Exatamente uma vez é o resultado de entrega pelo menos uma vez com um destino que torna a segunda
entrega inofensiva.** Nenhuma configuração num event hub liga isso, porque a metade do trabalho que é
do event hub é só a entrega; o que acontece com o resultado é decidido onde o resultado é gravado.
Esta seção executa o outro jeito de merecer o nome, e depois lê o que os serviços do Azure querem
dizer quando usam as palavras.

## O número de sequência como marca d'água

**Dentro de uma partição, uma repetição relê os eventos na mesma ordem com os mesmos números de
sequência.** Então um leitor pode guardar, ao lado dos resultados e na mesma gravação, o último número
de sequência que aplicou, e pular tudo o que for igual ou menor. Esse é o modo `guard` do
`totals.py`: os totais e o último número de sequência moram num blob só, enviado numa operação só,
então os dois nunca podem discordar depois de uma queda. A mesma queda e o mesmo reinício:

```
ana@laptop:~/azure$ python totals.py guard 5
seq 0  o-301 c-17   4590  added, with its sequence number
seq 1  o-302 c-02  12800  added, with its sequence number
seq 2  o-303 c-17    990  added, with its sequence number
  checkpoint at seq 2
seq 3  o-303 c-17    990  added, with its sequence number
seq 4  o-304 c-05   2350  added, with its sequence number
  crash
ana@laptop:~/azure$ python totals.py guard
seq 3  o-303 c-17    990  skipped, already in the state
seq 4  o-304 c-05   2350  skipped, already in the state
seq 5  o-305 c-02   1500  added, with its sequence number
  checkpoint at seq 5
seq 6  o-306 c-17   7200  added, with its sequence number
totals: c-02 14300  c-05 2350  c-17 13770
```

**A repetição foi pega**: os números de sequência 3 e 4 voltaram, foram encontrados iguais ou abaixo
do 4 guardado no estado, e foram pulados. `c-05` está em 2.350, certo. **E `c-17` está em 13.770, o
que continua errado**, por 990: a nova tentativa do produtor é um segundo evento com número de
sequência próprio, o 3, que a primeira execução aplicou como novo. Uma marca d'água de números de
sequência pega o que o leitor repete e é cega ao que o produtor repetiu. A chave do id do pedido da
seção anterior pegou os dois, e é por isso que uma chave do negócio, decidida antes do primeiro envio,
é o conserto mais forte.

Duas condições fazem a marca d'água funcionar, e as duas são fáceis de quebrar. **O estado e o número
de sequência precisam ser gravados juntos**: gravados como dois blobs, uma queda entre eles é o mesmo
problema de novo, um nível abaixo. E **a marca d'água é por partição**: um leitor de quatro partições
guarda quatro, porque o número de sequência 5 na partição 0 e na partição 3 não têm relação, como a
lição 22 mostrou.

## O que os serviços querem dizer com isso

**Esta parte vem da documentação da Microsoft e não foi executada.** O Stream Analytics é o único
serviço deste curso que usa as palavras, e é preciso sobre onde elas param: **processamento**
exatamente uma vez dentro do job, o que quer dizer que um job que reinicia depois de uma falha produz
os mesmos resultados a partir da mesma entrada, e **entrega** pelo menos uma vez às saídas. Uma linha
do contador de checkouts pode ser gravada duas vezes na tabela SQL depois de uma falha, e a chave da
tabela, ou um upsert, é o que torna isso inofensivo. A promessa termina na borda do job, que é a forma
de toda afirmação de exatamente uma vez: ela é verdadeira dentro de um sistema e para onde o resultado
sai dele.

**Então a pergunta a fazer a qualquer pipeline é onde mora a idempotência dele**, etapa por etapa.
Para os pagamentos da Quitanda: o produtor da loja pode enviar duas vezes, então o evento leva o id do
pedido; o Event Hubs entrega pelo menos uma vez; o leitor pode repetir, então grava pelo id do pedido;
os totais são calculados a partir dos pagamentos em vez de incrementados. Toda etapa que pode repetir
algo é seguida por uma etapa que não se importa. É disso que é feito o exatamente uma vez, e ele é
projetado, não configurado.
