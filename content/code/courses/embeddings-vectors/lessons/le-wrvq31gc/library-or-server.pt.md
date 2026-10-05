---
title: No seu processo ou do outro lado da rede
version: 1
---

As aulas 12 e 13 apresentaram seis ferramentas, e a diferença que mais importa na hora de colocar uma
em produção não está nas APIs. **Um índice no seu processo é rápido de alcançar e particular àquele
processo; um servidor é uma cópia que todos os processos compartilham, ao custo de um salto pela rede
e de um programa para rodar.** FAISS, LanceDB, o `PersistentClient` do Chroma e o modo local do
Qdrant são do primeiro tipo. O `chroma run` do Chroma, o servidor do Qdrant, o Weaviate e o Pinecone
são do segundo.

## A memória é por processo

Um índice do FAISS mora na memória do programa que o carregou. O índice plano que o `factory.py`
construiu foi gravado em `random.faiss`, e lê-lo de volta custa mais ou menos o tamanho do arquivo:

```
ana@lab:~/emb$ ls -l random.faiss
-rw-r--r-- 1 ana ana 30720045 Oct  5 14:24 random.faiss
ana@lab:~/emb$ python mem.py
20000 vectors; 29 MB more memory in this process
```

29 MB para um processo. Uma aplicação web que roda quatro processos workers, cada um carregando o
índice ao iniciar, guarda quatro cópias, e um quinto processo que acrescenta um artigo muda só a
cópia dele. Nada no FAISS avisa os outros; eles veem a mudança quando lerem o arquivo de novo. Para a
central de ajuda isso não é problema. Para um catálogo de milhões de vetores, decide o tamanho da
máquina, e se cada worker pode pagar pela própria cópia.

## Dois processos, um diretório

O modo local do Qdrant aceita um dono só, e diz isso. O LanceDB aceita mais, nos termos dele. Este
programa mantém cada diretório aberto e inicia um segundo processo contra ele:

```schooling-example
{
  "language": "python",
  "file": "two.py",
  "parts": [
    {
      "code": "import subprocess\nimport lancedb\nfrom qdrant_client import QdrantClient\n\ndef other(code):\n    r = subprocess.run([\"python\", \"-c\", code], capture_output=True, text=True)\n    return (r.stdout or r.stderr).strip().splitlines()[-1]",
      "note": "`other` roda uma linha de Python num segundo processo e devolve a última linha que ele imprimiu, ou a última linha do erro."
    },
    {
      "code": "mine = QdrantClient(path=\"qdrant\")\nprint(\"qdrant, second process:\", other(\n    \"from qdrant_client import QdrantClient; QdrantClient(path='qdrant')\"))\nmine.close()",
      "note": "Este processo abre o diretório do Qdrant, um segundo processo tenta abri-lo também, e este o fecha."
    },
    {
      "code": "table = lancedb.connect(\"lance\").open_table(\"help\")\nprint(\"lance, this process:  \", table.count_rows(), \"rows, version\", table.version)\nprint(\"lance, second process:\", other(\n    \"import lancedb; from minilm import embed; t = lancedb.connect('lance').open_table('help'); \"\n    \"t.add([{'id': 'h42', 'category': 'orders', 'lang': 'en', 'title': 'x', 'vector': embed('x')[0]}]); \"\n    \"print(t.count_rows(), 'rows, version', t.version)\"))\nprint(\"lance, this process:  \", table.count_rows(), \"rows, version\", table.version)\ntable.checkout_latest()\nprint(\"lance, after checkout:\", table.count_rows(), \"rows, version\", table.version)",
      "note": "Este processo abre a tabela do LanceDB; um segundo processo adiciona uma linha; este conta de novo e depois passa para a versão mais recente."
    }
  ],
  "output": "ana@lab:~/emb$ python two.py\nqdrant, second process: RuntimeError: Storage folder qdrant is already accessed by another instance of Qdrant client. If you require concurrent access, use Qdrant server instead.\nlance, this process:   40 rows, version 3\nlance, second process: 41 rows, version 4\nlance, this process:   40 rows, version 3\nlance, after checkout: 41 rows, version 4"
}
```

**O Qdrant recusou o segundo processo**, e a recusa já aponta a saída: um servidor. O
`PersistentClient` do Chroma é feito para um processo do mesmo jeito, e é por isso que a aula 12
serviu o diretório dele com `chroma run` antes de deixar vários programas usá-lo.

**O LanceDB deixou o segundo processo gravar**, e o primeiro não viu a linha nova: ele continuava
lendo a versão 3, a que tinha aberto, e contou 40. Só o `checkout_latest()` o levou para a versão 4 e
41 linhas. É o versionamento do LanceDB funcionando, e é uma escolha que o seu programa tem
de fazer de propósito: quão desatualizado um leitor pode estar, e quando ele olha de novo.

## Quanto custa cada lado

| | no seu processo | do outro lado da rede |
|---|---|---|
| alcançar | uma chamada de função | uma requisição, com a ida e volta dela |
| memória | uma cópia por processo que carrega | uma cópia, no servidor |
| vários programas | recusados, ou cada um com a sua cópia | o caso normal |
| operar | nada para rodar; o seu programa é dono dos arquivos e das cópias de segurança | um processo para implantar, atualizar, vigiar e guardar cópia |
| passar de uma máquina | não sem trabalho seu | trabalho do servidor, ou do fornecedor |

**Comece no seu processo quando um programa for dono dos dados**, que é o caso da maioria dos
protótipos, de todo teste, de uma ferramenta de linha de comando e da central de ajuda da Marginalia
hoje. **Vá para o outro lado da rede quando vários programas precisarem dos mesmos vetores, ou quando
eles não couberem mais ao lado de cada worker.** A mudança é mais barata do que parece quando a
biblioteca com que você começou tem um servidor com a mesma API. É o caso do Chroma e do Qdrant: a
aula 12 mudou um construtor, e `QdrantClient(url=...)` é a mesma mudança. Sair do FAISS significa
escrever o servidor em volta dele, ou adotar um banco de dados.

A aula 14 acrescenta uma última opção que as seis ferramentas daqui não cobrem: os vetores guardados
no banco de dados que a loja já roda, ao lado dos pedidos e dos clientes, e consultados com SQL.
