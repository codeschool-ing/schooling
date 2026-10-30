---
title: ETags e a escrita que confere antes
version: 1
---

**Por padrão a última escrita vence, em silêncio.** Dois programas que escrevem o mesmo blob com um
segundo de diferença passam os dois, e o blob fica com o que o segundo mandou. Nada registra que a
primeira escrita aconteceu. Isso serve para uma exportação escrita uma vez por noite por um job só, e
está errado para qualquer coisa que dois escritores compartilham: um marcador que diz onde o job
noturno parou, um arquivo pequeno de configuração, um manifesto que lista os arquivos de uma tabela. O
conserto é fazer cada escrita dizer qual versão espera substituir e deixar o serviço recusá-la quando
o blob já mudou.

## A linha de comando pergunta antes de sobrescrever

`az storage blob upload` já recusa um caso sozinho:

```
ana@laptop:~/azure$ az storage blob upload -c orders-raw -n exports/2026/10/orders-2026-10-27.csv -f export/orders-2026-10-28.csv --no-progress 2>&1 | grep ErrorCode
ErrorCode:BlobAlreadyExists
ana@laptop:~/azure$ az storage blob upload -c orders-raw -n exports/2026/10/orders-2026-10-27.csv -f export/orders-2026-10-28.csv --overwrite --if-none-match "*" --no-progress 2>&1 | grep ErrorCode
ErrorCode:BlobAlreadyExists
ana@laptop:~/azure$ az storage blob upload -c orders-raw -n exports/2026/10/orders-2026-10-27.csv -f export/orders-2026-10-28.csv --overwrite --if-match "\"0x8D0000000000000\"" --no-progress 2>&1 | grep ErrorCode
ErrorCode:ConditionNotMet
ana@laptop:~/azure$ az storage blob upload -c orders-raw -n exports/2026/10/orders-2026-10-27.csv -f export/orders-2026-10-28.csv --overwrite --if-match "$(az storage blob show -c orders-raw -n exports/2026/10/orders-2026-10-27.csv --query properties.etag -o tsv)" --no-progress -o none && echo written
written
```

**Sem `--overwrite`, a linha de comando se recusa a trocar um blob que existe**, que é a mesma recusa
que `--if-none-match "*"` pede de forma explícita: escrever só se não houver nada lá. As bibliotecas
têm o mesmo padrão, e é por isso que todo programa desta lição passa `overwrite=True` quando quer
isso. O segundo par de comandos é a outra condição. `--if-match` carrega um ETag, a escrita só passa
se o blob ainda tiver esse ETag, e o inventado foi recusado com `ConditionNotMet`. O comando que
passou leu o ETag atual primeiro e o devolveu na hora, que é o padrão inteiro numa linha.

## Duas cópias do mesmo job

A história para a qual a condição existe: a exportação noturna da Quitanda mantém um blob marcador
que diz qual noite foi exportada por último. Numa noite a execução agendada está lenta, alguém
dispara uma repetição à mão, e as duas cópias leem o marcador antes de qualquer uma escrever.

```schooling-example
{"language": "python", "file": "etag.py", "parts": [{"code": "from azure.core import MatchConditions\nfrom azure.core.exceptions import ResourceModifiedError\nfrom azure.storage.blob import BlobServiceClient\n\nservice = BlobServiceClient.from_connection_string(\"UseDevelopmentStorage=true\")\nmarker = service.get_blob_client(\"orders-raw\", \"control/last-export.txt\")\nmarker.upload_blob(b\"2026-10-29\\n\", overwrite=True)\n", "note": "O marcador é um blob de uma linha que diz qual foi a última noite exportada. O job noturno o lê para saber de onde começar e o reescreve quando termina."}, {"code": "\nseen_by_a = marker.get_blob_properties().etag\nseen_by_b = marker.get_blob_properties().etag\nprint(\"both copies read\", seen_by_a)\n", "note": "Duas cópias do job, a execução agendada e uma repetição que alguém disparou à mão, leem o marcador com um segundo de diferença. Cada uma guarda o ETag que viu."}, {"code": "\nmarker.upload_blob(b\"2026-10-30\\n\", overwrite=True,\n                   etag=seen_by_a, match_condition=MatchConditions.IfNotModified)\nprint(\"A wrote, and the ETag is now\", marker.get_blob_properties().etag)\n", "note": "A cópia A escreve com a condição de que o blob ainda tenha o ETag que ela leu. Tem, então a escrita passa e o blob ganha um ETag novo."}, {"code": "\ntry:\n    marker.upload_blob(b\"2026-10-31\\n\", overwrite=True,\n                       etag=seen_by_b, match_condition=MatchConditions.IfNotModified)\nexcept ResourceModifiedError as refusal:\n    print(\"B was refused:\", refusal.status_code, refusal.error_code)\nprint(\"the marker says\", marker.download_blob().readall().decode(), end=\"\")\n", "note": "A cópia B manda a mesma condição com o ETag que leu antes de A escrever. O serviço compara, recusa com 412 e nada é gravado. Sem a condição, a escrita de B teria substituído a de A em silêncio."}], "output": "both copies read \"0x261450520A0CB40\"\nA wrote, and the ETag is now \"0x1F27705FF331080\"\nB was refused: 412 StorageErrorCode.CONDITION_NOT_MET\nthe marker says 2026-10-30\n"}
```

Rode com `python etag.py`; a saída está embaixo do programa.

**A cópia B foi recusada com 412, o status HTTP de pré-condição que falhou**, e `ConditionNotMet` é o
nome que o Blob Storage dá a ele, impresso pela biblioteca como `StorageErrorCode.CONDITION_NOT_MET`.
O marcador diz `2026-10-30`, que é o que a cópia A escreveu. Sem `etag=` e `match_condition=`, a
escrita da cópia B teria passado e o marcador diria `2026-10-31`, uma noite que não foi exportada. A
recusa não é um erro para repetir às cegas. Ela quer dizer *alguém mudou isto depois que você leu*, e
a resposta certa é ler de novo e decidir se a sua escrita ainda faz sentido. Isso se chama
concorrência otimista: nada fica travado, e a colisão rara é pega no momento da escrita.

## A trava, quando você precisa de uma

**Um lease é a versão pessimista: uma trava no blob, de quem a pegou.** Enquanto o lease está ativo,
uma escrita que não apresenta o id do lease é recusada, venha de quem vier:

```
ana@laptop:~/azure$ az storage blob lease acquire -c orders-raw -b control/last-export.txt --lease-duration 15 -o tsv | wc -c
37
ana@laptop:~/azure$ az storage blob upload -c orders-raw -n control/last-export.txt -f export/orders-2026-10-28.csv --overwrite --no-progress 2>&1 | grep ErrorCode
ErrorCode:LeaseIdMissing
```

`lease acquire` devolveu um id de lease, 36 caracteres mais a quebra de linha que o `wc -c` contou. O
upload sem ele foi recusado com `LeaseIdMissing`. Segundo a documentação da Microsoft, um lease dura de
15 a 60 segundos ou é infinito, e um finito precisa ser renovado antes de vencer. Um lease serve para
um job que precisa ser o único escritor por um bom tempo. Para um marcador lido e escrito num segundo,
a condição de ETag é mais simples, e nada fica travado quando um programa cai segurando a trava.
