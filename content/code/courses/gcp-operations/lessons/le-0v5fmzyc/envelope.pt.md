---
title: Criptografia de envelope, no seu próprio disco
version: 1
---

**O Cloud KMS não criptografa os seus dados; ele criptografa as chaves que criptografam os seus dados.** Esse
arranjo é a **criptografia de envelope**. Cada objeto é criptografado com a própria chave de dados (DEK), gerada na
hora; a DEK é então criptografada, "embrulhada", com uma chave de criptografia de chaves (KEK) que vive no Cloud KMS,
e a DEK embrulhada é guardada ao lado do texto cifrado. Para ler o objeto, um programa pede ao Cloud KMS para
desembrulhar a DEK, e descriptografa localmente. A KEK nunca sai do Google, a DEK pura nunca é guardada em lugar
nenhum, e o Cloud KMS vê poucos bytes de chave por objeto em vez dos gigabytes de dados. **O Cloud KMS não tem
emulador, então não é usado aqui.** O que roda é o próprio padrão, com a KEK como arquivos no seu disco; cada lugar
onde o programa lê um arquivo de KEK é um lugar onde um código real faria uma chamada ao Cloud KMS.

Um pacote, no ambiente do curso:

```sh
cd ~/gcp && source venv/bin/activate
pip install -q 'cryptography==50.0.2'
```

Escreva o programa em `~/gcp/envelope.py`:

```schooling-example
{"language": "python", "file": "envelope.py", "parts": [{"code": "\"\"\"envelope.py: envelope encryption, the pattern Cloud KMS is built for.\n\nA key-encryption key (KEK) wraps a fresh data-encryption key (DEK) for every\nobject. Here the KEK versions are files on your disk; in Cloud KMS they never\nleave Google, and wrapping and unwrapping are calls to it.\n\"\"\"\n", "note": "A docstring é a ideia inteira em quatro linhas: uma KEK embrulha uma DEK nova para cada objeto. Aqui a KEK é um arquivo; no Cloud KMS ela nunca sai do Google."}, {"code": "import json\nimport os\nimport pathlib\nimport sys\n\nfrom cryptography.hazmat.primitives.ciphers.aead import AESGCM\n\n", "note": "`AESGCM`, do pacote `cryptography`, é criptografia autenticada: recusa descriptografar qualquer coisa que tenha sido alterada, em vez de devolver lixo."}, {"code": "KEYS = pathlib.Path(\"kek\")          # stands for a Cloud KMS key and its versions\n\n\ndef kek(version):\n    return (KEYS / f\"v{version}.bin\").read_bytes()\n\n\ndef primary():\n    return max(int(p.stem[1:]) for p in KEYS.glob(\"v*.bin\"))\n\n\n", "note": "As versões da KEK são os arquivos `kek/v1.bin`, `kek/v2.bin`, e a **primária** é a mais nova. O Cloud KMS guarda exatamente isso: uma chave, versões numeradas, uma delas primária."}, {"code": "def rotate():\n    KEYS.mkdir(exist_ok=True)\n    v = primary() + 1 if any(KEYS.glob(\"v*.bin\")) else 1\n    (KEYS / f\"v{v}.bin\").write_bytes(AESGCM.generate_key(bit_length=256))\n    print(f\"key version {v} is now primary\")\n\n\n", "note": "Girar acrescenta uma versão nova e a torna primária. As versões antigas ficam, então tudo o que elas embrulharam ainda pode ser lido."}, {"code": "def encrypt(name, text):\n    dek = AESGCM.generate_key(bit_length=256)\n    n1, n2 = os.urandom(12), os.urandom(12)\n    v = primary()\n    wrapped = AESGCM(kek(v)).encrypt(n1, dek, None)\n    body = AESGCM(dek).encrypt(n2, text.encode(), None)\n    pathlib.Path(name).write_text(json.dumps({\n        \"kek_version\": v, \"wrapped_dek\": (n1 + wrapped).hex(),\n        \"ciphertext\": (n2 + body).hex()}))\n    print(f\"{name}: encrypted under key version {v}\")\n\n\n", "note": "Criptografar gera uma DEK nova de 256 bits, criptografa o texto com ela, embrulha a DEK com a KEK primária, e guarda a DEK embrulhada e a versão da KEK **ao lado do texto cifrado**. A DEK em si nunca é guardada."}, {"code": "def decrypt(name):\n    doc = json.loads(pathlib.Path(name).read_text())\n    w = bytes.fromhex(doc[\"wrapped_dek\"])\n    dek = AESGCM(kek(doc[\"kek_version\"])).decrypt(w[:12], w[12:], None)\n    c = bytes.fromhex(doc[\"ciphertext\"])\n    print(f\"{name}: {AESGCM(dek).decrypt(c[:12], c[12:], None).decode()}\")\n\n\n", "note": "Descriptografar lê que versão embrulhou a DEK, a desembrulha com essa versão, e descriptografa o texto. No Cloud KMS desembrulhar é uma chamada ao Google, e a KEK nunca chega ao programa."}, {"code": "cmd = sys.argv[1]\nif cmd == \"rotate\":\n    rotate()\nelif cmd == \"encrypt\":\n    encrypt(sys.argv[2], sys.argv[3])\nelif cmd == \"decrypt\":\n    decrypt(sys.argv[2])\n", "note": "Três comandos: `rotate`, `encrypt NOME TEXTO` e `decrypt NOME`."}]}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Uma versão da chave de criptografia de chaves, v1, embrulha uma chave de dados nova. A chave de dados criptografa o pedido. O que se guarda lado a lado é a chave de dados embrulhada, o texto cifrado e o número da versão da chave; a chave de dados em claro é descartada.\"><defs><marker id=\"ah7\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"150\" height=\"50\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"95\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">KEK v1</text><text x=\"95\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no Cloud KMS</text><rect x=\"20\" y=\"130\" width=\"150\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"95\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">DEK nova</text><text x=\"95\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">por objeto</text><rect x=\"250\" y=\"130\" width=\"150\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"325\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o pedido</text><line x1=\"172\" y1=\"155\" x2=\"248\" y2=\"155\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#ah7)\"></line><text x=\"210\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">cifra</text><line x1=\"95\" y1=\"82\" x2=\"95\" y2=\"128\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#ah7)\"></line><text x=\"120\" y=\"105\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">embrulha</text><rect x=\"470\" y=\"40\" width=\"230\" height=\"150\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"585\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">guardado junto</text><text x=\"585\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">kek_version: 1</text><text x=\"585\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">wrapped_dek</text><text x=\"585\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ciphertext</text><line x1=\"402\" y1=\"155\" x2=\"468\" y2=\"155\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah7)\"></line></svg>", "caption": "A chave de chaves nunca toca os dados. Só a pequena chave de dados passa por ela.", "same": ["KEK v1"]}
```

## Dois objetos, duas versões de chave

Crie `~/gcp/vault`, trabalhe de dentro dele, e faça a primeira versão da chave; depois criptografe um pedido com ela:

```
ana@laptop:~/gcp/vault$ python3 ../envelope.py rotate
key version 1 is now primary
ana@laptop:~/gcp/vault$ python3 ../envelope.py encrypt order-1001.json 'card ending 4242, R$ 43.80'
order-1001.json: encrypted under key version 1
ana@laptop:~/gcp/vault$ jq -c '{kek_version, wrapped_dek: .wrapped_dek[:24], ciphertext: .ciphertext[:24]}' order-1001.json
{"kek_version":1,"wrapped_dek":"f38a234e4845963e0172c1e1","ciphertext":"c368dd5bd7a542f4c6b56eac"}
```

O arquivo guarda três coisas: que versão da KEK embrulhou a DEK dele, a DEK embrulhada e o texto cifrado (o `jq`
mostra os primeiros caracteres de cada). Nada nele pode ser lido sem a versão 1. Agora gire e criptografe um segundo
pedido:

```
ana@laptop:~/gcp/vault$ python3 ../envelope.py rotate
key version 2 is now primary
ana@laptop:~/gcp/vault$ python3 ../envelope.py encrypt order-1002.json 'pix, R$ 18.90'
order-1002.json: encrypted under key version 2
ana@laptop:~/gcp/vault$ python3 ../envelope.py decrypt order-1001.json
order-1001.json: card ending 4242, R$ 43.80
ana@laptop:~/gcp/vault$ python3 ../envelope.py decrypt order-1002.json
order-1002.json: pix, R$ 18.90
ana@laptop:~/gcp/vault$ ls kek
v1.bin
v2.bin
```

**A rotação não recriptografou nada.** O primeiro pedido continua embrulhado pela versão 1, que ainda existe, então
ainda descriptografa; o segundo está embrulhado pela versão 2, a nova primária. É exatamente o que a rotação
automática do Cloud KMS faz: acrescenta uma versão e a torna primária, e dados antigos continuam legíveis pelas
versões antigas. Girar limita quantos dados uma versão protege; não muda dados já escritos.

## Destruindo uma versão

Apague a versão 1, como destruir uma versão de chave no Cloud KMS faria:

```
ana@laptop:~/gcp/vault$ rm kek/v1.bin
ana@laptop:~/gcp/vault$ python3 ../envelope.py decrypt order-1001.json 2>&1 | tail -1
FileNotFoundError: [Errno 2] No such file or directory: 'kek/v1.bin'
ana@laptop:~/gcp/vault$ python3 ../envelope.py decrypt order-1002.json
order-1002.json: pix, R$ 18.90
```

**O primeiro pedido não pode mais ser lido por ninguém, nunca**, e o segundo fica intacto. Destruir uma versão de
chave é a única operação que torna dados irrecuperáveis sem tocar neles: o texto cifrado continua no disco, e é
ruído. Isso é útil de propósito (apagar toda cópia dos dados de um cliente, backups inclusive, destruindo a única
chave que os embrulhou) e catastrófico por acidente. A próxima seção é sobre as proteções que o Cloud KMS põe na
frente disso.
