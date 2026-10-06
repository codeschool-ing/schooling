---
title: Comparando dois pipelines
version: 1
---

Uma medição é mais útil como comparação: o pipeline como está, contra o pipeline com uma coisa mudada.
O `evaluate.py` recebe o piso e o k como opções, então as duas mudanças que as aulas 6 e 7 discutiram
podem ser testadas no dev sem mexer em código nenhum.

## Baixando o piso

A aula 6 ofereceu uma escolha: um piso de 0,5, que recusa a pergunta das parcelas junto com as sem
resposta, ou 0,44, que a deixa passar e deixa a pergunta do telefone chegar ao modelo também.

```
ana@lab:~/rag$ python evaluate.py --split dev --floor 0.44
dev: 20 questions, 18 answerable, floor 0.44, k 3
retrieval  recall@1 13/18  recall@3 18/18  recall@5 18/18  MRR 0.86
answers    correct 15/20  refused rightly 2/2  faithful 20/20
ana@lab:~/rag$ python evaluate.py --split dev --floor 0.44 --list | grep e14
e14  rank 2  answered  WRONG    faithful  Can I pay in instalments?
ana@lab:~/rag$ python -c "import answer; answer.FLOOR = 0.44; print(answer.answer(\"Can I pay in instalments?\", where=\"status = %s\", params=(\"current\",))[0])"
Instalments are offered by your card issuer under its own terms. [1]
```

**Os totais não se mexeram: 15 de 20 corretas, as duas sem resposta ainda recusadas.** Mas a e14 mudou
por baixo deles. Com 0,5 ela era recusada; com 0,44 foi respondida, com *Instalments are offered by your
card issuer under its own terms*, que é verdade, citada e não é a resposta: a resposta é *up to three
instalments with no interest on orders over 120*. Uma recusa virou uma resposta errada. E a pergunta do
telefone, agora acima do piso, foi recusada mesmo assim, pelo limiar próprio do extract-1; um modelo real
talvez não fosse tão cuidadoso.

**O mesmo total pode esconder um sistema pior.** Uma resposta errada entregue com confiança é pior para um
cliente que *I could not find that*, e o total conta as duas igual. É por isso que o `--list` existe e
por que uma comparação deveria informar o que mudou em cada pergunta, não só as somas.

## Menos fontes

```
ana@lab:~/rag$ python evaluate.py --split dev --k 1
dev: 20 questions, 18 answerable, floor 0.5, k 1
retrieval  recall@1 13/18  recall@3 18/18  recall@5 18/18  MRR 0.86
answers    correct 14/20  refused rightly 2/2  faithful 20/20
```

Com uma fonte em vez de três, a correção caiu de 15 para 14. A revocação em 1 era 13 de 18, então para
cinco perguntas com resposta a única fonte enviada não era a que tinha a resposta; uma delas tinha sido
respondida certo a partir da segunda fonte quando havia três. Menos tokens, uma resposta errada a mais:
se essa troca vale a pena é uma pergunta que a aula 12 mede direito, com empacotamento em vez de um corte
grosseiro.

## Regras para uma comparação confiável

**Mude uma coisa.** Duas mudanças de uma vez dão um número e nenhum jeito de dizer de qual mudança ele é.

**Use o mesmo conjunto de teste, a mesma parte e a mesma verificação de correção** dos dois lados. Uma
comparação com o conjunto de teste mudado mede o conjunto de teste.

**Leia as perguntas que mudaram**, não só os totais. Acima, os totais eram idênticos e uma pergunta piorou.

**Prefira diferenças grandes.** Em vinte perguntas, uma são cinco pontos. Uma diferença de uma pergunta é
motivo para olhar, não para decidir.

**Guarde o registro.** A linha de comando, o commit e a saída, num arquivo ao lado da mudança feita por
causa deles. Daqui a seis meses alguém vai perguntar por que o piso é 0,5, e a resposta deveria ser uma
medição, não uma lembrança.
