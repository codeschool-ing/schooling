---
title: Verificação no código, e onde ela é desligada
version: 1
---

As bibliotecas verificam por padrão, e vale a pena confirmar esse padrão em vez de presumi-lo. Um
pequeno cliente Python que busca a loja com o contexto padrão da biblioteca padrão:

```schooling-example
{"language": "python", "file": "fetch.py", "parts": [{"code": "import ssl, urllib.request\n\nurl = \"https://www.example.com/\"\nctx = ssl.create_default_context()", "note": "`create_default_context()` é o jeito certo de obter TLS em Python: carrega o repositório de confiança do sistema, exige um certificado válido e verifica o nome."}, {"code": "print(\"verify:\", ctx.verify_mode.name, \"| check_hostname:\", ctx.check_hostname)", "note": "Imprima as duas configurações que importam, para que o padrão seja visto e não presumido."}, {"code": "print(urllib.request.urlopen(url, context=ctx).read().decode().strip())", "note": "Busque a página por esse contexto. Contra o impostor da seção anterior, esta linha falharia com `SSLCertVerificationError` e nunca enviaria a requisição."}], "output": "verify: CERT_REQUIRED | check_hostname: True\norders service: ok"}
```

Como rodou no `laptop`, contra a loja de verdade:

```
ana@laptop:~$ python3 fetch.py
verify: CERT_REQUIRED | check_hostname: True
orders service: ok
```

`CERT_REQUIRED` e `check_hostname: True`: as duas metades da verificação, a cadeia e o nome.

**A verificação é desligada no código por alguém corrigindo um erro**, quase sempre de boa-fé: um
servidor de testes com um certificado autoassinado, um serviço interno de antes de a empresa ter uma
CA, um proxy que quebrava o TLS. O desligamento então sobrevive até a produção. Cada linguagem tem a
sua grafia, o que as torna fáceis de procurar:

| onde | o que desliga a verificação |
|---|---|
| Python `requests` | `verify=False` |
| Python `ssl` | `CERT_NONE`, `check_hostname = False`, `_create_unverified_context()` |
| `curl` em scripts | `-k`, `--insecure` |
| Go | `InsecureSkipVerify: true` |
| Node.js | `rejectUnauthorized: false`, `NODE_TLS_REJECT_UNAUTHORIZED=0` |

Uma busca por essas grafias em uma base de código é uma linha, e vale a pena rodá-la em toda revisão
e na integração contínua. No diretório pessoal do `laptop` ela não encontra nada:

```
ana@laptop:~$ grep -rnE "verify=False|CERT_NONE|_create_unverified_context|curl -k|--insecure|InsecureSkipVerify" --include=*.py --include=*.sh --include=*.go . 2>/dev/null; echo "matches: $?"
matches: 1
```

O `grep` sai com 1 quando nada casou. **Cada ocorrência, em uma base de código real, é uma pergunta a
fazer**: que conexão isso protege, e o que um certificado falso faria ali?
