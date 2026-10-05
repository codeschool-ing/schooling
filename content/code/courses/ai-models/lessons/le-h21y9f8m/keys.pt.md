---
title: Uma chave é dinheiro
version: 1
---

Toda API das aulas 6 a 20 pediu a mesma coisa antes de responder: uma chave. **Quem tem a chave
gasta o dinheiro**, e nada na requisição diz quem é. Uma chave não é uma senha que protege os dados
da ana; é um número de cartão que cobra da conta dela.

O lab guarda as chaves onde um programa as acha e um arquivo não: no ambiente, carregadas de um
arquivo fora do projeto. Os nomes delas, sem os valores:

```
ana@desk:~/desk$ grep -oE "^[A-Z_]+(KEY|TOKEN)=" /etc/aimodels.env
ANTHROPIC_API_KEY=
OPENAI_API_KEY=
GEMINI_API_KEY=
MISTRAL_API_KEY=
CO_API_KEY=
HF_TOKEN=
OPENROUTER_API_KEY=
```

Uma semana de trabalho de verdade deixa chaves em outros lugares. A ana colou uma numa anotação
enquanto depurava, e começou um widget de atendimento para o site da loja que classifica a mensagem
do cliente no navegador. O `lab/keyscan.py` procura qualquer coisa com o formato das chaves que este
curso usou:

```python
import pathlib
import re

# the shapes of the keys this course has used: OpenRouter's sk-or-, Hugging Face's hf_, the lab's own
SHAPES = re.compile(r"\b(sk-or-[\w-]{6,}|sk-[\w-]{16,}|hf_\w{8,}|lab-[a-z]+-key-\d+)")
for path in sorted(pathlib.Path(".").rglob("*")):
    if not path.is_file() or "node_modules" in path.parts:
        continue
    for n, line in enumerate(path.read_text(errors="ignore").splitlines(), 1):
        for key in SHAPES.findall(line):
            print(f"{path}:{n}: {key[:6]}{'*' * (len(key) - 6)}")
```

```
ana@desk:~/desk$ python lab/keyscan.py
notes.txt:2: sk-or-************
page/widget.js:2: sk-or-************
```

Dois achados, e o segundo é o sério. O `page/widget.js` é feito para ser servido a todo visitante do
site da loja: **uma chave numa página é uma chave publicada**, legível por qualquer um que abra as
ferramentas de desenvolvedor do navegador, e gastável de qualquer lugar. O modelo da aula 13 rodava
na página porque não precisava de chave; um modelo atrás de uma API precisa, então a chamada fica num
servidor que a ana controla, e a página fala com ele.

As regras que decorrem disso não custam nada:

- **O ambiente, não o código.** Uma chave num arquivo chega a toda cópia do arquivo: um commit, um
  backup, um trecho colado. Vale rodar a varredura acima antes de todo commit; os scanners de segredo
  dos serviços de código fazem o mesmo no push.
- **Uma chave por programa e por lugar onde ele roda.** Classificação e rascunho, teste e produção,
  cada um com a sua. Uma chave que vaza pode então ser revogada sozinha, e a página de uso do
  provedor diz que programa gastou o quê.
- **Revogue, depois substitua.** Uma chave que apareceu onde não devia é revogada no provedor na
  hora, antes de alguém descobrir se foi usada. Apagar o arquivo não a despublica.
- **Logs imprimem o começo de uma chave, nunca ela inteira.** A varredura mascara o que acha, e o
  `wire` do lab imprimiu `lab-anthropi…` na aula 17 pelo mesmo motivo.
