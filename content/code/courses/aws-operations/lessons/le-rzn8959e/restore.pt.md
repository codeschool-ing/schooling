---
title: Restaurar o estado a partir do próprio histórico
version: 1
---

A lição 6 ligou o versionamento no bucket de estado para este momento. Apagar um objeto num bucket
versionado não remove os dados: o S3 põe um **marcador de exclusão** por cima, e cada versão anterior
fica embaixo, legível pelo id da versão. O histórico do estado:

```
ana@laptop:~/aws/tf7/shop$ aws s3api list-object-versions --bucket shop-tfstate-123456789012 --prefix shop/terraform.tfstate --query "Versions[?Key=='shop/terraform.tfstate'].[LastModified,Size,VersionId]" --output text
2026-10-16T16:22:24+00:00	2744	3fb9b69f-91e3-4c92-8f84-22496f481bf7
2026-10-16T16:22:17+00:00	8403	c4dbd1b7-7504-44eb-9998-c78c8316bc6d
ana@laptop:~/aws/tf7/shop$ aws s3api list-object-versions --bucket shop-tfstate-123456789012 --prefix shop/terraform.tfstate --query "DeleteMarkers[?Key=='shop/terraform.tfstate'].[LastModified,VersionId]" --output text
2026-10-16T16:22:18+00:00	cf8e5336-4d4d-4f79-ae3c-383c510bea59
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Uma linha do tempo de uma chave no bucket de estado. Primeiro uma versão de 8.403 bytes com quatro recursos. Depois um marcador de exclusão, o acidente. Depois uma versão de 2.744 bytes gravada pelo apply ruim, com um recurso. Por último, uma versão de 8.403 bytes, a restauração, agora a mais nova. Uma seta tracejada da primeira versão para a última tem o rótulo copy-object com o id da primeira versão como origem da cópia.\"><defs><marker id=\"ver-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">uma chave, shop/terraform.tfstate, e o histórico dela</text><path d=\"M30 200 L700 200\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"700\" y=\"216\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tempo</text><rect x=\"40\" y=\"120\" width=\"150\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"115.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">versão, 8.403 bytes</text><text x=\"115.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">quatro recursos</text><path d=\"M115 176 L115 200\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"205\" y=\"120\" width=\"150\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"280.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">marcador de exclusão</text><text x=\"280.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o acidente</text><path d=\"M280 176 L280 200\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"370\" y=\"120\" width=\"150\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"445.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">versão, 2.744 bytes</text><text x=\"445.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o apply ruim: um recurso</text><path d=\"M445 176 L445 200\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"535\" y=\"120\" width=\"150\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"610.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">versão, 8.403 bytes</text><text x=\"610.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a restauração, a mais nova</text><path d=\"M610 176 L610 200\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M115 118 L115 70 L610 70 L610 118\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#ver-ah)\"></path><text x=\"362\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">copy-object --copy-source ...?versionId=c4db...</text></svg>", "caption": "Nada no histórico é removido. A restauração é uma versão nova cujo conteúdo é uma antiga."}
```

Duas versões e um marcador de exclusão. Leia por tempo: a versão de 8.403 bytes é o estado com quatro
recursos, gravado pelo apply; o marcador veio um segundo depois; a versão de 2.744 bytes foi gravada
pelo apply ruim depois dele, e registra só o tópico. A versão a trazer de volta é a de antes do
marcador.

## Copiando a versão boa por cima

```
ana@laptop:~/aws/tf7/shop$ aws s3api copy-object --bucket shop-tfstate-123456789012 --key shop/terraform.tfstate --copy-source 'shop-tfstate-123456789012/shop/terraform.tfstate?versionId=c4dbd1b7-7504-44eb-9998-c78c8316bc6d' --query VersionId --output text
1691c2ba-3a9b-4346-89fc-61adcfbd6543
ana@laptop:~/aws/tf7/shop$ terraform plan -no-color | grep -E '^(No changes|Plan:)'
No changes. Your infrastructure matches the configuration.
ana@laptop:~/aws/tf7/shop$ terraform state list
aws_cloudwatch_log_group.web
aws_dynamodb_table.orders
aws_s3_bucket.uploads
aws_sns_topic.alerts
```

`copy-object` com um id de versão em `--copy-source` grava aquele conteúdo antigo como uma versão
**nova** e mais recente. Nada é destruído no processo: a versão ruim e o marcador ficam no histórico,
então a própria restauração pode ser desfeita. **No changes**, e quatro recursos no estado de novo, que é
a prova de que a restauração funcionou: o Terraform comparou a memória restaurada com a conta e
encontrou as duas de acordo.

Dois detalhes decidem se isso dá certo numa equipe de verdade:

- **pare todo mundo primeiro**: uma esteira que aplica entre o acidente e a restauração grava uma
  versão mais nova, como o apply ruim fez aqui, e a restauração precisa escolher a versão certa por
  tempo e por tamanho, nunca simplesmente "a anterior";
- **leia a versão antes de restaurá-la**: `aws s3api get-object --version-id ... restored.json` a
  baixa, e o `serial` e os `resources` dela mostram o que ela guarda.

## Uma cópia que não depende do bucket

O versionamento protege contra um objeto apagado. Não protege contra um bucket apagado, uma regra de
ciclo de vida errada que expira versões antigas, ou uma chave do KMS que ninguém consegue mais usar. A
segunda cópia mais barata é o próprio estado, puxado antes de qualquer operação arriscada:

```
ana@laptop:~/aws/tf7/shop$ terraform state pull > state-2026-10-16.json && wc -c state-2026-10-16.json
8404 state-2026-10-16.json
```

`terraform state pull` imprime o estado atual, seja qual for o backend que o guarda. **Guarde esse
arquivo com o mesmo cuidado que o bucket**: ele tem os mesmos segredos, então pertence a um
armazenamento cifrado, nunca ao repositório. `terraform state push` põe uma cópia de volta, e recusa
uma cujo serial seja mais antigo que o do estado que já está lá, a menos que forçado, que é a proteção
contra empurrar a cópia de ontem por cima do trabalho de hoje.
