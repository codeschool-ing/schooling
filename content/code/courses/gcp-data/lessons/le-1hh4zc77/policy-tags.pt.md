---
title: Policy tags: uma permissão numa coluna do BigQuery
version: 1
---

**Os pedidos curated da Quitanda levam o telefone do cliente, para o entregador, e as analistas que
precisam dos pedidos não têm nada a ver com os telefones.** O IAM na tabela não consegue dizer isso:
um papel numa tabela do BigQuery dá acesso a todas as colunas dela ou a nenhuma. Copiar a tabela sem a
coluna funciona e deixa duas tabelas para manter em sincronia. **Uma policy tag é uma permissão presa
a uma coluna**, e o BigQuery a confere em toda consulta, seja qual for a tabela ou view pela qual se
chega à coluna.

## Taxonomias, tags e o papel de leitura

**Uma taxonomia é uma árvore de policy tags, e cada tag é um rótulo para um tipo de dado.** A
Quitanda teria uma taxonomia, `personal-data`, com tags como `phone`, `email` e `tax-id`, aninhadas se
ajudar: um pai `contact` sobre `phone` e `email` permite que um acesso cubra os dois. A taxonomia mora
numa região, e governa colunas de tabelas da mesma região. As policy tags nasceram no Data Catalog, e
as taxonomias ainda são administradas pela API dele e por `gcloud data-catalog taxonomies`; até onde
esta aula sabe, a aposentadoria do Data Catalog deixou as policy tags onde estavam.

**Três passos tornam a coluna privada**, todos ensinados aqui a partir da documentação e nenhum
executado:

1. **Criar a taxonomia e suas tags**, e ligar o controle de acesso da taxonomia. Até o controle de
   acesso estar ligado, uma tag é um rótulo e não impõe nada.
2. **Prender a tag à coluna** no esquema da tabela. O campo do esquema ganha uma entrada `policyTags`
   nomeando a tag, como o `bq show --schema` a imprimiria:

```json
{
  "name": "phone",
  "type": "STRING",
  "policyTags": {
    "names": ["projects/planner-dev/locations/southamerica-east1/taxonomies/TAXONOMY_ID/policyTags/PHONE_TAG_ID"]
  }
}
```

3. **Dar o papel Fine-Grained Reader**, `roles/datacatalog.categoryFineGrainedReader`, na tag, às
   pessoas que podem ler a coluna: o time de entregas, não as analistas.

**A coluna então responde diferente conforme quem pergunta.** Uma analista que seleciona `phone`
recebe um erro de acesso, e a consulta falha em vez de devolver uma coluna em branco; uma consulta que
nomeia as outras colunas roda como antes, e o `SELECT * EXCEPT (phone)` também. Alguém do time de
entregas lê os números. A permissão acompanha a coluna em toda view construída sobre ela, porque o
BigQuery confere a tag na coluna de baixo, não na view.

## Mascaramento, quando a coluna ainda precisa servir

**Às vezes recusar é forte demais.** Uma analista que conta pedidos por cliente pelo telefone precisa
dos valores para agrupar, não para ler. O **mascaramento dinâmico de dados** prende uma **política de dados** à mesma policy tag.
Quem recebe o papel Masked Reader nela vê então um valor transformado em vez
de um erro: um hash SHA-256 do valor, que ainda agrupa e junta; um nulo; os quatro últimos
caracteres; ou um valor padrão do tipo da coluna. Os Fine-Grained Readers continuam vendo o número de
verdade, e todos os outros são recusados como antes. Um hash é determinístico, o que o torna útil para
juntar, e é também por isso que o hash de um telefone não é anônimo: qualquer pessoa pode aplicar o
hash a todo telefone de São Paulo e procurar o resultado.

## Onde isto fica entre o resto

**As policy tags são do BigQuery**, impostas pelo motor do BigQuery nas tabelas do BigQuery. Um
arquivo Parquet num bucket, sob uma tabela do BigLake, pode ser governado do mesmo jeito quando é lido
pelo BigQuery, que é um dos motivos que a aula 17 deu para o BigLake; lido direto com `gcloud storage
cat`, o arquivo responde ao IAM do bucket e a mais nada. **E o catálogo da seção anterior pode levar o
mesmo conhecimento como metadado**, um aspecto dizendo `contains_personal_data`, que avisa as pessoas.
Uma policy tag avisa o motor. A Quitanda precisa das duas coisas: o aspecto para que quem busca saiba
que os telefones estão lá, e a tag para que saber não lhe permita lê-los.

**Aplicar policy tags não custa nada na página do Dataplex**, que lista a aplicação e a propagação de
políticas de segurança entre os recursos gratuitos. O que uma consulta recusada custa é a tarde da
analista, então o trabalho está nos acessos, não na conta.
