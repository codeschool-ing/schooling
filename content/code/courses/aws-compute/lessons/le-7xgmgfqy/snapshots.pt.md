---
title: Snapshots, e por que o segundo sai barato
version: 1
---

Um snapshot parece uma cópia de um disco, e a cópia de um disco de 100 GB parece mais 100 GB para
pagar cada vez que você tira uma. **Um snapshot guarda os blocos que mudaram desde o snapshot
anterior**, e mais nada. O primeiro snapshot de um volume guarda todo bloco que já foi escrito; cada
um depois dele guarda só o que é novo, e aponta para os blocos antigos de que ainda precisa.

## Tirando dois

Um volume de 100 GB, e dois snapshots dele com um dia de diferença:

```
ana@laptop:~/aws$ VOL=$(aws ec2 create-volume --availability-zone sa-east-1a --size 100 --volume-type gp3 --query VolumeId --output text)
ana@laptop:~/aws$ SNAP=$(aws ec2 create-snapshot --volume-id "$VOL" --description "orders, Monday" --query SnapshotId --output text)
ana@laptop:~/aws$ aws ec2 create-snapshot --volume-id "$VOL" --description "orders, Tuesday"
{
    "Tags": [],
    "StorageTier": "standard",
    "SnapshotId": "snap-a9866757c0726a8a2",
    "VolumeId": "vol-03bc20f80bd5f6780",
    "State": "completed",
    "StartTime": "2026-10-16T16:25:21+00:00",
    "Progress": "100%",
    "OwnerId": "123456789012",
    "Description": "orders, Tuesday",
    "VolumeSize": 100,
    "Encrypted": false
}
ana@laptop:~/aws$ aws ec2 describe-snapshots --filters Name=volume-id,Values="$VOL" --query "Snapshots[].[SnapshotId,VolumeSize,State,Description]" --output table
-------------------------------------------------------------------
|                        DescribeSnapshots                        |
+-------------------------+------+------------+-------------------+
|  snap-8c825a3b1a1702295 |  100 |  completed |  orders, Monday   |
|  snap-a9866757c0726a8a2 |  100 |  completed |  orders, Tuesday  |
+-------------------------+------+------------+-------------------+
```

O primeiro comando guarda o id do volume em `VOL` e o segundo guarda o id do snapshot de segunda em
`SNAP`, para que os comandos seguintes possam usar os dois; os seus ids vão ser outros. O moto
informa os dois snapshots como `completed` e `100%` no instante em que é chamado, e os dois mostram
`VolumeSize` 100.

Nenhum desses números é uma medição. `VolumeSize` é o tamanho do **volume** de onde o snapshot foi
tirado, não o que o snapshot guarda, e o moto não guarda bloco nenhum. Na AWS um snapshot começa
`pending` e chega a `completed` minutos ou horas depois, conforme quanto mudou; o volume continua
usável o tempo todo, porque o snapshot é do momento em que foi pedido. O que ele guarda nunca
aparece no `describe-snapshots`. **A AWS cobra por isso, e é aí que você vê.**

```schooling-figure
{"svg": "<svg id=\"fig-incremental\" viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Três linhas de oito blocos de um volume. O snapshot de segunda guarda os seis blocos escritos até então; dois nunca foram escritos e não são guardados. O snapshot de terça guarda só os dois blocos que mudaram e se refere ao de segunda para os outros quatro. Depois que o snapshot de segunda é apagado, o de terça fica com os quatro blocos de que precisava e continua inteiro.\"><defs><marker id=\"incremental-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"24\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">segunda</text><rect x=\"160\" y=\"26\" width=\"40\" height=\"36\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"206\" y=\"26\" width=\"40\" height=\"36\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"252\" y=\"26\" width=\"40\" height=\"36\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"298\" y=\"26\" width=\"40\" height=\"36\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"344\" y=\"26\" width=\"40\" height=\"36\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"390\" y=\"26\" width=\"40\" height=\"36\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"436\" y=\"26\" width=\"40\" height=\"36\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"482\" y=\"26\" width=\"40\" height=\"36\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"536\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">guarda 6 blocos</text><text x=\"24\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">terça</text><rect x=\"160\" y=\"84\" width=\"40\" height=\"36\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"></rect><rect x=\"206\" y=\"84\" width=\"40\" height=\"36\" rx=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"252\" y=\"84\" width=\"40\" height=\"36\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"></rect><rect x=\"298\" y=\"84\" width=\"40\" height=\"36\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"></rect><rect x=\"344\" y=\"84\" width=\"40\" height=\"36\" rx=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"390\" y=\"84\" width=\"40\" height=\"36\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"></rect><rect x=\"436\" y=\"84\" width=\"40\" height=\"36\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"482\" y=\"84\" width=\"40\" height=\"36\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"536\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">guarda 2, aponta 4</text><text x=\"24\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">terça, sem segunda</text><rect x=\"160\" y=\"142\" width=\"40\" height=\"36\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"206\" y=\"142\" width=\"40\" height=\"36\" rx=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"252\" y=\"142\" width=\"40\" height=\"36\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"298\" y=\"142\" width=\"40\" height=\"36\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"344\" y=\"142\" width=\"40\" height=\"36\" rx=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"390\" y=\"142\" width=\"40\" height=\"36\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"436\" y=\"142\" width=\"40\" height=\"36\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"482\" y=\"142\" width=\"40\" height=\"36\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"536\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">fica com os 4 que usava</text><rect x=\"24\" y=\"210\" width=\"18\" height=\"18\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"50\" y=\"219\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">guardado neste snapshot</text><rect x=\"200\" y=\"210\" width=\"18\" height=\"18\" rx=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"226\" y=\"219\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">mudou desde o anterior</text><rect x=\"384\" y=\"210\" width=\"18\" height=\"18\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"></rect><text x=\"410\" y=\"219\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">achado num mais antigo</text><rect x=\"556\" y=\"210\" width=\"18\" height=\"18\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"582\" y=\"219\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nunca escrito</text></svg>", "caption": "Um snapshot guarda o que mudou desde o anterior. Apagar um snapshot mais antigo libera só os blocos para os quais nada posterior ainda aponta."}
```

A figura é a parte que o moto não consegue mostrar. O snapshot de segunda guarda os seis blocos que
tinham sido escritos. O de terça guarda os dois que mudaram desde então, e se refere ao de segunda
para os outros quatro. **Apague o de segunda, e o de terça continua inteiro**: a AWS mantém os
blocos de que um snapshot posterior ainda precisa, e libera só aqueles para os quais nada aponta.
Você pode portanto apagar qualquer snapshot de uma cadeia sem quebrar os outros, e a conta só cai
pelo que era exclusivo dele.

## Quanto custa

A tabela de preços de 16 de outubro de 2026 diz 0,068 USD por GB-mês para um snapshot em
`sa-east-1`, sobre o que o snapshot guarda. Pegue o volume acima, com 60 GB dele escritos, e um
snapshot por noite guardado por 30 dias, com 3 GB mudando a cada dia:

| | guardado | por mês |
|---|---|---|
| o primeiro snapshot | 60 GB | 4,08 USD |
| mais 29, de 3 GB cada | 87 GB | 5,92 USD |
| os 30 | 147 GB | 10,00 USD |

Trinta cópias completas teriam sido 1.800 GB e 122,40 USD. **Blocos vazios nunca são guardados**,
então o primeiro snapshot custa o que foi escrito, não o tamanho do volume. E o número que cresce é
a taxa de mudança: um banco que reescreve 30 GB por noite é uma conta diferente do disco raiz de um
servidor web, que muda alguns megabytes.

## Restaurando um

Um snapshot volta a ser útil como um volume novo, e **um snapshot pertence à região, não a uma
zona**:

```
ana@laptop:~/aws$ aws ec2 create-volume --availability-zone sa-east-1c --snapshot-id "$SNAP" --volume-type gp3 --query "[VolumeId,AvailabilityZone,Size,SnapshotId]" --output text
vol-097c5b072b0ebbc79	sa-east-1c	100	snap-8c825a3b1a1702295
```

O volume foi tirado em `sa-east-1a` e o novo foi criado em `sa-east-1c`. Esse é o jeito normal de
mudar um volume de zona, de que a lição 3 precisa, já que um volume em si nunca sai da zona em que
foi criado.

O segundo comando é o moto sendo tolerante de novo:

```
ana@laptop:~/aws$ aws ec2 create-volume --availability-zone sa-east-1a --snapshot-id "$SNAP" --size 50 --volume-type gp3 --query "[VolumeId,Size]" --output text
vol-646726d597c884e30	50
```

Ele criou um volume de 50 GB a partir de um snapshot de 100 GB. **A AWS recusa isso**: um volume
feito de um snapshot precisa ter pelo menos o tamanho do volume do snapshot, e pode ser maior, e
depois disso o sistema de arquivos lá dentro precisa ser aumentado para usar o espaço extra.
Diminuir se faz dentro do sistema operacional, copiando os arquivos para um volume menor.

Mais um comportamento da AWS que o moto não tem como mostrar. Um volume restaurado é usável na hora,
mas **os blocos dele chegam do snapshot na primeira vez que cada um é lido**, então a primeira
passada num disco de banco restaurado é bem mais lenta que a segunda. Ler cada bloco uma vez depois
de restaurar o aquece; a AWS também vende o Fast Snapshot Restore, que tira essa demora para
snapshots escolhidos em zonas escolhidas, a um preço por hora que não está na tabela.

## O que um snapshot não garante

Um snapshot é dos **blocos**, num instante, e não sabe nada dos arquivos acima deles. Para um disco
que é quase só lido, como um volume raiz, tudo bem. Para um banco no meio de uma escrita, é o estado
em que o disco estaria depois de uma queda de energia: o banco vai se recuperar, como faz depois de
um crash, mas o que estava na memória e não tinha sido gravado não está no snapshot. Tirar um
consistente significa perguntar à aplicação primeiro: descarregar e congelar o sistema de arquivos,
usar o backup do próprio banco, ou parar a instância. A imagem da próxima seção é feita do jeito
seguro por padrão, reiniciando a instância antes.
