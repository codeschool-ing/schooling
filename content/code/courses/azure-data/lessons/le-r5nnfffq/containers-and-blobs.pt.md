---
title: Contêineres, blobs e as pastas que não estão lá
version: 1
---

**Um contêiner é um grupo de blobs com nome, dentro de uma conta de armazenamento, e um blob é um
nome e os bytes guardados nele.** Esse é o modelo de dados inteiro do Blob Storage. Não há diretórios
dentro de um contêiner nem contêineres dentro de um contêiner. As barras que as pessoas põem nos
nomes dos blobs parecem um sistema de arquivos, e o portal e todo explorador de armazenamento
desenham pastas a partir delas, mas por baixo há uma lista plana de nomes por contêiner, em ordem. A
lição 3 trata da única chave que muda isso, e esta lição trata do espaço de nomes plano que toda
conta tem por padrão.

Esta lição precisa só do Azurite, ligado vazio com `docker compose up -d` em `~/azure`, e das quatro
linhas de "Toda vez que abrir um terminal" da lição 1 digitadas no terminal que você usa. As outras
lições de armazenamento, até a lição 7, começam do mesmo jeito. A loja da Quitanda exporta um CSV por
noite; crie três pequenos, para os três últimos dias de outubro:

```sh
mkdir -p export
for d in 27 28 29; do
  printf 'order_id,customer_id,total_cents\n%s-1,c-17,4590\n%s-2,c-03,12800\n' "$d" "$d" \
    > export/orders-2026-10-$d.csv
done
```

Depois crie um contêiner e ponha os três arquivos nele, cada um com um nome que começa com
`exports/2026/10/`:

```
ana@laptop:~/azure$ az storage container create -n orders-raw
{
  "created": true
}
ana@laptop:~/azure$ az storage blob upload-batch -d orders-raw -s export --destination-path exports/2026/10 --no-progress -o none
ana@laptop:~/azure$ az storage blob list -c orders-raw --query "[].name" -o tsv
exports/2026/10/orders-2026-10-27.csv
exports/2026/10/orders-2026-10-28.csv
exports/2026/10/orders-2026-10-29.csv
```

O `upload-batch` mandou uma requisição por arquivo, e o nome de cada blob é a string inteira depois do
nome do contêiner, com barras e tudo. `--no-progress` e `-o none` só deixam a transcrição curta: sem
eles o comando desenha uma barra de progresso e imprime uma linha por arquivo.

## Listar é pedir um prefixo

```
ana@laptop:~/azure$ az storage blob list -c orders-raw --query "[].name" -o tsv --delimiter /
exports/
ana@laptop:~/azure$ az storage blob list -c orders-raw --query "[].name" -o tsv --delimiter / --prefix exports/2026/
exports/2026/10/
ana@laptop:~/azure$ az storage blob show -c orders-raw -n exports/2026/ 2>&1 | tail -1
ErrorCode:BlobNotFound
ana@laptop:~/azure$ az storage blob exists -c orders-raw -n EXPORTS/2026/10/orders-2026-10-27.csv
{
  "exists": false
}
```

**A segunda listagem mostra um `exports/` que ninguém criou.** Com `--delimiter /`, o Blob Storage
agrupa cada nome na primeira barra e responde com uma entrada por grupo, que a biblioteca chama de
`BlobPrefix`. Acrescente `--prefix exports/2026/` e ele filtra primeiro e depois agrupa na barra
seguinte ao prefixo. Uma pasta é só isso: **a resposta a uma pergunta de listagem, e ela só existe
enquanto algum nome de blob começar com ela.** Apague os três blobs e `exports/` some junto, sem nada
para apagar por conta própria.

Por isso pedir a pasta como blob falha: esse blob não existe. E o último comando mostra a outra
metade do mesmo fato: os nomes são comparados byte a byte, então `EXPORTS/` é um prefixo diferente de
`exports/`, e nada mora debaixo dele.

A documentação da Microsoft traz os limites que importam aqui. Um nome de blob pode ter até 1.024
caracteres, diferencia maiúsculas de minúsculas, e um contêiner pode guardar um número ilimitado de
blobs. O nome é o único índice que o Blob Storage mantém: uma listagem percorre os nomes em ordem,
então um desenho que põe a data cedo no nome, como `exports/2026/10/` faz, deixa um programa pedir um
mês sem ler os nomes de todos os outros meses.

## Três tipos de blob, escolhidos uma vez

**Todo blob tem um tipo, definido quando ele é criado e nunca mais trocado.** Os três arquivos acima
são block blobs, que é o que todo upload cria quando não pede outra coisa. O tipo decide que
operações o blob aceita:

| tipo | como é escrito | para que serve |
|---|---|---|
| block blob | blocos preparados, depois confirmados como lista | arquivos: exportações, Parquet, imagens, backups |
| append blob | blocos acrescentados no fim, nunca alterados | logs escritos uma linha por vez |
| page blob | páginas de 512 bytes escritas em qualquer deslocamento | discos de máquinas virtuais |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Os três tipos de blob lado a lado. Um block blob: os blocos B0, B1 e B2 são preparados, depois um commit os nomeia em ordem, e só então o blob pode ser lido. Um append blob: as linhas 1 a 3 estão gravadas, e o próximo append só pode entrar depois delas. Um page blob: uma grade de páginas de 512 bytes em que três foram escritas e as outras são lidas como zeros.\" data-fig=\"l02-types\"><defs><marker id=\"l02-types-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,4 L0,8 z\" fill=\"var(--wire)\"/></marker></defs><rect x=\"20\" y=\"20\" width=\"200\" height=\"210\" rx=\"5\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"/><text x=\"120\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">block blob</text><text x=\"120\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">preparados, depois o commit</text><rect x=\"260\" y=\"20\" width=\"200\" height=\"210\" rx=\"5\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"/><text x=\"360\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">append blob</text><text x=\"360\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">só acrescentados no fim</text><rect x=\"500\" y=\"20\" width=\"200\" height=\"210\" rx=\"5\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"/><text x=\"600\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">page blob</text><text x=\"600\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">qualquer página de 512 bytes</text><text x=\"34\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">preparados</text><rect x=\"34\" y=\"96\" width=\"46\" height=\"26\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"/><text x=\"57\" y=\"109\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">B0</text><rect x=\"92\" y=\"96\" width=\"46\" height=\"26\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"/><text x=\"115\" y=\"109\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">B1</text><rect x=\"150\" y=\"96\" width=\"46\" height=\"26\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"/><text x=\"173\" y=\"109\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">B2</text><line x1=\"120\" y1=\"128\" x2=\"120\" y2=\"150\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l02-types-ah)\"/><text x=\"34\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">commit [B0, B1, B2]</text><rect x=\"34\" y=\"174\" width=\"46\" height=\"26\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"57\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">B0</text><rect x=\"92\" y=\"174\" width=\"46\" height=\"26\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"115\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">B1</text><rect x=\"150\" y=\"174\" width=\"46\" height=\"26\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"173\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">B2</text><text x=\"120\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">legível só depois do commit</text><rect x=\"290\" y=\"84\" width=\"140\" height=\"24\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"360\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">linha 1</text><rect x=\"290\" y=\"114\" width=\"140\" height=\"24\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"360\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">linha 2</text><rect x=\"290\" y=\"144\" width=\"140\" height=\"24\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"360\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">linha 3</text><rect x=\"290\" y=\"174\" width=\"140\" height=\"24\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"/><text x=\"360\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">linha 4</text><text x=\"360\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">o próximo append entra aqui</text><rect x=\"522\" y=\"84\" width=\"36\" height=\"24\" rx=\"5\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"/><rect x=\"562\" y=\"84\" width=\"36\" height=\"24\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><rect x=\"602\" y=\"84\" width=\"36\" height=\"24\" rx=\"5\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"/><rect x=\"642\" y=\"84\" width=\"36\" height=\"24\" rx=\"5\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"/><rect x=\"522\" y=\"114\" width=\"36\" height=\"24\" rx=\"5\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"/><rect x=\"562\" y=\"114\" width=\"36\" height=\"24\" rx=\"5\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"/><rect x=\"602\" y=\"114\" width=\"36\" height=\"24\" rx=\"5\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"/><rect x=\"642\" y=\"114\" width=\"36\" height=\"24\" rx=\"5\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"/><rect x=\"522\" y=\"144\" width=\"36\" height=\"24\" rx=\"5\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"/><rect x=\"562\" y=\"144\" width=\"36\" height=\"24\" rx=\"5\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"/><rect x=\"602\" y=\"144\" width=\"36\" height=\"24\" rx=\"5\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"/><rect x=\"642\" y=\"144\" width=\"36\" height=\"24\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><rect x=\"522\" y=\"174\" width=\"36\" height=\"24\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><rect x=\"562\" y=\"174\" width=\"36\" height=\"24\" rx=\"5\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"/><rect x=\"602\" y=\"174\" width=\"36\" height=\"24\" rx=\"5\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"/><rect x=\"642\" y=\"174\" width=\"36\" height=\"24\" rx=\"5\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"/><text x=\"600\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">só as páginas escritas; o resto é zero</text></svg>", "caption": "O tipo é escolhido quando o blob é criado e decide que escritas ele vai aceitar para sempre."}
```

As duas próximas seções tratam de cada tipo. Quase tudo o que uma plataforma de dados guarda é block
blob, e ele é o único tipo que aceita os tiers hot, cool, cold e archive da lição 4. Os outros dois
valem ser conhecidos principalmente para reconhecer um erro que fala do tipo de blob errado quando ele
aparecer.
