---
title: O que o moto é, e o que ele não é
version: 1
---

**O moto responde como a AWS e impõe muito menos.** É um programa Python escrito para testar
outros programas: recebe as mesmas requisições que os serviços de verdade recebem, nos mesmos
caminhos e no mesmo formato, e devolve respostas no formato que a AWS documenta. Por trás dessas
respostas há um dicionário na memória. Um bucket é uma entrada nele, um objeto são bytes nele, e um
banco de dados é um registro com um nome e um status. Isso basta para aprender a interface de um
serviço, e não basta para aprender o comportamento dele, e este curso diz qual dos dois cada lição
está mostrando.

Três demonstrações deixam a diferença concreta. As duas primeiras são sobre quem pode entrar, e a
terceira é sobre trabalho que o moto não faz:

```
ana@laptop:~/aws$ aws s3 mb s3://quitanda-moto-demo
make_bucket: quitanda-moto-demo
ana@laptop:~/aws$ echo hello > note.txt && aws s3 cp note.txt s3://quitanda-moto-demo/note.txt
upload: ./note.txt to s3://quitanda-moto-demo/note.txt          
ana@laptop:~/aws$ AWS_ACCESS_KEY_ID=nobody-issued-this AWS_SECRET_ACCESS_KEY=wrong aws s3 ls s3://quitanda-moto-demo
2026-10-16 12:31:09          6 note.txt
ana@laptop:~/aws$ curl -s -o /dev/null -w '%{http_code}\n' http://localhost:4567/quitanda-moto-demo/note.txt
403
ana@laptop:~/aws$ aws athena start-query-execution --query-string "SELECT count(*) FROM orders" --result-configuration OutputLocation=s3://quitanda-moto-demo/athena/
{
    "QueryExecutionId": "768774a0-842f-4668-afd6-741d06d99814"
}
ana@laptop:~/aws$ aws athena get-query-execution --query-execution-id 768774a0-842f-4668-afd6-741d06d99814 --query 'QueryExecution.[Status.State,Statistics.DataScannedInBytes]' --output text
SUCCEEDED	0
ana@laptop:~/aws$ aws athena get-query-results --query-execution-id 768774a0-842f-4668-afd6-741d06d99814 --query 'ResultSet.Rows'
[]
```

**Uma chave que ninguém emitiu foi aceita.** A listagem foi assinada com `nobody-issued-this`, uma
chave que nenhuma conta jamais teve, e o moto respondeu como se fosse sua. No S3 a mesma requisição
falha com `InvalidAccessKeyId`. A linha do `curl` é a outra metade: uma requisição HTTP simples, sem
assinatura nenhuma, e o moto respondeu `403`, porque o bucket é privado e uma requisição anônima a um
bucket privado é recusada. **O moto confere que a requisição está assinada e, por padrão, não quem
assinou**, e não avalia política nenhuma, então toda ação que uma política deveria negar dá certo. A
lição 4 liga a parte do moto que avalia políticas de identidade, porque uma lição sobre quem pode ler
um bucket não pode ser ensinada por um servidor que deixa entrar toda requisição assinada.

**A consulta deu certo, leu 0 bytes e não devolveu nada.** Não existe tabela chamada `orders` em lugar
nenhum, e o Athena teria falhado com um erro dizendo o nome dela. O moto registra a consulta, a marca
como `SUCCEEDED` e não roda SQL nenhum. O mesmo vale para um job do Glue, que "dá certo" sem rodar uma
linha de Spark, para um banco do RDS, que fica `available` na hora e não tem motor de banco por trás,
e para um cluster do Redshift. Quando uma lição precisa do comportamento de um deles, ela o tira de
algo real: o DuckDB para o SQL, a tabela de preços para o dinheiro, e a documentação da própria AWS
para o resto, com o texto dizendo com todas as letras que aquela parte não foi executada.

## O que ele faz, com fidelidade

Os serviços cujo comportamento é estrutura de dados, e não máquina, são onde o moto está no seu
melhor, e eles são boa parte deste curso:

| serviço | o que o moto faz de verdade |
|---|---|
| S3 | guarda os bytes, lista por prefixo, mantém versões, recusa apagar um objeto travado |
| DynamoDB | avalia condições de chave, filtros e escritas condicionais; mantém um stream de mudanças |
| Kinesis Data Streams | faz o hash da chave de partição para um shard e mantém os registros em ordem por shard |
| Data Firehose | entrega o que recebe no S3, sob um prefixo com a data |
| Glue Data Catalog | guarda bancos, tabelas, partições e as versões de uma tabela |

E três coisas que ele nunca faz, seja qual for o serviço: **não manda conta, não espera nada e só
falha quando mandam.** Um cluster que leva vinte minutos para subir na AWS fica pronto na mesma linha.
Um disco não enche, uma zona não cai, um shard nunca é estrangulado. As lições sobre essas falhas as
ensinam a partir do comportamento documentado.

**Trate um sucesso do moto como "a requisição estava bem formada", nunca como "isto funcionaria".** É a
frase mais útil deste curso, e a mais fácil de esquecer.
