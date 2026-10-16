---
title: Quanto custa uma chave
version: 1
---

O KMS é cobrado por chaves e por requisições:

```
ana@laptop:~/aws$ python3 price.py awskms Keys
awskms, sa-east-1, published 2026-09-11
  sa-east-1-KMS-Keys                       1.000000 USD per Keys       $1 per customer managed KMS key version in South America (Sao Paulo)
ana@laptop:~/aws$ python3 price.py awskms "kms requests"
awskms, sa-east-1, published 2026-09-11
  Global-KMS-Requests                      0.000000 USD per Requests   $0.00 per request - Monthly Global Free Tier for KMS requests
  sa-east-1-KMS-Requests                   0.000003 USD per Requests   $0.03 per 10000 KMS requests in South America (Sao Paulo)
```

**Uma chave gerenciada pelo cliente custa 1 USD por mês**, e a linha diz por **versão de chave**: cada
rotação acrescenta uma versão. A AWS documenta que a primeira e a segunda rotação somam uma mensalidade
cada e as seguintes não somam nada, então uma chave rotacionada todo ano custa 1, depois 2, depois 3 USD
por mês, e fica em 3. Chaves gerenciadas pela AWS, `aws/ssm` e as outras, não têm mensalidade.

**Requisições custam 3 centavos por 10.000**, depois de uma franquia que a AWS documenta como 20.000 por
mês para a conta toda; a linha `Global-` mostra o preço dela, nada, e não o tamanho. Chaves assimétricas e
a geração de pares de chaves têm linhas mais caras próprias.

## De onde vêm as requisições

A taxa das chaves é pequena e fixa. As requisições são onde uma conta de KMS cresce, e crescem com
**quantas vezes algo pede uma chave de dados ao KMS**:

| o que acontece | requisições ao KMS |
|---|---|
| `envelope.py seal` num arquivo | 1, qualquer que seja o tamanho |
| ler uma `SecureString` | 1 por leitura, que é o cache da lição 17 de novo |
| o S3 gravando um objeto com SSE-KMS | 1 por objeto, a menos que o bucket use uma **S3 Bucket Key** |
| o S3 lendo um objeto com SSE-KMS | 1 por objeto, a menos que o bucket use uma S3 Bucket Key |

Um bucket S3 que recebe 10 milhões de objetos pequenos por mês com SSE-KMS faz 10 milhões de requisições
para gravá-los: **30 USD por mês**, e mais 3 USD a cada milhão de objetos lidos. Com uma **S3 Bucket
Key**, o S3 pede ao KMS uma chave para o bucket e deriva dela as chaves dos objetos por um tempo, o que a
AWS documenta como um corte de até 99% nas requisições: o mesmo mês vira centavos. É uma configuração no
bucket, e é a primeira coisa a olhar quando uma linha de KMS na conta é maior do que as chaves explicam.
