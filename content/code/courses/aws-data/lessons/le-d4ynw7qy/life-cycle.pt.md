---
title: Regras de ciclo de vida, e o relógio que o moto não tem
version: 1
---

**Uma configuração de ciclo de vida é uma lista de regras que o S3 aplica aos objetos de um bucket
conforme eles envelhecem**: passá-los para uma classe mais barata depois de tantos dias, apagá-los
depois de tantos outros, apagar versões não atuais, limpar uploads que começaram e nunca terminaram. É
o único lugar em que o S3 trabalha sozinho, sem requisição sua, e é justamente a parte que o moto não
consegue imitar.

Uma regra tem um filtro, que diz a quais objetos ela se aplica, e uma ou mais ações:

| ação | o que faz |
|---|---|
| `Transitions` | passa versões atuais para outra classe depois de um número de dias desde que foram escritas |
| `Expiration` | apaga versões atuais depois de um número de dias; num bucket versionado, põe um marcador de exclusão |
| `NoncurrentVersionTransitions` | passa versões não atuais de classe, contando do dia em que foram substituídas |
| `NoncurrentVersionExpiration` | apaga versões não atuais de vez, podendo guardar as mais novas |
| `AbortIncompleteMultipartUpload` | remove as partes de um upload começado há tantos dias e nunca concluído |

O filtro é um prefixo, uma tag, uma faixa de tamanho de objeto, ou vários desses juntos com `And`. Uma
regra com filtro vazio vale para o bucket inteiro.

## As regras da Quitanda

O bucket bruto guarda as exportações noturnas da lição 1 sob `raw/orders/`. Os analistas leem muito o
último mês, raramente o último ano, e nada mais antigo a não ser para uma auditoria. Escreva isso como
regras, num arquivo:

`lifecycle.json`:

```json
{
  "Rules": [
    {
      "ID": "orders-age-out",
      "Status": "Enabled",
      "Filter": {"Prefix": "raw/orders/"},
      "Transitions": [
        {"Days": 30, "StorageClass": "STANDARD_IA"},
        {"Days": 365, "StorageClass": "DEEP_ARCHIVE"}
      ],
      "Expiration": {"Days": 2555}
    },
    {
      "ID": "scratch-goes-in-a-week",
      "Status": "Enabled",
      "Filter": {"And": {"Prefix": "raw/", "Tags": [{"Key": "kind", "Value": "scratch"}]}},
      "Expiration": {"Days": 7}
    },
    {
      "ID": "tidy-the-bucket",
      "Status": "Enabled",
      "Filter": {},
      "NoncurrentVersionExpiration": {"NoncurrentDays": 7},
      "AbortIncompleteMultipartUpload": {"DaysAfterInitiation": 3}
    }
  ]
}
```

**Uma exportação fica em Standard no primeiro mês, em Standard-IA até fazer um ano, em Deep Archive
por mais seis anos, e depois some**, já que 2.555 dias são sete anos. Um objeto com a tag
`kind=scratch` sob `raw/` vive uma semana. E em qualquer lugar do bucket, uma versão substituída vive
sete dias e um upload multipart deixado pela metade é limpo depois de três.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 222\" role=\"img\" aria-label=\"A regra orders-age-out numa linha do tempo de dias, em escala de raiz quadrada. Do dia 0 ao 30, Standard a 0,0405 por GB-mês; do 30 ao 365, Standard-IA a 0,0221; do 365 ao 2.555, Deep Archive a 0,0032; no dia 2.555 o objeto é apagado. Um GB custa 0,52 USD pela vida inteira com a regra, contra 3,45 USD se ficasse sempre em Standard.\" data-fig=\"l03-lifeline\"><defs><marker id=\"lc-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"40.0\" y=\"70.0\" width=\"69.3\" height=\"40.0\" rx=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"74.7\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--ink)\" font-weight=\"600\">Standard</text><text x=\"74.7\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">0,0405 por GB-mês</text><rect x=\"109.3\" y=\"70.0\" width=\"172.5\" height=\"40.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"195.6\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Standard-IA</text><text x=\"195.6\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">0,0221 por GB-mês</text><rect x=\"281.9\" y=\"70.0\" width=\"398.1\" height=\"40.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"480.9\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Deep Archive</text><text x=\"480.9\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">0,0032 por GB-mês</text><path d=\"M40.0 60.0 L40.0 116.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"40.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0</text><path d=\"M109.3 60.0 L109.3 116.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"109.3\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">30</text><path d=\"M281.9 60.0 L281.9 116.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"281.9\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">365</text><path d=\"M680.0 60.0 L680.0 116.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"680.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2.555</text><text x=\"680.0\" y=\"158.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">apagado</text><text x=\"40.0\" y=\"24.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" font-weight=\"600\">dias desde que o objeto foi escrito</text><text x=\"40.0\" y=\"186.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">um GB pela vida toda, sete anos:</text><text x=\"40.0\" y=\"206.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">com a regra 0,52 USD; só em Standard 3,45 USD</text></svg>", "caption": "A vida de uma exportação sob a regra. A escala é a raiz quadrada dos dias, para que o primeiro mês não suma ao lado dos sete anos.", "same": ["Standard", "Standard-IA", "Deep Archive"]}
```

**Ao longo dos sete anos, um gigabyte sob a primeira regra custa cerca de 0,52 USD**, contra 3,45 se
tivesse ficado em Standard, aos preços da lição 2. Um mês tem 30 dias: Standard por 30 dias dá
30 / 30 × 0,0405 = 0,0405, Standard-IA por 335 dias dá 335 / 30 × 0,0221 = 0,2468, Deep Archive por
2.190 dias dá 2.190 / 30 × 0,0032 = 0,2336, juntos 0,5209. Standard pelos 2.555 dias daria
2.555 / 30 × 0,0405 = 3,449. Aplique o arquivo e leia de volta:

```
ana@laptop:~/aws$ aws s3 mb s3://quitanda-raw-prod
make_bucket: quitanda-raw-prod
ana@laptop:~/aws$ aws s3api put-bucket-lifecycle-configuration --bucket quitanda-raw-prod --lifecycle-configuration file://lifecycle.json
ana@laptop:~/aws$ aws s3api get-bucket-lifecycle-configuration --bucket quitanda-raw-prod --query '[TransitionDefaultMinimumObjectSize, Rules[].ID]'
[
    "all_storage_classes_128K",
    [
        "orders-age-out",
        "scratch-goes-in-a-week",
        "tidy-the-bucket"
    ]
]
```

**O `TransitionDefaultMinimumObjectSize` foi acrescentado pelo S3, não pelo arquivo**: o valor dele,
`all_storage_classes_128K`, quer dizer que objetos menores que 128 KB não mudam de classe de jeito
nenhum, a menos que a configuração diga o contrário. Esse é o padrão da AWS desde 2024, e é a regra dos
128 KB da lição anterior aplicada sem você pedir: uma exportação de 10 KB passada para Standard-IA seria
cobrada como 128 KB, então o S3 a deixa onde está.

O upload inacabado merece a regra porque é invisível. Um upload multipart manda um arquivo grande em
partes e as junta no fim; se o programa morre antes do fim, as partes ficam, são cobradas, e não
aparecem em listagem de objetos nenhuma. Só aparecem em `list-multipart-uploads`.

## O que o moto faz com as regras

**O moto guarda a configuração e nunca a aplica.** Não há no moto um relógio que envelheça um objeto;
nada acontece nele entre duas requisições. O teste mais simples é uma regra que deveria agir na hora.
Um `put-bucket-lifecycle-configuration` substitui a configuração inteira, então este toma o lugar das
três regras da Quitanda:

```
ana@laptop:~/aws$ aws s3api put-bucket-lifecycle-configuration --bucket quitanda-raw-prod --lifecycle-configuration '{"Rules":[{"ID":"at-once","Status":"Enabled","Filter":{"Prefix":"now/"},"Transitions":[{"Days":0,"StorageClass":"GLACIER"}],"Expiration":{"Days":1}}]}'
ana@laptop:~/aws$ head -c 200000 /dev/urandom > big.bin && aws s3 cp big.bin s3://quitanda-raw-prod/now/big.bin
upload: ./big.bin to s3://quitanda-raw-prod/now/big.bin           
ana@laptop:~/aws$ sleep 5; aws s3api head-object --bucket quitanda-raw-prod --key now/big.bin --query '{class: StorageClass, expiration: Expiration}'
{
    "class": null,
    "expiration": null
}
ana@laptop:~/aws$ aws s3api create-multipart-upload --bucket quitanda-raw-prod --key now/half.bin --query Key
"now/half.bin"
ana@laptop:~/aws$ aws s3api list-multipart-uploads --bucket quitanda-raw-prod --query 'Uploads[].[Key,Initiated]' --output text
now/half.bin	2010-11-10T20:48:33+00:00
ana@laptop:~/aws$ aws s3 ls s3://quitanda-raw-prod --recursive
2026-10-16 13:11:17     200000 now/big.bin
```

**O objeto continua `STANDARD`, e nenhuma data de expiração é anunciada.** Ele tem 200.000 bytes,
acima da linha dos 128 KB, então o padrão descrito acima não é o motivo. Na AWS, esta regra passaria
todo objeto novo sob `now/` para o Glacier Flexible Retrieval na execução seguinte, e o `head-object`
de uma chave coberta por uma regra de expiração traz um campo `Expiration` com o dia em que ela vai
embora. O moto não mostra nenhum dos dois. A data `Initiated` do upload inacabado, em 2010, é mais um
sinal de que o tempo no moto não é um tempo contra o qual algo é medido.

E o moto confere menos que o S3 quando a regra é escrita. A AWS recusa uma passagem para Standard-IA
ou One Zone-IA antes de 30 dias, porque um objeto precisa passar 30 dias em Standard primeiro:

```
ana@laptop:~/aws$ aws s3api put-bucket-lifecycle-configuration --bucket quitanda-raw-prod --lifecycle-configuration '{"Rules":[{"ID":"too-soon","Status":"Enabled","Filter":{"Prefix":"raw/"},"Transitions":[{"Days":10,"StorageClass":"STANDARD_IA"}]}]}'
ana@laptop:~/aws$ aws s3api get-bucket-lifecycle-configuration --bucket quitanda-raw-prod --query 'Rules[].Transitions'
[
    [
        {
            "Days": 10,
            "StorageClass": "STANDARD_IA"
        }
    ]
]
```

**Foi aceita.** Contra o S3 a mesma requisição falha, e o erro diz que os dias de uma passagem para
`STANDARD_IA` precisam ser pelo menos 30. O que uma regra de ciclo de vida faz ao longo de meses é
ensinado aqui pela documentação da AWS, e os arquivos de regras são conferidos por você: o moto só
confirma que eles são lidos.

Dois detalhes documentados completam o quadro. O S3 avalia as regras mais ou menos uma vez por dia,
então um objeto chega à classe nova algum tempo depois do dia em que se qualifica, não no minuto. E
uma passagem de classe é uma requisição por objeto, cobrada pela classe de destino, o que é mais um
motivo para o padrão dos 128 KB existir.
