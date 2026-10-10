---
title: O que uma execução precisa registrar
version: 1
---

Daqui a três semanas um arquivo vai dizer `0.9583`, e a pergunta vai ser *que execução foi essa*. Um
número sem registro ao lado não pode ser reproduzido, comparado nem confiado, e **memória não é
registro**: lá pela vigésima execução ninguém lembra em qual delas a taxa de aprendizado foi mudada à
mão.

Uma execução pode ser repetida quando cinco coisas ficam anotadas ao lado do resultado:

| o quê | por que importa |
| --- | --- |
| a configuração | cada ajuste, inclusive os que ficaram no valor padrão |
| a semente | as duas seções anteriores mostraram o que ela move |
| a versão do código | as mesmas configurações sobre outro código são outro experimento |
| a versão dos dados | uma nova divisão, ou uma biblioteca que mudou os dados, move o resultado |
| as versões das bibliotecas | uma nova versão do PyTorch ou do NumPy pode calcular a mesma coisa em outra ordem |

Depois, as próprias métricas. Anotar tudo isso à mão é o que ninguém faz na vigésima execução, então
um programa anota.

## Uma linha por execução

Salve como `~/dl/track.py`:

```schooling-example
{
  "language": "python",
  "file": "track.py",
  "parts": [
    {
      "code": "\"\"\"track: append one line of JSON per run to runs.jsonl, with everything that made the number.\"\"\"\nimport datetime\nimport hashlib\nimport json\nimport platform\nimport subprocess\n\nimport numpy as np\nimport sklearn\nimport torch\n\nimport digits",
      "note": "Só a biblioteca padrão e o que o curso já instalou. Um arquivo de rastreamento não precisa de servidor."
    },
    {
      "code": "def code_version():\n    \"\"\"The commit the directory is at, and whether any file differs from it.\"\"\"\n    git = lambda *args: subprocess.run([\"git\", *args], capture_output=True,\n                                       text=True, check=True).stdout\n    return {\"commit\": git(\"rev-parse\", \"--short\", \"HEAD\").strip(),\n            \"dirty\": git(\"status\", \"--porcelain\") != \"\"}",
      "note": "A versão do código é o commit, mais uma marca dizendo se os arquivos no disco ainda batem com ele. O `check=True` faz de um diretório que não é repositório um erro, nunca uma execução registrada sem versão."
    },
    {
      "code": "def data_version(seed=0):\n    \"\"\"The training set's fingerprint: change one pixel and it changes.\"\"\"\n    (x, y), _, _ = digits.load(seed)\n    digest = hashlib.sha256(x.tobytes() + y.tobytes()).hexdigest()[:12]\n    return {\"split_seed\": seed, \"train\": len(y), \"sha256\": digest}",
      "note": "Um hash dos bytes com que a rede treinou. Um scikit-learn novo que mudasse os dados, ou outra divisão, dá outra impressão digital mesmo com o código igual."
    },
    {
      "code": "def record(config, seed, metrics, path=\"runs.jsonl\"):\n    entry = {\n        \"time\": datetime.datetime.now().isoformat(timespec=\"seconds\"),\n        \"config\": config,\n        \"seed\": seed,\n        \"code\": code_version(),\n        \"data\": data_version(),\n        \"versions\": {\"python\": platform.python_version(), \"torch\": torch.__version__,\n                     \"numpy\": np.__version__, \"sklearn\": sklearn.__version__},\n        \"threads\": torch.get_num_threads(),\n        \"metrics\": metrics,\n    }\n    with open(path, \"a\") as f:\n        f.write(json.dumps(entry) + \"\\n\")\n    return entry",
      "note": "Um dicionário por execução, escrito como uma linha e acrescentado: o arquivo só cresce, e uma queda no meio de uma execução deixa intactas todas as linhas anteriores. O número de threads está aí pelo motivo que a seção sobre determinismo dá."
    }
  ]
}
```

E como `~/dl/run.py`, o programa que treina e registra:

```schooling-example
{
  "language": "python",
  "file": "run.py",
  "parts": [
    {
      "code": "\"\"\"run: train one configuration with one seed, and record it.\"\"\"\nimport argparse\n\nimport exp\nimport track\n\np = argparse.ArgumentParser()\np.add_argument(\"--hidden\", type=int, default=32)\np.add_argument(\"--lr\", type=float, default=0.01)\np.add_argument(\"--epochs\", type=int, default=10)\np.add_argument(\"--batch-size\", type=int, default=32)\np.add_argument(\"--seed\", type=int, default=0)\na = p.parse_args()",
      "note": "Toda configuração é um argumento com valor padrão, então uma execução muda pela linha de comando e nunca editando o arquivo. Uma edição é uma nova versão do código; um argumento é só outra execução da mesma versão."
    },
    {
      "code": "config = {\"hidden\": a.hidden, \"lr\": a.lr, \"epochs\": a.epochs, \"batch_size\": a.batch_size}\n_, acc = exp.run(config, a.seed)\nentry = track.record(config, a.seed, {\"val_acc\": round(acc, 4)})\nprint(f\"seed {a.seed}  val acc {acc:.4f}  commit {entry['code']['commit']}\"\n      + (\"  (uncommitted changes)\" if entry[\"code\"][\"dirty\"] else \"\"))",
      "note": "Treina, registra e imprime uma linha. O registro é escrito antes de qualquer impressão, então uma execução que aparece na tela é uma execução que está no arquivo."
    }
  ]
}
```

O formato é **JSON Lines**: um objeto JSON por linha, acrescentado ao fim. Cada linha se lê sozinha,
o `tail` mostra a última execução, e uma execução que morre no meio deixa todas as linhas anteriores
como estavam. Um único array JSON teria de ser lido, aumentado e reescrito inteiro a cada execução, e
uma queda durante a reescrita perde tudo.

## A versão do código é um commit

O nome mais limpo para o estado de um diretório de código é um commit do git: um hash curto que fixa
cada arquivo exatamente. O `~/dl` ainda não é um repositório. Primeiro diga ao git o que deixar de
fora, em `~/dl/.gitignore`:

```
# .gitignore: what git leaves out of ~/dl
.venv/
__pycache__/
runs.jsonl
```

O ambiente são gigabytes de bibliotecas instaladas, e o `requirements.txt` já dá o nome delas. O
`__pycache__` são as sobras compiladas do Python. E o `runs.jsonl` é saída, não código. O git pede um
nome e um endereço uma vez por máquina, e então vem o primeiro commit:

```
PENDING git
```

O `git status --short` listou dez arquivos e nada de `.venv`: os cinco programas desta aula até aqui,
os três das aulas 1 e 9, o `requirements.txt` e o `.gitignore`. Agora eles são o commit `HASH`. Uma
execução, e o registro dela:

```
PENDING record
```

**A semente 0 deu 0,9167, o mesmo número que o `spread.py` imprimiu para ela**: um processo novo, um
programa diferente chamando `exp.run`, e o mesmo resultado até o último dígito. O registro leva o
commit, `"dirty": false`, a impressão digital dos dados e cada versão que participou.

## A execução que ninguém consegue repetir

Agora o caso para o qual a marca `dirty` existe. Edite um programa sem fazer commit, e rode:

```
PENDING dirty
```

A nova linha do `runs.jsonl` cita o commit `HASH`, e **o código que rodou não é o commit `HASH`**:
ele tem uma linha que o commit não tem. Aqui a linha é um comentário e não muda nada, mas a marca não
tem como saber disso e nem deve tentar. O `git checkout exp.py` devolveu o arquivo ao que está no
commit, e o `git status` voltou a ficar quieto.

A regra que sai disso é curta: **o resultado de uma execução suja é uma pista, não uma descoberta.**
Faça o commit, rode de novo e fique com essa. O relatório da próxima seção deixa as execuções sujas de
fora por esse motivo.
