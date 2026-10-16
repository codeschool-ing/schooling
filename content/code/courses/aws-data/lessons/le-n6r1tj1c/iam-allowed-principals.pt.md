---
title: IAMAllowedPrincipals, o modo híbrido e a porta que fica aberta
version: 1
---

**Ligar o Lake Formation não muda nada até alguém tirar a concessão do IAM.** Os padrões da seção
anterior dão a todo banco e toda tabela nova uma concessão `ALL` a `IAM_ALLOWED_PRINCIPALS`, e com
essa concessão no lugar o Lake Formation responde "sim" a qualquer um que o IAM já deixa entrar. A
concessão por coluna em `orders` não esconderia nada: a política de IAM do analista, que permite o
Athena e o bucket, basta para todas as colunas. É uma configuração de compatibilidade, e um lake pode
rodar com ela por anos com todo mundo acreditando que as suas concessões por coluna estão valendo.

## Assumindo uma tabela

**Passar uma tabela para o Lake Formation são dois passos, nesta ordem.** Primeiro conceda, no Lake
Formation, o que cada principal que usa a tabela precisa, como a seção anterior fez para os
analistas. Depois revogue o `ALL` de `IAM_ALLOWED_PRINCIPALS` naquela tabela. Feito ao contrário,
toda consulta na tabela falha entre os dois passos, porque a porta do IAM fechou e a do Lake
Formation ainda não abriu. Para as tabelas criadas depois, a mudança está nas configurações: deixe as
duas concessões padrão de fora, como o `put-data-lake-settings` do administrador fez, e as tabelas
novas começam sem concessão nenhuma.

O moto não reproduz a primeira metade disso. Na AWS, `orders`, criada enquanto os padrões estavam
valendo, teria a concessão a `IAM_ALLOWED_PRINCIPALS`, e o `list-permissions` a mostraria ao lado
da do analista; o moto não aplicou padrão nenhum, e a lista dele só tem as concessões que esta lição
fez, como mostra a seção de LF-tags. Então a revogação não tem o que remover aqui, e é descrita em
vez de rodada.

## O modo de acesso híbrido

**O modo de acesso híbrido deixa o IAM e o Lake Formation decidirem lado a lado, um local por vez.**
Um local registrado com acesso híbrido continua respeitando as permissões do IAM para todo mundo, e
os principais que foram incluídos, um por um, passam a ser julgados pelas concessões do Lake
Formation. É o jeito suave de migrar um lake que muitos times usam: inclua os analistas, confira que
os relatórios deles continuam rodando, depois o próximo time, e só no fim revogue a concessão do IAM.
O moto aceita o registro e não guarda nada dele:

```
ana@laptop:~/aws$ aws lakeformation register-resource --resource-arn arn:aws:s3:::quitanda-curated-prod/marketing --use-service-linked-role --hybrid-access-enabled
ana@laptop:~/aws$ aws lakeformation describe-resource --resource-arn arn:aws:s3:::quitanda-curated-prod/marketing
{
    "ResourceInfo": {
        "ResourceArn": "arn:aws:s3:::quitanda-curated-prod/marketing"
    }
}
ana@laptop:~/aws$ aws lakeformation create-lake-formation-opt-in --principal DataLakePrincipalIdentifier=arn:aws:iam::123456789012:role/analyst --resource '{"Table":{"DatabaseName":"curated","Name":"orders"}}'

aws: [ERROR]: An error occurred (404) when calling the CreateLakeFormationOptIn operation: <!doctype html>
<html lang=en>
<title>404 Not Found</title>
<h1>Not Found</h1>
<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try again.</p>
```

**O registro deu certo, o `describe-resource` não diz nada sobre acesso híbrido, e a inclusão
respondeu 404**, porque o moto não a implementa. Tudo sobre o modo híbrido aqui vem da documentação
da AWS e não foi rodado.

## A porta que o Lake Formation não vigia

**O Lake Formation governa os motores que perguntam a ele, e o S3 nunca ouviu falar dele.** Um
principal cuja política de IAM ainda permite `s3:GetObject` em `quitanda-curated-prod/curated/*` lê os
arquivos direto, com `aws s3 cp`, exatamente como a primeira seção desta lição fez, telefones
incluídos. Nenhuma concessão do Lake Formation impede isso, porque não há motor envolvido para
perguntar.

Então a segunda metade de assumir um lake fica do lado do IAM. **As pessoas e papéis que consomem os
dados perdem a permissão direta nos buckets registrados**; as políticas deles mantêm o Athena, o
catálogo e `lakeformation:GetDataAccess`, e os bytes só chegam a eles por um motor que confere as
concessões. Os únicos principais que ficam com `s3:GetObject` na camada curada são os que a
escrevem, como os jobs do Glue da lição 17, e o papel do próprio Lake Formation. Uma política de
bucket que nega leituras a todos os outros faz disso uma regra em vez de um hábito, e o Block Public
Access da lição 4 continua ligado por baixo de tudo.
