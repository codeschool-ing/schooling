---
title: Mudando uma tabela, e as versões que ficam
version: 1
---

**Uma tabela muda sendo substituída inteira, e o catálogo guarda a que ela substituiu.** O
`update-table` recebe uma descrição de tabela completa, o mesmo JSON que o `create-table` recebeu, e
a descrição anterior vira uma versão numerada. Nada é editado no lugar, a mesma regra que a lição 1
encontrou para um objeto do S3, e pelo mesmo motivo: um leitor no meio de uma consulta deve manter a
descrição com que começou.

Em novembro a loja da Quitanda começa a aceitar cupons, e a exportação ganha uma coluna. A tabela
precisa dizer isso. Depois, na mesma semana, alguém decide que os totais devem estar em reais em vez
de centavos, e muda o tipo. As duas coisas são um `jq` e um `update-table`:

```
ana@laptop:~/aws$ jq '.StorageDescriptor.Columns += [{"Name": "coupon", "Type": "string"}]' orders-table.json > orders-table-2.json
ana@laptop:~/aws$ aws glue update-table --database-name quitanda --table-input file://orders-table-2.json
ana@laptop:~/aws$ jq '(.StorageDescriptor.Columns[] | select(.Name == "total_cents") | .Type) = "double"' orders-table-2.json > orders-table-3.json
ana@laptop:~/aws$ aws glue update-table --database-name quitanda --table-input file://orders-table-3.json
ana@laptop:~/aws$ aws glue get-table-versions --database-name quitanda --table-name orders --query 'TableVersions[].[VersionId,length(Table.StorageDescriptor.Columns),Table.StorageDescriptor.Columns[4].Type]' --output text
1	7	bigint
2	8	bigint
3	8	double
```

**Três versões: sete colunas, depois oito, depois oito com `total_cents` como `double`.** O moto as
guarda fielmente, e o catálogo na AWS também. Uma versão é uma descrição de tabela inteira, então
voltar atrás é um `update-table` com uma antiga, o mais perto de um desfazer que o catálogo tem. Ela
também é um objeto, contado no milhão grátis como uma partição, e **um crawler deixado em
`UPDATE_IN_DATABASE` acrescenta uma toda vez que um arquivo discorda da tabela**. Ninguém esgota um
milhão de versões à mão; um crawler apontado para um prefixo barulhento toda hora pode fazer do
histórico de uma tabela a maior coisa do catálogo.

## As partições ficaram com as colunas antigas

```
ana@laptop:~/aws$ aws glue get-partition --database-name quitanda --table-name orders --partition-values 2026-10-15 --query 'Partition.StorageDescriptor.Columns[-1].Name' --output text
neighbourhood
ana@laptop:~/aws$ aws glue get-table --database-name quitanda --name orders --query 'Table.StorageDescriptor.Columns[-1].Name' --output text
coupon
```

**A tabela termina em `coupon` e a partição de 15 de outubro termina em `neighbourhood`.** Cada
partição levou uma cópia do storage descriptor quando o `partitions.py` a criou, colunas incluídas,
e um `update-table` muda a tabela e nenhuma das 31 partições. Isso é de propósito, já que os arquivos de um dia antigo têm mesmo sete colunas. É também onde as consultas quebram: um motor que compara as colunas de uma partição com as da tabela pode recusar a partição, e o erro do Athena para
uma coluna cujo tipo difere entre as duas é `HIVE_PARTITION_SCHEMA_MISMATCH`. A mudança de tipo da
versão 3 é exatamente esse caso, uma tabela que diz `double` sobre 31 partições que dizem `bigint`.

Dois jeitos de mantê-las em dia: `batch-update-partition` no programa que mudou a tabela, ou um
crawler com a configuração que faz as partições herdarem o esquema da tabela. Nenhum dos dois foi
preciso para a coluna acrescentada, que uma partição sem ela pode simplesmente não ter; a mudança de
tipo é a que pede uma decisão.

## Onde o moto e a AWS diferem

```
ana@laptop:~/aws$ aws glue update-table --database-name quitanda --table-input file://orders-table-2.json --skip-archive
ana@laptop:~/aws$ aws glue get-table-versions --database-name quitanda --table-name orders --query 'TableVersions[].VersionId' --output text
1	2	3	4
```

**O `--skip-archive` fez uma quarta versão mesmo assim.** Na AWS a opção quer dizer exatamente o
contrário: atualizar a tabela sem arquivar a descrição anterior, que é como um job que reescreve uma
tabela toda noite evita deixar uma versão a cada vez. O moto a ignora. Um teste que conta versões
contra o moto passaria aqui e contaria diferente numa conta real, que é o tipo de diferença que a
lição 1 pediu para você esperar.
