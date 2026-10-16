---
title: Um object store, e o que ele não faz
version: 1
---

**Um object store guarda *objetos*: uma chave, um valor de qualquer tamanho e um pouco de
metadados.** Você escreve um objeto inteiro, numa requisição; lê o objeto, ou um trecho dos bytes
dele; apaga; lista chaves por prefixo. Essa é quase toda a interface, e é o que o Amazon S3 ofereceu
em 2006 e o que o equivalente de cada nuvem oferece hoje. O Google Cloud Storage e o Azure Blob
Storage diferem em detalhes e dividem o modelo.

De longe ele parece um sistema de arquivos, porque as chaves têm barras, e não é. O que ele não tem
é o assunto desta seção e da próxima:

- **Não tem diretórios.** `raw/clicks/day=2025-01-01/part-0.csv.gz` é uma chave. Nada chamado
  `raw/clicks/` existe, e "listar um diretório" é pedir as chaves que começam com isso.
- **Não tem renomear.** Um nome novo é um objeto novo: copiar, depois apagar o antigo.
- **Não tem acréscimo nem edição.** Mudar um byte quer dizer escrever o objeto inteiro de novo.

O que ele tem em troca é o que o fez vencer na nuvem: armazenamento que cresce sem ninguém
acrescentar discos, cobrado por gigabyte por mês, guardado em várias cópias pelo provedor e
acessível de quantas máquinas for ao mesmo tempo. Um cluster pode ser desligado à noite e os dados
continuam lá, porque nunca estiveram nele. A aula 14 conta quanto isso economiza.

## Um substituto na sua máquina

Não é preciso o object store de empresa nenhuma para ver o modelo. O `moto` é uma biblioteca Python
que responde à API do S3 localmente; ele foi feito para testar programas, guarda tudo na memória e
perde tudo quando para, o que o torna do tamanho certo para uma demonstração e a coisa errada para
guardar dados. O `boto3` é o cliente Python do S3. Instale os dois num ambiente virtual próprio e
inicie o servidor em segundo plano:

```sh
python3 -m venv ~/s3-env
~/s3-env/bin/pip install "moto[server]==5.2.3" boto3==1.43.111
setsid ~/s3-env/bin/moto_server -p 9090 > ~/moto.log 2>&1 < /dev/null &
```

O `setsid` inicia o servidor numa sessão própria, para que fechar o terminal não o pare. Então este
programa envia janeiro, lista e move, do único jeito que um object store permite. Salve como
`~/big/s3_demo.py`:

```schooling-example
{
  "language": "python",
  "file": "s3_demo.py",
  "parts": [
    {
      "code": "\"\"\"What an object store does differently: upload a month of the clicks, list\nthem, and 'rename' the month the only way an object store can.\"\"\"\nimport glob\nimport time\n\nimport boto3\n\n"
    },
    {
      "code": "s3 = boto3.client(\"s3\", endpoint_url=\"http://localhost:9090\", region_name=\"us-east-1\",\n                  aws_access_key_id=\"test\", aws_secret_access_key=\"test\")\ns3.create_bucket(Bucket=\"pontofinal-lake\")\n\n",
      "note": "A API do S3, apontada para o substituto local em vez da Amazon. As chaves são as duas palavras que o moto aceita; um armazenamento de verdade pediria credenciais de verdade, e o código seria o mesmo."
    },
    {
      "code": "for path in sorted(glob.glob(\"data/raw/clicks/day=2025-01-*/*.csv.gz\")):\n    day = path.split(\"/\")[3]\n    with open(path, \"rb\") as f:\n        s3.put_object(Bucket=\"pontofinal-lake\", Key=f\"raw/clicks/{day}/part-0.csv.gz\", Body=f)\n\n",
      "note": "**Um objeto é escrito inteiro, numa requisição, sob uma chave.** A chave parece um caminho, com barras e tudo, e o armazenamento não liga: não existe diretório `raw/clicks/` em lugar nenhum, só trinta e uma chaves que começam com esses caracteres."
    },
    {
      "code": "listing = s3.list_objects_v2(Bucket=\"pontofinal-lake\", Prefix=\"raw/clicks/\", Delimiter=\"/\")\nprint(\"folders:\", len(listing[\"CommonPrefixes\"]), \"first:\", listing[\"CommonPrefixes\"][0][\"Prefix\"])\n\n",
      "note": "Listar pede chaves com um prefixo. Com um `Delimiter`, o armazenamento agrupa as chaves pelo que vem antes da próxima barra e responde com esses grupos, que é como um cliente desenha pastas que não existem."
    },
    {
      "code": "start = time.time()\nkeys = [o[\"Key\"] for o in s3.list_objects_v2(Bucket=\"pontofinal-lake\", Prefix=\"raw/\")[\"Contents\"]]\nfor key in keys:\n    s3.copy_object(Bucket=\"pontofinal-lake\", Key=\"archive/\" + key,\n                   CopySource={\"Bucket\": \"pontofinal-lake\", \"Key\": key})\n    s3.delete_object(Bucket=\"pontofinal-lake\", Key=key)\nprint(f\"moved {len(keys)} objects with {2 * len(keys)} requests in {time.time() - start:.2f} s\")\n",
      "note": "**Não existe renomear.** Mover o mês para `archive/` quer dizer copiar cada objeto para a chave nova e apagar a antiga, uma requisição cada, com o mês metade em cada lugar enquanto isso roda."
    }
  ]
}
```

```
ana@lab:~/big$ ~/s3-env/bin/python s3_demo.py
folders: 31 first: raw/clicks/day=2025-01-01/
moved 31 objects with 62 requests in 0.56 s
```

**Trinta e uma "pastas" que são trinta e um prefixos de chave, e um movimento que levou sessenta e
duas requisições.** Na memória da sua própria máquina, isso é cerca de meio segundo. Contra um object
store de verdade, atravessando uma rede, cada requisição custa algumas dezenas de milissegundos,
então mover 50.000 objetos um a um são 100.000 requisições e boa parte de uma hora. O mesmo
movimento no HDFS:

```
ana@lab:~/big$ time hdfs dfs -mv /raw/clicks-2025.csv /raw/clicks-2025-moved.csv

real	0m2.754s
user	0m5.333s
sys	0m0.322s
```

**Uma requisição ao namenode, seja qual for o tamanho do arquivo**: os 2,8 segundos são quase todos o
tempo que o Java leva para iniciar. Renomear no HDFS muda
uma entrada na memória do namenode, e é *atômico*: quem olha vê o nome antigo ou o novo, nunca
metade de cada.

**O Spark lê um object store com o mesmo código**, `s3a://bucket/chave` no lugar de `hdfs://`, por
meio de um conector que o Hadoop oferece. Esse conector e a biblioteca da Amazon por baixo dele
somam mais de 600 MB de jars, então este laboratório não os instala, e nenhum job Spark deste curso
rodou contra um object store. Tudo o que esta seção mostrou sobre objetos vale para o que o Spark
veria pelo conector, e a próxima seção trata do ponto em que isso dói.
