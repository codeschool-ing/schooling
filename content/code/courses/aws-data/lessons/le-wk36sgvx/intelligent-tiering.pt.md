---
title: Intelligent-Tiering, e a taxa por ser vigiado
version: 1
---

**O Intelligent-Tiering é uma classe que move cada objeto entre camadas por conta própria**, conforme
a última vez em que ele foi lido, e cobra uma taxa mensal por objeto para ficar de olho. É a resposta
para "não sabemos como estes dados vão ser lidos", e é a resposta errada para objetos pequenos, porque
a taxa é por objeto e a economia é por gigabyte.

A AWS documenta as camadas dele assim. Um objeto começa na camada de acesso frequente, com preço de
Standard. Depois de 30 dias seguidos sem ser lido ele passa para uma camada de acesso infrequente, e
depois de 90 dias para uma camada de arquivo com acesso instantâneo, as duas mais baratas e as duas
lidas em milissegundos. Uma leitura o traz de volta para a frequente. Duas camadas a mais, de arquivo
e de arquivo profundo, ficam desligadas a menos que o bucket as ligue, e um objeto nelas precisa ser
restaurado como um do Glacier. Não há taxa de recuperação, nem duração mínima, nem cobrança por mudar
de camada.

A tabela de preços imprime duas linhas dele:

```
  Intelligent-Tiering, frequent                         0.04050  GB-month
  Intelligent-Tiering monitoring, per 1,000 objects     0.00250  per month
```

A tabela não imprime os preços das camadas infrequente e de arquivo, então este curso não cita uma
economia. O que as duas linhas acima permitem calcular é o custo de ser vigiado.

## A taxa contra o objeto

**Objetos abaixo de 128 KB não são monitorados nem pagam a taxa**; ficam na camada frequente enquanto
existirem, ao preço do Standard. Então o menor objeto que paga a taxa tem 128 KB, e para esse objeto a
conta é:

- o armazenamento na camada frequente: 128 KB são 128 / 1.048.576 GB, e isso × 0,04050 dá 0,00000494
  USD por mês;
- o monitoramento: 0,00250 / 1.000 dá 0,00000250 USD por mês.

**A taxa é metade do preço de guardar o objeto**, para um arquivo de 128 KB que nunca é lido e não sai
do lugar. Mesmo que uma camada mais barata tornasse o armazenamento de graça, só a taxa já impediria o
objeto de custar menos que metade do Standard. Com 1 MB a taxa cai para cerca de 6% do preço frequente,
e com 100 MB para bem menos de um décimo de um por cento. O Intelligent-Tiering compensa para objetos
grandes com futuro incerto: os arquivos Parquet do lago de dados da lição 19, não os eventos de 10 KB
de um fluxo de cliques.

## No moto

A classe em si é aceita como qualquer outra, e a configuração que liga as duas camadas de arquivo não
é:

```
ana@laptop:~/aws$ aws s3 cp export/orders-2026-09.csv s3://quitanda-archive-prod/orders/2026-09/auto.csv --storage-class INTELLIGENT_TIERING
upload: export/orders-2026-09.csv to s3://quitanda-archive-prod/orders/2026-09/auto.csv
ana@laptop:~/aws$ aws s3api head-object --bucket quitanda-archive-prod --key orders/2026-09/auto.csv --query StorageClass
"INTELLIGENT_TIERING"
ana@laptop:~/aws$ aws s3api put-bucket-intelligent-tiering-configuration --bucket quitanda-archive-prod --id archive-after-90 --intelligent-tiering-configuration 'Id=archive-after-90,Status=Enabled,Tierings=[{Days=90,AccessTier=ARCHIVE_ACCESS}]'

aws: [ERROR]: An error occurred (IllegalLocationConstraintException) when calling the PutBucketIntelligentTieringConfiguration operation: The unspecified location constraint is incompatible for the region specific endpoint this request was sent to.
```

**`IllegalLocationConstraintException` não é uma resposta sobre o Intelligent-Tiering**: é o erro de
criar um bucket na região errada. O moto 5.2.3 não implementa esta chamada, e a requisição, um `PUT` no
endereço do bucket, foi parar no código que cria buckets. Nada das camadas de arquivo pode ser
praticado aqui, e nada nesta seção depende disso. O moto também não move objeto nenhum entre camadas,
já que nada no moto acontece sozinho com o passar do tempo.
