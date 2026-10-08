---
title: Comparando dois pipelines
version: 2
---

Uma medição é mais útil como comparação: o pipeline como está, contra o pipeline com uma coisa mudada.
O `evaluate.py` recebe o piso e o k como opções, então as duas mudanças que as aulas 6 e 7 discutiram
podem ser testadas no dev sem mexer em código nenhum.

## Baixando o piso

A aula 6 ofereceu uma escolha: um piso de 0,5, que recusa a pergunta das parcelas junto com as sem
resposta, ou 0,44, que a deixa passar e deixa a pergunta do telefone chegar ao modelo também.

```
ana@vm:~/rag$ python evaluate.py --split dev --floor 0.44
dev: 20 questions, 18 answerable, floor 0.44, k 3
retrieval  recall@1 13/18  recall@3 18/18  recall@5 18/18  MRR 0.86
answers    correct 16/20  refused rightly 2/2  faithful 9/20
ana@vm:~/rag$ python evaluate.py --split dev --floor 0.44 --list | grep e14
e14  rank 2  answered  correct  UNFAITHFUL  Can I pay in instalments?
ana@vm:~/rag$ python -c "import answer; answer.FLOOR = 0.44; print(answer.answer(\"Can I pay in instalments?\", where=\"status = %s\", params=(\"current\",))[0])"
According to [1] 4.1, instalments are offered by your card issuer under its own terms, but it does not specify the maximum amount for instalments. However, [2] 1 states that a card payment can be split into up to three instalments with no interest on orders over 120. Since [2] is updated more recently than [1], I prefer [2] as the more up-to-date source. Therefore, yes, you can pay in instalments, but the maximum amount is 120.
```

**Uma correta a mais, 16 de 20, e as duas sem resposta ainda recusadas.** A e14 mudou: com 0,5 ela era
recusada, e com 0,44 foi respondida pelo documento de pagamentos, *a card payment can be split into up
to three instalments with no interest on orders over 120*, depois de uma frase sobre emissores de
cartão de outra fonte. E a pergunta do telefone, agora acima do piso, chegou ao modelo, que a recusou,
seguindo a instrução da aula 7.

**Um total melhor ainda pode esconder um sistema pior.** O piso que deixou a e14 passar deixa toda
pergunta de correspondência fraca chegar ao modelo, e se o modelo depois recusa é uma instrução, seguida
na maior parte das vezes, onde o piso era uma regra seguida sempre. Uma resposta errada entregue com
confiança é pior para um cliente que *I could not find that*, e o total conta as duas igual. É por isso
que o `--list` existe e por que uma comparação deveria informar o que mudou em cada pergunta, não só as
somas.

## Menos fontes

```
ana@vm:~/rag$ python evaluate.py --split dev --k 1
dev: 20 questions, 18 answerable, floor 0.5, k 1
retrieval  recall@1 13/18  recall@3 18/18  recall@5 18/18  MRR 0.86
answers    correct 10/20  refused rightly 2/2  faithful 11/20
```

Com uma fonte em vez de três, **a correção caiu de 15 para 10**. A revocação em 1 era 13 de 18, então
para cinco perguntas com resposta a única fonte enviada não era a que tinha a resposta, e cinco é a
queda. A fidelidade subiu, 11 de 20 contra 9: com uma fonte só, há menos para citar errado. Menos
tokens, cinco respostas erradas a mais: se um contexto menor vale a pena é uma pergunta que a aula 12
mede direito, com empacotamento em vez de um corte grosseiro.

## Regras para uma comparação confiável

**Mude uma coisa.** Duas mudanças de uma vez dão um número e nenhum jeito de dizer de qual mudança ele é.

**Use o mesmo conjunto de teste, a mesma parte e a mesma verificação de correção** dos dois lados. Uma
comparação com o conjunto de teste mudado mede o conjunto de teste.

**Leia as perguntas que mudaram**, não só os totais. Acima, o total do piso mudou em uma
pergunta, e o que o mudou foi uma resposta que valia ler.

**Prefira diferenças grandes.** Em vinte perguntas, uma são cinco pontos. Uma diferença de uma pergunta é
motivo para olhar, não para decidir.

**Guarde o registro.** A linha de comando, o commit e a saída, num arquivo ao lado da mudança feita por
causa deles. Daqui a seis meses alguém vai perguntar por que o piso é 0,5, e a resposta deveria ser uma
medição, não uma lembrança.
