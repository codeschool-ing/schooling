---
title: Criptografia de envelope, para qualquer coisa maior
version: 1
---

O jeito de a AWS cifrar um terabyte com uma chave que só aceita 4 KB é a **criptografia de envelope**. O
KMS cria uma chave de dados nova e a entrega ao programa duas vezes, uma pura e uma cifrada com a chave
KMS. O programa cifra os dados ele mesmo com a pura, guarda a cifrada ao lado do resultado e esquece a
pura. O S3, o EBS e o RDS fazem exatamente isso em cada objeto, volume e banco, e um programa também pode,
em `~/aws/kms/envelope.py`:

```schooling-example
{"language": "python", "file": "envelope.py", "parts": [{"code": "# envelope.py: encrypt a file with a data key from KMS, and keep only the key's ciphertext\n#   python3 envelope.py seal FILE      writes FILE.sealed\n#   python3 envelope.py open FILE.sealed  prints what was sealed\nimport base64\nimport json\nimport os\nimport sys\n\nimport boto3\nfrom cryptography.hazmat.primitives.ciphers.aead import AESGCM\n\nkms = boto3.client(\"kms\")\n\n\n", "note": "Duas bibliotecas além da padrão: `boto3` para perguntar ao KMS, e `cryptography` para cifrar localmente. As duas já estão em `~/aws/venv`, porque o moto também precisa delas."}, {"code": "def seal(path):\n    key = kms.generate_data_key(KeyId=\"alias/shop-orders\", KeySpec=\"AES_256\")\n", "note": "**Uma requisição ao KMS por arquivo, qualquer que seja o tamanho.** A resposta traz a mesma chave de dados de 256 bits duas vezes: `Plaintext`, para usar agora, e `CiphertextBlob`, essa chave cifrada com `alias/shop-orders`, para guardar."}, {"code": "    nonce = os.urandom(12)\n    with open(path, \"rb\") as f:\n        data = AESGCM(key[\"Plaintext\"]).encrypt(nonce, f.read(), None)\n", "note": "O arquivo é cifrado aqui, neste computador, com AES-GCM, que também detecta qualquer mudança no resultado. Um nonce nunca é reusado com a mesma chave, e uma chave nova por arquivo torna isso fácil."}, {"code": "    sealed = {\n        \"key\": base64.b64encode(key[\"CiphertextBlob\"]).decode(),\n        \"nonce\": base64.b64encode(nonce).decode(),\n        \"data\": base64.b64encode(data).decode(),\n    }\n    with open(path + \".sealed\", \"w\") as f:\n        json.dump(sealed, f)\n\n\n", "note": "**O envelope**: os dados cifrados e, ao lado, a chave de dados cifrada. A chave de dados pura não é gravada em lugar nenhum e some quando a função retorna."}, {"code": "def unseal(path):\n    with open(path) as f:\n        sealed = json.load(f)\n    key = kms.decrypt(CiphertextBlob=base64.b64decode(sealed[\"key\"]))[\"Plaintext\"]\n    nonce, data = base64.b64decode(sealed[\"nonce\"]), base64.b64decode(sealed[\"data\"])\n    return AESGCM(key).decrypt(nonce, data, None)\n\n\n", "note": "Abrir faz o caminho inverso: o KMS decifra a pequena chave de dados, o que exige permissão em `alias/shop-orders`, e os dados são decifrados localmente. Quem não pode chamar `kms:Decrypt` tem nas mãos um arquivo de ruído."}, {"code": "if sys.argv[1] == \"seal\":\n    seal(sys.argv[2])\nelse:\n    sys.stdout.write(unseal(sys.argv[2]).decode())\n", "note": "`seal` grava o envelope; `open` imprime o que ele guardava, como texto, o que serve para o arquivo pequeno que esta seção sela."}]}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Dentro do KMS, a chave alias/shop-orders, que nunca sai. GenerateDataKey devolve uma chave de dados duas vezes: pura, e cifrada sob a chave KMS. A chave de dados pura e o orders.csv entram no AES-GCM, que produz os dados cifrados. O arquivo selado, orders.csv.sealed, guarda os dados cifrados e a chave de dados cifrada. A chave de dados pura é usada uma vez e depois esquecida.\"><defs><marker id=\"env-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"170\" height=\"150\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"105\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">dentro do KMS</text><rect x=\"30\" y=\"60\" width=\"150\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"105.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">chave KMS</text><text x=\"105.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">alias/shop-orders</text><text x=\"105\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nunca sai</text><path d=\"M192 82 L268 64\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#env-ah)\"></path><text x=\"196\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">GenerateDataKey</text><rect x=\"270\" y=\"40\" width=\"170\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"355.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">chave de dados, pura</text><rect x=\"270\" y=\"100\" width=\"170\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"355.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">chave de dados, cifrada</text><path d=\"M192 92 L268 118\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#env-ah)\"></path><rect x=\"270\" y=\"200\" width=\"170\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"355.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">orders.csv</text><rect x=\"480\" y=\"120\" width=\"120\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"540.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">AES-GCM</text><path d=\"M442 64 L520 118\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#env-ah)\"></path><path d=\"M442 218 L520 162\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#env-ah)\"></path><rect x=\"470\" y=\"190\" width=\"230\" height=\"100\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"585\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">orders.csv.sealed</text><rect x=\"484\" y=\"200\" width=\"202\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"585.0\" y=\"213.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">dados cifrados</text><rect x=\"484\" y=\"232\" width=\"202\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"585.0\" y=\"245.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">chave de dados cifrada</text><path d=\"M540 162 L540 198\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#env-ah)\"></path><path d=\"M442 128 L456 128 L456 245 L482 245\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#env-ah)\"></path><text x=\"355\" y=\"28\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">usada uma vez, depois esquecida</text></svg>", "caption": "A chave KMS cifra só a chave de dados. Os dados são cifrados no computador, e o envelope leva a chave cifrada ao lado deles."}
```

## Selando os pedidos

Um arquivo pequeno de pedidos inventados, com dígitos de cartão das faixas que as bandeiras publicam para
testes:

```
ana@laptop:~/aws/kms$ printf 'order,card_last4,total\n1001,4242,129.90\n1002,1881,59.00\n' > orders.csv
ana@laptop:~/aws/kms$ python3 envelope.py seal orders.csv
ana@laptop:~/aws/kms$ jq "keys" orders.csv.sealed
[
  "data",
  "key",
  "nonce"
]
ana@laptop:~/aws/kms$ jq -r .key orders.csv.sealed | base64 -d | wc -c
96
ana@laptop:~/aws/kms$ rm orders.csv && python3 envelope.py open orders.csv.sealed
order,card_last4,total
1001,4242,129.90
1002,1881,59.00
```

O envelope guarda três campos e nenhuma chave que alguém possa usar: a chave de dados que ele leva são
**96 bytes de texto cifrado** aqui, um pouco mais na AWS, legíveis só pedindo ao KMS. Com `orders.csv`
apagado, o único caminho de volta passa por `kms:Decrypt` em `alias/shop-orders`, que é uma permissão,
que é uma política, que é o objetivo.

## O tamanho não importa ao KMS

```
ana@laptop:~/aws/kms$ head -c 5000000 /dev/urandom > photos.tar && python3 envelope.py seal photos.tar && wc -c photos.tar photos.tar.sealed
 5000000 photos.tar
 6666868 photos.tar.sealed
11666868 total
```

Cinco megabytes custaram **a mesma requisição única** ao KMS que as três linhas; o trabalho é AES neste
computador. O arquivo selado é um terço maior, porque o programa o guarda em base64 dentro de JSON para
continuar legível; um formato de verdade guarda os bytes. A criptografia de envelope também é o motivo de
rotacionar uma chave KMS, na próxima seção, nunca cifrar dados de novo: só chaves de dados são cifradas
com ela.
