---
title: Block blobs: preparados, depois confirmados
version: 1
---

**Um block blob é uma lista de blocos, e ele só muda quando uma lista nova é confirmada com um
commit.** As pessoas imaginam um upload como bytes entrando num arquivo que cresce até a transferência
acabar. O Blob Storage não funciona assim. O cliente manda blocos, cada um com um id, e eles ficam ao
lado do blob, preparados e invisíveis. Depois mais uma requisição, o commit, nomeia os blocos em ordem,
e naquele instante o blob passa a ser aquela lista. Um leitor vê o blob antigo ou o novo, nunca a
metade de um deles.

O programa abaixo grava a exportação de 30 de outubro em três blocos, uma linha cada, e pergunta ao
serviço o que ele guarda entre um passo e outro:

```schooling-example
{"language": "python", "file": "blocks.py", "parts": [{"code": "import base64\nfrom azure.storage.blob import BlobServiceClient, BlobBlock\n\nservice = BlobServiceClient.from_connection_string(\"UseDevelopmentStorage=true\")\nblob = service.get_blob_client(\"orders-raw\", \"exports/2026/10/orders-2026-10-30.csv\")\n\n\ndef block_id(n):\n    return base64.b64encode(f\"{n:06d}\".encode()).decode()\n", "note": "A cadeia de conexão é a mesma que todo terminal exporta, escrita por extenso para o programa não depender de mais nada. O id de um bloco é qualquer texto de até 64 bytes, em base64, e todos os ids de um blob precisam ter o mesmo tamanho; por isso o número é completado até seis dígitos."}, {"code": "\n\nparts = [b\"order_id,customer_id,total_cents\\n\", b\"30-1,c-17,4590\\n\", b\"30-2,c-03,12800\\n\"]\nfor n, data in enumerate(parts):\n    blob.stage_block(block_id(n), data)\ncommitted, uncommitted = blob.get_block_list(\"all\")\nprint(\"staged:\", len(committed), \"committed,\", len(uncommitted), \"uncommitted\")\nprint(\"exists before the commit:\", blob.exists())\n", "note": "Três blocos são preparados, uma requisição cada. Um upload de verdade prepara blocos de megabytes, vários ao mesmo tempo, de várias threads; estes têm uma linha de CSV cada, para a saída caber na tela."}, {"code": "\nblob.commit_block_list([BlobBlock(block_id=block_id(n)) for n in range(3)])\ncommitted, uncommitted = blob.get_block_list(\"all\")\nprint(\"after the commit:\", [b.id for b in committed], len(uncommitted), \"uncommitted\")\nprint(blob.download_blob().readall().decode(), end=\"\")\n", "note": "O commit é uma requisição só, que nomeia os blocos na ordem em que o blob deve guardá-los. Só agora o blob existe, e inteiro de uma vez."}, {"code": "\nblob.stage_block(block_id(2), b\"30-2,c-03,12900\\n\")\nblob.commit_block_list([BlobBlock(block_id=block_id(n)) for n in range(3)])\nprint(blob.download_blob().readall().decode(), end=\"\")\n", "note": "Preparar um bloco com um id que o blob já usa e fazer o commit da mesma lista de novo troca aquele bloco e mantém os outros dois. Os dois primeiros blocos não foram enviados outra vez."}], "output": "staged: 0 committed, 3 uncommitted\nexists before the commit: False\nafter the commit: ['MDAwMDAw', 'MDAwMDAx', 'MDAwMDAy'] 0 uncommitted\norder_id,customer_id,total_cents\n30-1,c-17,4590\n30-2,c-03,12800\norder_id,customer_id,total_cents\n30-1,c-17,4590\n30-2,c-03,12900\n"}
```

Rode com `python blocks.py`. A saída está embaixo do programa: **antes do commit, o blob não existe**,
embora três blocos já estejam guardados para ele. Depois do commit a lista de blocos tem três
confirmados e nenhum pendente, e o CSV volta inteiro. A última parte mudou um total de 12800 para
12900 mandando dezesseis bytes; o cabeçalho e o primeiro pedido ficaram onde estavam.

É isso que torna um block blob seguro para a exportação noturna. Um job que cai no meio de um upload
grande deixa blocos preparados e um blob intocado, então quem lê `orders-2026-10-30.csv` na manhã
seguinte lê a última versão completa ou nada. A documentação da Microsoft diz que blocos preparados e
nunca confirmados são descartados depois de uma semana, então um upload que falhou custa armazenamento
só por esse tempo.

## A biblioteca corta o arquivo por você

Ninguém escreve `stage_block` para um upload comum. A biblioteca Python e a linha de comando decidem
sozinhas: um arquivo abaixo de um limite sobe numa requisição só, e um maior é cortado em blocos,
preparados vários de cada vez e confirmados no fim. Os dois limites são configurações do cliente:

`split.py`:

```python
from azure.storage.blob import BlobServiceClient

rows = b"".join(f"{i},c-{i % 97:02d},{i * 37 % 20000}\n".encode() for i in range(40000))
print(len(rows), "bytes")

default = BlobServiceClient.from_connection_string("UseDevelopmentStorage=true")
print("defaults:", default._config.max_single_put_size, default._config.max_block_size)

small = BlobServiceClient.from_connection_string(
    "UseDevelopmentStorage=true", max_single_put_size=256 * 1024, max_block_size=256 * 1024)
blob = small.get_blob_client("orders-raw", "exports/2026/10/big.csv")
blob.upload_blob(rows, overwrite=True)
committed, _ = blob.get_block_list("committed")
print(len(committed), "blocks:", [b.size for b in committed])
```

```
ana@laptop:~/azure$ python split.py
646670 bytes
defaults: 67108864 4194304
3 blocks: [262144, 262144, 122382]
```

Os padrões da biblioteca, impressos na segunda linha, são uma requisição só até 64 MiB e blocos de
4 MiB acima disso. `_config` é um atributo privado, lido aqui só para imprimir os números; o jeito
suportado de mudá-los são os dois argumentos que o programa passa. Com 256 KiB para os dois, os
646.670 bytes subiram como dois blocos cheios de 262.144 bytes e um último com o resto.

**Os limites documentados** de um block blob, da página da Microsoft sobre block, append e page blobs:
até 50.000 blocos confirmados, cada um com até 4.000 MiB, o que põe o maior blob em cerca de
190,7 TiB. Nada disso dá para alcançar no laboratório nem vale tentar. O que vale saber é o primeiro
número: um programa que envia um arquivo de 300 GB em blocos de 4 MiB precisa de 76.800 blocos, mais
do que um blob pode ter, e falha no commit. Um programa que move arquivos desse tamanho usa um bloco
maior, e um programa que reduz `max_block_size` para um teste não deve levar essa configuração para
produção.
