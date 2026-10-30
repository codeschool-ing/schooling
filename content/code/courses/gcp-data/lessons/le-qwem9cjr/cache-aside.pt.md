---
title: Cache-aside, e o preço que ficou velho
version: 1
---

**Cache-aside são três passos em toda leitura: pergunte ao cache, e numa falta leia o banco de dados
e ponha a resposta no cache com um tempo de vida.** O cache nunca fala com o banco. O programa faz as
duas metades, e é por isso que o padrão também se chama carga preguiçosa: nada entra no cache até
alguém pedir. É o jeito mais comum de pôr o Memorystore na frente do Cloud SQL, do Spanner ou do Firestore, e o jeito
como ele dá errado é o assunto desta seção.

As páginas de produto da Quitanda leem as mesmas poucas centenas de produtos o dia inteiro, de um
banco que também recebe todos os pedidos. É o formato que combina com um cache: muitas leituras das
mesmas chaves, poucas escritas, e uma cópia de alguns minutos atrás que não prejudica ninguém. Monte
um banco pequeno para fazer o papel do verdadeiro. O SQLite faz parte da biblioteca padrão do Python,
então isto não precisa de nada novo:

```sh
python3 - <<'EOF'
import sqlite3
db = sqlite3.connect('quitanda.db')
db.execute('CREATE TABLE products (id TEXT PRIMARY KEY, name TEXT, price_cents INTEGER)')
db.executemany('INSERT INTO products VALUES (?, ?, ?)', [
    ('p-101', 'banana prata 1kg', 1290),
    ('p-102', 'tomate italiano 1kg', 990),
    ('p-103', 'cafe torrado 500g', 3450),
])
db.commit()
EOF
```

O programa que o lê através do cache. Salve-o como `~/gcp/catalog.py`:

```schooling-example
{"language": "python", "file": "catalog.py", "parts": [{"code": "import json\nimport sqlite3\nimport sys\n\nimport redis\n\ncache = redis.Redis(host='127.0.0.1', port=6379, decode_responses=True)\ndb = sqlite3.connect('quitanda.db')\nTTL_SECONDS = 300\nreads = 0\n\n\n", "note": "Duas conexões: o cache no Redis local, e o arquivo de banco que o bloco acima criou. `decode_responses=True` faz o cliente devolver texto em vez de bytes. `reads` conta quantas vezes o banco é consultado."}, {"code": "def product(pid):\n    global reads\n    key = f'product:{pid}'\n    cached = cache.get(key)\n    if cached is not None:\n        return 'hit ', json.loads(cached)\n", "note": "**Passo um: pergunte ao cache.** A chave leva o tipo da coisa e o id dela, `product:p-101`, para que produtos e qualquer outra coisa posta no cache depois não colidam. Um acerto volta na hora, e o banco não é tocado."}, {"code": "    reads += 1\n    row = db.execute('SELECT name, price_cents FROM products WHERE id = ?',\n                     (pid,)).fetchone()\n    if row is None:\n        return 'none', None\n", "note": "**Passo dois, numa falta: leia o banco.** Um produto que não existe é respondido pelo banco toda vez, e nada vai para o cache por ele."}, {"code": "    value = {'id': pid, 'name': row[0], 'price_cents': row[1]}\n    cache.set(key, json.dumps(value), ex=TTL_SECONDS)\n    return 'miss', value\n\n\n", "note": "**Passo três: ponha a resposta no cache, com um tempo de vida.** O `ex=` é o mesmo `EX` do `redis-cli`. O valor é guardado como texto JSON, porque o Redis guarda strings."}, {"code": "def set_price(pid, cents):\n    db.execute('UPDATE products SET price_cents = ? WHERE id = ?', (cents, pid))\n    db.commit()\n    cache.delete(f'product:{pid}')\n\n\n", "note": "O caminho de escrita. Ele muda o banco primeiro e depois apaga a cópia do cache, então o próximo leitor falta e busca o preço novo."}, {"code": "if __name__ == '__main__':\n    if sys.argv[1] == 'price':\n        set_price(sys.argv[2], int(sys.argv[3]))\n    else:\n        for pid in sys.argv[1:]:\n            how, value = product(pid)\n            print(how, value)\n        print(f'database reads: {reads}')\n", "note": "`python3 catalog.py p-101 p-102` lê produtos; `python3 catalog.py price p-101 1390` muda um preço do jeito certo."}]}
```

```
ana@laptop:~/gcp$ python3 catalog.py p-101 p-102 p-101
miss {'id': 'p-101', 'name': 'banana prata 1kg', 'price_cents': 1290}
miss {'id': 'p-102', 'name': 'tomate italiano 1kg', 'price_cents': 990}
hit  {'id': 'p-101', 'name': 'banana prata 1kg', 'price_cents': 1290}
database reads: 2
ana@laptop:~/gcp$ redis-cli TTL product:p-101
(integer) 300
```

**O primeiro `p-101` faltou e o segundo acertou**, e o banco foi lido duas vezes para três
requisições. A segunda resposta para `p-101` veio da memória, sem SQL nenhum rodar. O `TTL` diz que
a cópia tem cinco minutos de vida, 300 segundos.

## O preço mudou, e o cache não ficou sabendo

Toda noite a Quitanda importa os preços do dia seguinte direto no banco, com um job que não sabe
nada do cache. Faça o que ele faz, com um produto:

```
ana@laptop:~/gcp$ python3 -c "import sqlite3; db = sqlite3.connect('quitanda.db'); db.execute('UPDATE products SET price_cents = 1390 WHERE id = ?', ('p-101',)); db.commit()"
ana@laptop:~/gcp$ python3 -c "import sqlite3; print(sqlite3.connect('quitanda.db').execute('SELECT price_cents FROM products WHERE id = ?', ('p-101',)).fetchone())"
(1390,)
ana@laptop:~/gcp$ python3 catalog.py p-101
hit  {'id': 'p-101', 'name': 'banana prata 1kg', 'price_cents': 1290}
database reads: 0
```

**O banco diz 1390 e a página continua dizendo 1290**, e vai continuar dizendo enquanto a chave
tiver tempo de vida. Nada falhou: o cache respondeu exatamente o que recebeu, e essa é toda a
dificuldade. Um cache só está certo enquanto todos que escrevem aqueles dados souberem que ele
existe.

**A correção fica no caminho de escrita: quem muda os dados apaga a cópia do cache.** O `set_price`
do programa faz isso, e a próxima leitura falta e busca o preço novo:

```
ana@laptop:~/gcp$ python3 catalog.py price p-101 1390
ana@laptop:~/gcp$ python3 catalog.py p-101
miss {'id': 'p-101', 'name': 'banana prata 1kg', 'price_cents': 1390}
database reads: 1
```

Ele apaga em vez de escrever o valor novo no cache, e isso é de propósito. Dois escritores correndo
para gravar o valor no cache podem deixar o mais antigo lá; um delete não deixa nada, e o próximo
leitor busca o que o banco tiver. O tempo de vida continua, como rede de proteção para o escritor
que esquece, como a importação noturna acima: com um TTL de 300 segundos, uma escrita esquecida fica
errada por no máximo cinco minutos, e sem TTL fica errada até alguém perceber.

## O que pôr no cache, e o que nunca pôr

**Ponha no cache o que é lido muito mais vezes do que muda, e o que não faz mal mostrar com alguns
minutos de atraso**: nomes e fotos de produtos, a lista de categorias, uma página de resultados de
busca, o horário de funcionamento de uma loja. **Nunca deixe uma cópia do cache decidir algo que
custa dinheiro.** A página do produto pode mostrar os 12,90 do cache; o checkout lê o preço do banco,
porque cobrar do cliente o valor velho é um bug com reembolso no fim. Vale o mesmo para o estoque:
"restam 3" numa página pode estar um pouco atrasado, e a baixa que vende o último é uma escrita no
banco.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 350\" role=\"img\" aria-label=\"Cache-aside em sete mensagens entre o programa, o cache e o banco de dados. Na leitura: o programa pede GET ao cache, recebe nil, faz SELECT no banco, recebe 1290 e grava o valor no cache com SET e EX 300. Depois o preço muda: o programa faz UPDATE no banco para 1390 e apaga a chave com DEL, e o próximo GET falta e lê 1390.\" data-fig=\"g12-aside-pt\"><defs><marker id=\"g12-aside-pt-ah-0\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"g12-aside-pt-ah-1\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"40\" y=\"14\" width=\"140\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">programa</text><polyline points=\"110,46 110,335\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></polyline><rect x=\"290\" y=\"14\" width=\"140\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">cache</text><polyline points=\"360,46 360,335\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></polyline><rect x=\"540\" y=\"14\" width=\"140\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"610\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">banco de dados</text><polyline points=\"610,46 610,335\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></polyline><polyline points=\"110,78 358,78\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#g12-aside-pt-ah-0)\"></polyline><text x=\"235.0\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">GET product:p-101</text><polyline points=\"360,108 112,108\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#g12-aside-pt-ah-1)\"></polyline><text x=\"235.0\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">nil: falta</text><polyline points=\"110,138 608,138\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#g12-aside-pt-ah-0)\"></polyline><text x=\"485\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">SELECT ... WHERE id = 'p-101'</text><polyline points=\"610,168 112,168\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#g12-aside-pt-ah-1)\"></polyline><text x=\"485\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1290</text><polyline points=\"110,198 358,198\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#g12-aside-pt-ah-0)\"></polyline><text x=\"235.0\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">SET product:p-101 ... EX 300</text><polyline points=\"30,222 690,222\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></polyline><text x=\"360\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">depois, o preço muda</text><polyline points=\"110,270 608,270\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#g12-aside-pt-ah-0)\"></polyline><text x=\"485\" y=\"260\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">UPDATE ... 1390</text><polyline points=\"110,300 358,300\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#g12-aside-pt-ah-0)\"></polyline><text x=\"235.0\" y=\"290\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">DEL product:p-101</text><text x=\"360\" y=\"328\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">o próximo GET falta e lê 1390</text></svg>", "caption": "O cache nunca fala com o banco. Quem lê preenche o cache numa falta, e quem escreve apaga a cópia depois de mudar o banco.", "same": ["cache"]}
```
