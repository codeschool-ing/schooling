---
title: Ruído, e como responder a ele
version: 1
---

Uma verificação estática conhece padrões, não intenções, então parte do que ela aponta não é
problema. **Uma verificação que grita lobo a cada execução é uma verificação que as pessoas aprendem
a ignorar**, então o ruído tem de ser tratado de propósito, um achado por vez, e nunca desligando a
verificação.

Rode o bandit na pasta inteira, com um formato de uma linha mais fácil de ler no terminal:

```
(.venv) ana@vm:~/sc/checks$ bandit -q -r . -f custom --msg-template '{relpath}:{line}: {test_id} {msg}'
app.py:8: B105 Possible hardcoded password: 'vereda-dev'
app.py:12: B311 Standard pseudo-random generators are not suitable for security/cryptographic purposes.
app.py:16: B324 Use of weak MD5 hash for security. Consider usedforsecurity=False
app.py:20: B201 A Flask app appears to be run with debug=True, which exposes the Werkzeug debugger and allows the execution of arbitrary code.
test_app.py:7: B101 Use of assert detected. The enclosed code will be removed when compiling to optimised byte code.
test_app.py:8: B101 Use of assert detected. The enclosed code will be removed when compiling to optimised byte code.
test_app.py:12: B101 Use of assert detected. The enclosed code will be removed when compiling to optimised byte code.
```

Três achados novos, todos **B101** no `test_app.py`: o `assert` é removido quando o Python roda com
otimização ligada, então código que depende de `assert` para uma decisão de segurança perde a
verificação. Isso é verdade, e vale para código da aplicação. Num arquivo do pytest, `assert` é como
um teste diz o que espera, e o pytest nunca roda otimizado. A resposta certa é **deixar os arquivos de
teste fora da varredura**, com `-x ./test_app.py`, e não parar de usar `assert` nos testes.

### Três tipos de resposta

| achado | resposta certa | por quê |
|---|---|---|
| uma falha real (B311 no código de redefinição) | corrigir o código | o achado é a razão de ser da ferramenta |
| um padrão usado com segurança de propósito (B324 num identificador de recibo) | dizer isso **no código**, onde a ferramenta e quem lê veem | a intenção fica registrada ao lado da linha que ela explica |
| uma regra que não vale para um tipo inteiro de arquivo (B101 nos testes) | excluir esses arquivos, no comando que todo mundo roda | uma decisão, tomada uma vez, visível no repositório |

Para o identificador do recibo, o próprio `hashlib` do Python tem o jeito de dizer isso:
`hashlib.md5(…, usedforsecurity=False)` declara que esse resumo não protege nada, e a própria mensagem
do bandit sugeriu exatamente isso. Onde uma biblioteca não oferece argumento assim, o bandit aceita
um comentário na linha, `# nosec B324`, e o comentário deve trazer o motivo: *`# nosec B324: receipt
ids are labels, not a security control`*. Um `# nosec` sozinho, sem regra e sem motivo, silencia
também todo achado futuro naquela linha, e é assim que um real passa.

### Gravidade e confiança

Todo achado traz as duas. **Gravidade** é quão ruim seria se o achado for real; **confiança** é quão
segura a ferramenta está de que ele é. O B201 acima tem gravidade alta com confiança média: o
depurador é perigoso, e a ferramenta não tem como saber se aquela linha roda fora de um notebook.
Nenhum dos dois números é um veredicto. Eles ordenam a leitura, o mais alto dos dois primeiro.
