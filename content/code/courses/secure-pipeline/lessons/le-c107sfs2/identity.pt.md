---
title: "Identidade federada: a execução prova quem é"
version: 1
---

**Uma execução não precisa de um segredo para provar quem é; precisa de alguém em quem os dois lados
confiem para dizer isso.** Foi o servidor de CI que iniciou a execução, então ele conhece o
repositório e a branch melhor do que qualquer coisa que a execução pudesse afirmar sobre si mesma. Se
o servidor assinar essa afirmação com uma chave privada, e o Vault tiver a chave pública
correspondente, o Vault consegue conferir toda afirmação do servidor e acreditar nas que têm a
assinatura válida. A execução carrega a afirmação assinada por alguns minutos e mais nada.

O formato que quase todo mundo usa para essa afirmação é o **JSON Web Token**, um JWT, e o protocolo
que publica as chaves e dá nome aos campos é o OpenID Connect, e por isso a documentação de CI costuma
chamar isso de "OIDC". GitHub Actions, GitLab CI, CircleCI e Buildkite emitem esses tokens. Esta seção
faz o seu servidor de CI emiti-los também.

### A chave do servidor de CI

A chave privada é a coisa nova a proteger, e ela fica junto das outras chaves do servidor de CI, fora
de qualquer repositório. Gere-a e derive a metade pública que o Vault vai receber:

```
ana@vm:~/linkbox$ mkdir -p ~/ci/oidc && cd ~/ci/oidc
ana@vm:~/ci/oidc$ openssl genpkey -quiet -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out ci-oidc.key
ana@vm:~/ci/oidc$ openssl pkey -in ci-oidc.key -pubout -out ci-oidc.pub
```

`pkey -pubout` grava a chave pública, que não é segredo: qualquer um pode tê-la, porque ela só confere
assinaturas, não as cria. Repare no que acabou de acontecer com o problema do segredo zero. Ainda
existe um segredo de vida longa, a chave privada, mas ela nunca sai do servidor de CI e **nenhuma
execução a recebe**. Uma execução recebe um token que a chave assinou, e o token morre em cinco
minutos.

### O programa que emite os tokens

Serviços de CI de verdade montam esses tokens dentro dos próprios servidores. O seu é um programa
curto que usa a biblioteca padrão do Python para o JSON e pede a assinatura ao `openssl`. Salve-o como
`~/ci/oidc/mint.py`:

```schooling-example
{"language": "python", "file": "mint.py", "parts": [{"code": "\"\"\"The CI server's identity tokens. For the branch a run is building, a JSON\nWeb Token that says which repository and which branch it is, signed with\nthe CI server's own private key. Anybody holding the public half can check\nthat this server said it and that nobody changed a word since.\n\n    python3 ~/ci/oidc/mint.py REF [AUDIENCE]\n\nprints the token, which is good for five minutes. The audience is the one\nservice it is meant for; Vault, unless you say otherwise.\n\"\"\"", "note": "Para que serve o programa e como o servidor de CI o chama: com a branch que uma execução constrói, do jeito que o Git a nomeia, `refs/heads/main`."}, {"code": "import base64\nimport json\nimport os\nimport subprocess\nimport sys\nimport time\nimport uuid\nfrom pathlib import Path\n", "note": "A biblioteca padrão e mais nada. A assinatura em si é feita pelo `openssl`, que toda máquina Linux e macOS já tem; a biblioteca padrão do Python não tem RSA."}, {"code": "KEY = Path(os.environ.get(\"CI_OIDC_KEY\", Path.home() / \"ci/oidc/ci-oidc.key\"))\nISSUER = \"https://ci.linkbox.example\"\nREPOSITORY = \"ana/linkbox\"\nLIFETIME = 300\n\n", "note": "A chave privada é do servidor de CI, ao lado deste programa; `CI_OIDC_KEY` aponta para outro lugar, o que a aula usa uma vez para ver a chave de um estranho ser recusada. O emissor é o nome com que a CI assina, e o Vault só vai aceitar tokens desse nome."}, {"code": "def b64(data):\n    return base64.urlsafe_b64encode(data).rstrip(b\"=\").decode()\n\n", "note": "Um JWT são três pedaços de base64url, o alfabeto seguro para URLs, sem o preenchimento `=`."}, {"code": "def claims(ref, audience):\n    now = int(time.time())\n    return {\n        \"iss\": ISSUER,\n        \"sub\": f\"repo:{REPOSITORY}:ref:{ref}\",\n        \"aud\": audience,\n        \"repository\": REPOSITORY,\n        \"ref\": ref,\n        \"iat\": now,\n        \"nbf\": now,\n        \"exp\": now + LIFETIME,\n        \"jti\": str(uuid.uuid4()),\n    }\n\n", "note": "Os claims são as afirmações que o token faz. `iss`, `sub`, `aud`, `iat`, `nbf`, `exp` e `jti` são os padrão: quem disse, sobre quem, para quem, quando, e um id único. `repository` e `ref` são desta CI, os mesmos nomes que o GitHub Actions usa. O token morre cinco minutos depois de criado."}, {"code": "def mint(ref, audience=\"vault\"):\n    header = b64(json.dumps({\"alg\": \"RS256\", \"typ\": \"JWT\"}).encode())\n    payload = b64(json.dumps(claims(ref, audience)).encode())\n    signed = header + \".\" + payload\n    signature = subprocess.run([\"openssl\", \"dgst\", \"-sha256\", \"-sign\", str(KEY)],\n                               input=signed.encode(), capture_output=True, check=True).stdout\n    return signed + \".\" + b64(signature)\n", "note": "O cabeçalho diz como ele é assinado. Cabeçalho e claims são unidos por um ponto, e essa string é o que o `openssl` assina com a chave privada: mude um caractere de qualquer um dos dois e a assinatura deixa de bater."}, {"code": "\nif __name__ == \"__main__\":\n    print(mint(*sys.argv[1:3]))"}]}
```

O diretório agora guarda a identidade inteira do servidor de CI, e o `genpkey` criou a chave privada
legível só pela dona:

```
ana@vm:~/ci/oidc$ ls -l
total 12
-rw------- 1 ana ana 1704 Oct 23 09:44 ci-oidc.key
-rw-r--r-- 1 ana ana  451 Oct 23 09:44 ci-oidc.pub
-rw-r--r-- 1 ana ana 1636 Oct 23 09:44 mint.py
ana@vm:~/ci/oidc$ cd ~/linkbox
```

Os claims são a parte interessante do programa. `sub`, o subject, segue o mesmo padrão que o GitHub
Actions usa, `repo:DONO/REPO:ref:REF`, então os hábitos que você cria aqui valem lá. `repository` e
`ref` repetem duas partes do subject como claims separados, e é isso que deixa uma regra conferir cada
um exatamente, em vez de casar um padrão numa string mais longa.

### Um token, desmontado

Emita um para `main` e olhe para ele. Um JWT são três pedaços de base64url unidos por pontos: o
cabeçalho, os claims e a assinatura. Os primeiros 64 caracteres são o cabeçalho inteiro e o começo
dos claims:

```
ana@vm:~/linkbox$ main=$(python3 ~/ci/oidc/mint.py refs/heads/main)
ana@vm:~/linkbox$ cut -c1-64 <<<"$main"
eyJhbGciOiAiUlMyNTYiLCAidHlwIjogIkpXVCJ9.eyJpc3MiOiAiaHR0cHM6Ly9
ana@vm:~/linkbox$ jq -R 'split(".")[1] | gsub("-";"+") | gsub("_";"/") | @base64d | fromjson' <<<"$main"
{
  "iss": "https://ci.linkbox.example",
  "sub": "repo:ana/linkbox:ref:refs/heads/main",
  "aud": "vault",
  "repository": "ana/linkbox",
  "ref": "refs/heads/main",
  "iat": 1792759471,
  "nbf": 1792759471,
  "exp": 1792759771,
  "jti": "39d66bb6-3d6b-4844-b727-ea4847cd4ab4"
}
```

O segundo comando decodifica o pedaço do meio. O `jq` traduz os dois caracteres seguros para URL do
base64url de volta para o base64 padrão, decodifica e interpreta o JSON. **Qualquer um que tenha o
token faz o mesmo**, e essa é a primeira coisa a entender sobre um JWT: base64 é uma codificação, não
uma cifra. Os claims são públicos para quem vê o token, então levam identidades e nunca segredos.

O que torna os claims dignos de crédito é o terceiro pedaço. A assinatura cobre os dois primeiros
exatamente, byte a byte. Troque `refs/heads/try-something` por `refs/heads/main` num token e a
assinatura deixa de bater com o que foi assinado, então quem confere o recusa. **Os claims são
verdadeiros porque a assinatura confere, não porque parecem certos.**

Lendo os claims de cima para baixo:

| claim | significado | o que quem confere faz com ele |
|---|---|---|
| `iss` | o emissor, o nome do servidor de CI | aceita tokens de um emissor só |
| `sub` | o subject: este repositório, esta branch | registra como quem fez login |
| `aud` | a audiência, o único serviço a que o token se destina | recusa um token feito para outro serviço |
| `repository`, `ref` | os claims próprios da CI | compara com o que uma role permite |
| `iat`, `nbf`, `exp` | emitido em, não antes de, expira em, em segundos desde 1970 | recusa um token fora dessa janela |
| `jti` | um id único deste token | deixa quem guarda uma lista recusar um token usado duas vezes |

`exp` menos `iat` dá 300, os cinco minutos que o `mint.py` dá a todo token. É curto o bastante para
um token vazado num log estar morto antes de a maioria das pessoas ler o log, e longo o bastante para
um job começar, fazer login e buscar o que precisa.

### O que os serviços hospedados fazem diferente

A troca é a mesma em todo lugar; o encanamento em volta muda de dois jeitos, e a última seção desta
aula volta aos dois. Primeiro, um serviço hospedado não entrega a chave pública para você colar em
algum lugar. Ele **publica** as chaves num endereço conhecido, e quem confere as busca, então o
serviço troca a chave sem avisar cada cliente. Segundo, um job precisa **pedir** um token: no GitHub
Actions um workflow só recebe um se as `permissions` dele incluírem `id-token: write`, então um
workflow que nunca pediu não pode ser levado a apresentar um.

O seu servidor de CI não tem nenhum dos dois. O Vault vai receber a chave pública diretamente, e o
token é emitido à mão nesta aula, fazendo o papel que o servidor de CI faria em cada execução. A
próxima seção ensina o Vault a conferir esses tokens e mostra quais ele recusa.
