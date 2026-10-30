---
title: Append blobs para logs, page blobs para discos
version: 1
---

**Um append blob aceita um único tipo de escrita: um bloco acrescentado no fim.** Nenhum bloco pode
ser trocado, reordenado ou removido depois, e cada append pode ser lido assim que é confirmado pelo
serviço, sem passo de commit. Esse é o formato de um log, e é para isso que existem os append blobs. O
serviço de checkout da Quitanda escreve uma linha para cada coisa que acontece com um carrinho, e o
programa abaixo guarda essas linhas num blob por dia:

`applog.py`:

```python
from azure.storage.blob import BlobServiceClient

service = BlobServiceClient.from_connection_string("UseDevelopmentStorage=true")
log = service.get_blob_client("app-logs", "checkout/2026-10-30.log")
if not service.get_container_client("app-logs").exists():
    service.create_container("app-logs")
if not log.exists():
    log.create_append_blob()

for event in ["cart c-17 opened", "cart c-17 paid 4590", "cart c-03 opened"]:
    answer = log.append_block(f"{event}\n".encode())
    print("appended at offset", answer["blob_append_offset"],
          "- blocks so far:", answer["blob_committed_block_count"])
print(log.download_blob().readall().decode(), end="")
```

Rode duas vezes:

```
ana@laptop:~/azure$ python applog.py
appended at offset 0 - blocks so far: 1
appended at offset 17 - blocks so far: 2
appended at offset 37 - blocks so far: 3
cart c-17 opened
cart c-17 paid 4590
cart c-03 opened
ana@laptop:~/azure$ python applog.py
appended at offset 54 - blocks so far: 4
appended at offset 71 - blocks so far: 5
appended at offset 91 - blocks so far: 6
cart c-17 opened
cart c-17 paid 4590
cart c-03 opened
cart c-17 opened
cart c-17 paid 4590
cart c-03 opened
```

**A segunda execução não começou um arquivo novo.** O blob existia, então o programa pulou o
`create_append_blob` e os três appends entraram depois dos três primeiros: deslocamentos 54, 71 e 91,
contagem de blocos de 4 a 6. Cada append é uma requisição, e a resposta diz onde ele caiu no blob.
Dois programas acrescentando ao mesmo blob ao mesmo tempo intercalam as linhas sem sobrescrever um ao
outro, que é a propriedade de que um log compartilhado precisa.

A documentação da Microsoft limita um append blob a 50.000 blocos acrescentados. Um programa que
acrescenta uma linha por requisição chega lá numa tarde movimentada, então os programas de log de
verdade juntam linhas e as acrescentam em lotes.

## Só acrescentar não é proteção

O tipo fixa que operações o blob aceita; não diz nada sobre quem pode apagá-lo ou trocá-lo. Um upload
com `--overwrite` não acrescenta. Ele troca o blob inteiro por um novo, do tipo que o upload criar:

```
ana@laptop:~/azure$ az storage blob upload -c app-logs -n checkout/2026-10-30.log -f export/orders-2026-10-27.csv --overwrite --no-progress -o none
ana@laptop:~/azure$ az storage blob show -c app-logs -n checkout/2026-10-30.log --query "[properties.blobType, properties.contentLength]" -o tsv
BlockBlob
64
ana@laptop:~/azure$ python applog.py 2>&1 | grep ErrorCode
ErrorCode:InvalidBlobType
```

As seis linhas do log sumiram, o blob agora é um block blob com um CSV, e a próxima execução do
programa de log falha no primeiro append com `InvalidBlobType`, porque um block blob não aceita
append. Um log que não pode ser reescrito precisa das políticas de imutabilidade da lição 5, que
recusam a própria troca.

## Page blobs

**Um page blob é uma sequência de tamanho fixo de páginas de 512 bytes, e qualquer página pode ser
escrita a qualquer momento.** É assim que um disco se comporta, e é para isso que os page blobs
existem: os discos das máquinas virtuais do Azure são guardados como page blobs. Uma plataforma de
dados raramente cria um, e os encontra mais como uma linha inesperada na conta de armazenamento. O
tamanho é declarado de saída e precisa ser múltiplo de 512 bytes:

`pages.py`:

```python
from azure.storage.blob import BlobServiceClient

service = BlobServiceClient.from_connection_string("UseDevelopmentStorage=true")
if not service.get_container_client("disks").exists():
    service.create_container("disks")
disk = service.get_blob_client("disks", "vm-01.vhd")

for size in (1000, 1024):
    try:
        disk.create_page_blob(size)
        print("created with", size, "bytes")
    except Exception as refusal:
        print(size, "bytes refused:", refusal.error_code)

try:
    disk.upload_page(b"x" * 100, offset=0, length=100)
except ValueError as refusal:
    print("100 bytes refused before sending:", refusal)

disk.upload_page(b"\x01" * 512, offset=512, length=512)
written, cleared = disk.get_page_ranges()
print("written ranges:", written)
data = disk.download_blob().readall()
print(len(data), "bytes; first page", data[:4], "second page", data[512:516])
```

```
ana@laptop:~/azure$ python pages.py
1000 bytes refused: StorageErrorCode.INVALID_OPERATION
created with 1024 bytes
100 bytes refused before sending: length must be an integer that aligns with 512 page size
written ranges: [{'start': 512, 'end': 1023}]
1024 bytes; first page b'\x00\x00\x00\x00' second page b'\x01\x01\x01\x01'
```

Duas recusas, depois a escrita que funciona. **O Azurite recusou um tamanho de 1.000 bytes** com o
código `InvalidOperation`, que a biblioteca imprime como uma constante dela,
`StorageErrorCode.INVALID_OPERATION`, porque 1.000 não é múltiplo de 512. A escrita de 100 bytes nem
saiu do computador: a biblioteca conferiu o alinhamento sozinha e lançou um `ValueError`, e por isso
essa linha traz uma mensagem do Python em vez de um código de erro. A escrita alinhada caiu na segunda
página. O blob tem 1.024 bytes, o serviço informa um trecho escrito, dos bytes 512 a 1023, e a página
que ninguém escreveu é lida como zeros. **Numa conta padrão só as páginas escritas são cobradas**,
segundo a documentação da Microsoft, e por isso um disco de 1 TB quase vazio não custa um terabyte. O
tamanho máximo documentado de um page blob é 8 TiB.
