---
title: Propriedades, metadados e o que o serviço preenche
version: 1
---

**Um blob carrega dois tipos de descrição além dos bytes: propriedades, que o serviço define, e
metadados, que você define.** As propriedades têm nomes e significados fixos: o tipo, o tamanho, o
tipo de conteúdo, o MD5 do conteúdo, o tier, o ETag, quando mudou pela última vez. Algumas são
preenchidas pelo serviço e outras por quem faz o upload. Metadados são um conjunto de pares de nome e
valor que o Blob Storage guarda e devolve sem nunca interpretar. Os dois voltam numa requisição que
não lê o conteúdo, que é o jeito barato de perguntar sobre um blob sem baixá-lo.

## Propriedades

```
ana@laptop:~/azure$ az storage blob show -c orders-raw -n exports/2026/10/orders-2026-10-27.csv --query "{type:properties.blobType, size:properties.contentLength, contentType:properties.contentSettings.contentType, contentMd5:properties.contentSettings.contentMd5, etag:properties.etag, blobTier:properties.blobTier}"
{
  "blobTier": "Hot",
  "contentMd5": "yqM8kXSyNguuY9wnjUCE8g==",
  "contentType": "text/csv",
  "etag": "\"0x216F28C5453D7E0\"",
  "size": 64,
  "type": "BlockBlob"
}
ana@laptop:~/azure$ openssl dgst -md5 -binary export/orders-2026-10-27.csv | base64
yqM8kXSyNguuY9wnjUCE8g==
```

A linha de comando preencheu duas delas sozinha. **`text/csv` veio da extensão do arquivo**, porque
`az storage blob upload` adivinha um tipo de conteúdo quando nenhum é informado, e um navegador ou um
motor de consulta que leia o blob depois confia nesse cabeçalho. **`contentMd5` é o MD5 dos bytes, em
base64**, e o segundo comando o calcula localmente com `openssl` para mostrar que os dois batem. Um
programa que baixa o blob pode calcular o mesmo hash e saber que os bytes chegaram inteiros.

**O ETag não é um hash.** É um carimbo de versão opaco, `0x` seguido de dígitos hexadecimais, que muda
toda vez que qualquer coisa no blob muda. Dois blobs com conteúdo idêntico têm ETags diferentes, e o
mesmo blob ganha um novo quando os metadados mudam, como o próximo bloco mostra. O único uso dele é o
da seção seguinte: perguntar se um blob ainda é a versão que você leu.

`blobTier` diz `Hot` porque o tier padrão da conta vale para um block blob que não recebeu um. A
lição 4 trata dessa propriedade.

## Metadados

```
ana@laptop:~/azure$ az storage blob show -c orders-raw -n exports/2026/10/orders-2026-10-27.csv --query properties.etag -o tsv
"0x216F28C5453D7E0"
ana@laptop:~/azure$ az storage blob metadata update -c orders-raw -n exports/2026/10/orders-2026-10-27.csv --metadata source=shop rows=2 -o none
ana@laptop:~/azure$ az storage blob metadata show -c orders-raw -n exports/2026/10/orders-2026-10-27.csv
{
  "rows": "2",
  "source": "shop"
}
ana@laptop:~/azure$ az storage blob show -c orders-raw -n exports/2026/10/orders-2026-10-27.csv --query properties.etag -o tsv
"0x23C540E60F62F00"
ana@laptop:~/azure$ az storage blob metadata update -c orders-raw -n exports/2026/10/orders-2026-10-27.csv --metadata rows=3 -o none
ana@laptop:~/azure$ az storage blob metadata show -c orders-raw -n exports/2026/10/orders-2026-10-27.csv
{
  "rows": "3"
}
ana@laptop:~/azure$ az storage blob metadata update -c orders-raw -n exports/2026/10/orders-2026-10-27.csv --metadata row-count=3 2>&1 | grep ErrorCode
ErrorCode:InvalidMetadata
```

Aconteceram quatro coisas, e as duas últimas surpreendem.

1. A primeira `metadata update` pendurou dois pares, `source=shop` e `rows=2`, e eles voltaram como
   foram escritos.
2. **O ETag mudou**, embora nem um byte do conteúdo tenha mudado. Quem guardava o ETag antigo agora
   guarda um vencido.
3. **A segunda atualização trocou o conjunto inteiro.** Ela disse `rows=3` e mais nada, então
   `source` sumiu. Não há operação que mude um par só: um programa que quer acrescentar um par lê os
   metadados, acrescenta e grava tudo de volta.
4. **Um nome com hífen foi recusado** com `InvalidMetadata`. Nomes de metadados precisam ser
   identificadores válidos de C#, uma regra que vem do jeito como eles viajam: cada par é um cabeçalho
   HTTP, `x-ms-meta-rows: 3`, e a regra mantém todo nome utilizável pelas bibliotecas de qualquer
   linguagem. Os nomes não diferenciam maiúsculas e os valores são texto.

A documentação da Microsoft limita os metadados de um blob a 8 KB, nomes e valores somados. Dá de
sobra para alguns rótulos, como o sistema de origem ou a contagem de linhas, e descarta usar metadados
como um banco de dados pequeno.

**Metadados não podem ser pesquisados.** O único jeito de achar todo blob cujo `source` é `shop` é
listar o contêiner e ler os metadados de cada blob, uma requisição por blob. O Azure tem um recurso
separado para essa pergunta, as blob index tags, que o serviço indexa; elas não são usadas neste curso,
e nada aqui foi rodado contra elas. Num lake, a resposta de costume é mais simples: ponha no nome
aquilo por que você vai procurar, como `exports/2026/10/` já faz com a data, porque o nome é a única
coisa que uma listagem filtra.
