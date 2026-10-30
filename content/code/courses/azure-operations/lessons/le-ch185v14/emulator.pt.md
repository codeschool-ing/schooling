---
title: O motor de consulta, no seu computador
version: 1
---

**Um workspace do Log Analytics responde em KQL, a Kusto Query Language, e o Azure Data Explorer, o serviço para o qual
o KQL foi escrito, também.** A Microsoft publica o motor do Data Explorer como contêiner, o **emulador do Kusto**, para
desenvolvimento local. Ele não é um workspace: não tem as tabelas do Azure Monitor, nem retenção, nem cobrança, nem
conexão com nada. O que ele tem é a linguagem, rodada pelo motor de verdade, que é exatamente o que as próximas seis
lições precisam: toda consulta nelas foi executada, e toda resposta é o que o motor imprimiu.

Ele é grande. A imagem ocupa cerca de 4,6 GB em disco, e o contêiner recebe no máximo 4 GB de memória aqui; usou bem
menos de um quando o curso foi gravado. Suba uma vez; `--restart unless-stopped` o traz de volta depois de reiniciar a
máquina:

```sh
docker run -d --name kusto --restart unless-stopped -e ACCEPT_EULA=Y -m 4g -p 8080:8080 \
  mcr.microsoft.com/azuredataexplorer/kustainer-linux:2026.10.29.1806-2643-0ef1614-master
```

`ACCEPT_EULA=Y` aceita a licença da Microsoft para o emulador, que permite desenvolvimento e testes locais e não uso em
produção. A tag fixa o build com que este curso foi gravado.

```
ana@laptop:~/azure/kusto$ docker ps --format "{{.Names}}  {{.Status}}"
kusto  Up 6 seconds
ana@laptop:~/azure/kusto$ docker image ls --format "{{.Repository}}  {{.Size}}" | grep kustainer
mcr.microsoft.com/azuredataexplorer/kustainer-linux  4.64GB
```

## Um cliente seu

O emulador responde HTTP na porta 8080. Em vez de instalar um cliente, o curso usa um programa pequeno em Python,
escrito uma vez e usado em toda lição daqui para frente. Crie o diretório dele:

```sh
mkdir -p ~/azure/kusto && cd ~/azure/kusto
```

e salve isto nele como `kql.py`:

```schooling-example
{
  "language": "python",
  "file": "kql.py",
  "parts": [
    {
      "code": "# kql.py: send one query or command to the local Kusto emulator and print the answer as a table\nimport json, sys, urllib.error, urllib.request\n\nURL = \"http://localhost:8080/v1/rest/\"\nDATABASE = \"shop\"\n\n",
      "note": "Só a biblioteca padrão: nada para instalar. Toda consulta vai ao emulador na porta 8080, no banco `shop`."
    },
    {
      "code": "def ask(text):\n    # a command starts with a dot; comments above it are dropped, not sent\n    lines = text.strip().splitlines()\n    while lines and lines[0].lstrip().startswith(\"//\"):\n        lines.pop(0)\n    text = \"\\n\".join(lines)\n    kind = \"mgmt\" if text.startswith(\".\") else \"query\"\n",
      "note": "O Kusto tem dois endpoints. Um **comando**, que começa com ponto, como `.create`, vai para `mgmt`; uma **consulta** vai para `query`. Um comentário acima de um comando esconderia o ponto, então os comentários do começo saem antes."
    },
    {
      "code": "    body = json.dumps({\"db\": DATABASE, \"csl\": text}).encode()\n    request = urllib.request.Request(URL + kind, body, {\"Content-Type\": \"application/json\"})\n    try:\n        with urllib.request.urlopen(request) as answer:\n            return json.load(answer)[\"Tables\"][0]\n",
      "note": "A requisição é um JSON pequeno: o banco e o texto. A resposta traz uma ou mais tabelas; a primeira é o resultado."
    },
    {
      "code": "    except urllib.error.HTTPError as e:\n        text = e.read().decode()\n        try:\n            error = json.loads(text)[\"error\"]\n            sys.exit(error.get(\"@message\") or error[\"message\"])\n        except (ValueError, KeyError):\n            sys.exit(f\"{e.code} {e.reason}: {text}\")\n    except urllib.error.URLError as e:\n        sys.exit(f\"cannot reach the emulator at {URL}: {e.reason}\")\n\n",
      "note": "Uma consulta que o Kusto recusa volta como erro HTTP com a mensagem do próprio Kusto, impressa como veio. Um emulador parado ganha uma linha dizendo isso, e não um traceback."
    },
    {
      "code": "def show(table):\n    names = [c[\"ColumnName\"] for c in table[\"Columns\"]]\n    rows = [[\"\" if v is None else str(v) for v in row] for row in table[\"Rows\"]]\n    widths = [max(len(x) for x in column) for column in zip(names, *rows)]\n    for line in [names, *rows]:\n        print(\"  \".join(x.ljust(w) for x, w in zip(line, widths)).rstrip())\n\n",
      "note": "Colunas ajustadas ao valor mais largo, separadas por dois espaços: as tabelas de toda transcrição deste curso são impressas por estas seis linhas."
    },
    {
      "code": "show(ask(sys.argv[1] if len(sys.argv) > 1 else sys.stdin.read()))\n",
      "note": "O texto vem do primeiro argumento, ou da entrada padrão quando não há argumento, que é como uma consulta longa num arquivo é enviada: `python3 kql.py < arquivo.kql`."
    }
  ]
}
```

Depois crie o banco que as lições usam, e pergunte ao motor algo que ele responde sem dado nenhum:

```
ana@laptop:~/azure/kusto$ python3 kql.py '.create database shop volatile'
DatabaseName  PersistentPath  Created  StoresMetadata  StoresData
shop                          True     True            True
ana@laptop:~/azure/kusto$ python3 kql.py 'print answer = 6 * 7'
answer
42
```

`volatile` mantém o banco na memória do contêiner. É o equivalente, no emulador, ao esquecimento do moto: **um contêiner
reiniciado não tem banco nem tabelas**, então cada lição que precisa de dados começa carregando-os dos arquivos `.kql`
que as lições mostram. A carga leva segundos.

## Quando não responde

Um contêiner parado, ou ainda subindo, o que leva cerca de meio minuto, dá uma linha:

```
ana@laptop:~/azure/kusto$ python3 kql.py 'AppRequests | count'
cannot reach the emulator at http://localhost:8080/v1/rest/: [Errno 111] Connection refused
```

`docker start kusto` o traz de volta, vazio. Se o próprio `docker run` falhar com uma mensagem sobre memória, a máquina
tem menos de 4 GB livres para ele; feche outros programas, ou baixe o `-m` para `2g`, que bastou para os dados deste
curso.
