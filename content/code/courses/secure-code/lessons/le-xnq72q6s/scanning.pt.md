---
title: Achando um segredo antes do commit
version: 1
---

Um segredo num commit é muito mais barato de barrar do que de limpar, então a primeira defesa é um
scanner que roda **antes** de o commit existir. O **detect-secrets** é um: ele lê arquivos e aponta
strings com cara de credencial, por palavra-chave (`password`, `api_key`, `secret`) e por
aleatoriedade, e traz um hook feito exatamente para esse momento. Instale:

```
(.venv) ana@vm:~/sc/secrets$ pip install --progress-bar off detect-secrets==1.5.0
Collecting detect-secrets==1.5.0
  Using cached detect_secrets-1.5.0-py3-none-any.whl.metadata (23 kB)
Requirement already satisfied: pyyaml in /home/ana/sc/.venv/lib/python3.13/site-packages (from detect-secrets==1.5.0) (6.0.3)
Requirement already satisfied: requests in /home/ana/sc/.venv/lib/python3.13/site-packages (from detect-secrets==1.5.0) (2.34.2)
Requirement already satisfied: charset_normalizer<4,>=2 in /home/ana/sc/.venv/lib/python3.13/site-packages (from requests->detect-secrets==1.5.0) (3.5.2)
Requirement already satisfied: idna<4,>=2.5 in /home/ana/sc/.venv/lib/python3.13/site-packages (from requests->detect-secrets==1.5.0) (3.20)
Requirement already satisfied: urllib3<3,>=1.26 in /home/ana/sc/.venv/lib/python3.13/site-packages (from requests->detect-secrets==1.5.0) (2.8.0)
Requirement already satisfied: certifi>=2023.5.7 in /home/ana/sc/.venv/lib/python3.13/site-packages (from requests->detect-secrets==1.5.0) (2026.10.23)
Using cached detect_secrets-1.5.0-py3-none-any.whl (120 kB)
Installing collected packages: detect-secrets
Successfully installed detect-secrets-1.5.0
```

Pergunte sobre o arquivo como está:

```
(.venv) ana@vm:~/sc/secrets$ detect-secrets-hook app.py
ERROR: Potential secrets about to be committed to git repo!

Secret Type: Secret Keyword
Location:    app.py:5

Secret Type: Secret Keyword
Location:    app.py:6

Possible mitigations:
  - For information about putting your secrets in a safer place, please ask in
    #security
  - Mark false positives with an inline `pragma: allowlist secret` comment

If a secret has already been committed, visit
https://help.github.com/articles/removing-sensitive-data-from-a-repository
```

As duas linhas são encontradas: a chave de sessão e a chave do SMS, cada uma relatada como *Secret
Keyword*, quer dizer, o nome da variável parece de credencial e o valor é uma string. O código de
saída não é zero, então num hook o commit para aqui. O `check.sh` da aula 19 é o lugar deste
comando, ao lado do bandit e do pip-audit.

### O que o scanner sabe e o que não sabe

Ele aponta o que **parece** segredo. Um dado de teste de aparência aleatória também é apontado, e uma
chave real guardada numa variável chamada `x` pode não ser. Duas respostas, as mesmas da aula 19:

- **um falso positivo** é marcado na própria linha com `# pragma: allowlist secret`, que a mensagem
  da ferramenta sugere, e a linha diz por quê com palavras que um revisor consegue conferir;
- **um achado real** se corrige mudando o segredo de lugar, nunca acrescentando o pragma.

O arquivo de testes que vem a seguir nesta aula pede a mesma coisa pelo outro lado: ele falha se a
string `sms_live_` voltar a aparecer no `app.py`.
