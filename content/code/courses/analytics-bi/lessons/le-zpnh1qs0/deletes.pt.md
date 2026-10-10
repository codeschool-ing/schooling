---
title: Um cliente que não está mais no modelo
version: 1
---

O modelo pode perder linhas. Um cliente pede para ser esquecido, e a loja o apaga; uma definição muda,
e o modelo passa a mandar só clientes ativos. De um jeito ou de outro, um contato que está no CRM e não
está mais no modelo precisa ser tratado, e **a resposta certa depende de por que ele saiu**.

A exclusão é o caso sem escolha. A lei brasileira de proteção de dados, a LGPD, dá à pessoa o direito de
ter seus dados pessoais eliminados, e uma cópia no CRM é dado pessoal dela tanto quanto a linha no banco
da loja. Apagá-la da origem e deixá-la no CRM é uma exclusão que não aconteceu.

O cliente 2 pede para ser esquecido, e a loja o apaga:

```
lantern=# DELETE FROM shop.customers WHERE customer_id = 2;
DELETE 1
ana@vm:~/reverse$ bash sync.sh
run 3: sent 0, removed 1, failed 0, retried after 429: 0
ana@vm:~/reverse$ curl -s -w '\n' 'localhost:8000/contacts?external_id=lantern-2'
[]
```

O segundo laço da sincronização achou o contato que `last_sent` lembra e o modelo não tem mais, e mandou
`DELETE`. O CRM responde que não guarda mais nada com essa chave. E o log, em `sync_log`, guarda o id
externo e a hora da exclusão — que é o que um auditor perguntando "quando os dados dessa pessoa saíram
do CRM?" precisa, e nada sobre a pessoa.

## Quando sair do modelo não é exclusão

Se um contato sai do modelo porque um filtro mudou — o modelo manda só clientes ativos no último ano, e
este ficou quieto —, apagá-lo do CRM destrói o histórico que os vendedores escreveram nele: ligações,
notas, promessas. As ferramentas costumam oferecer uma escolha para esse caso, e a aula 8 dá nome às
opções; o padrão seguro é **limpar os campos sincronizados** e manter o registro, e apagar só quando o
motivo é que o cliente não pode estar lá de jeito nenhum.
