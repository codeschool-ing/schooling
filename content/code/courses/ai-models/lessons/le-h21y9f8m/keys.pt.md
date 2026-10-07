---
title: Uma chave é dinheiro
version: 1
---

Toda API das aulas 6 a 20 pediu a mesma coisa antes de responder: uma chave. **Quem tem a chave
gasta o dinheiro**, e nada na requisição diz quem é. Uma chave não é uma senha que protege os dados
da ana; é um número de cartão que cobra da conta da ana.

A seção 04 da aula 1 pôs as chaves do curso onde um programa as acha e um arquivo de código não: no
ambiente, carregadas do `desk.env`. São valores de mentira, porque o Ollama ignora a chave:

```
ana@desk:~/desk$ grep -E "_KEY|_TOKEN" desk.env
export OPENAI_API_KEY=ollama
export ANTHROPIC_API_KEY=ollama
```

Uma chave de verdade vai no mesmo tipo de lugar, e uma semana de trabalho de verdade deixa chaves
em outros lugares também. Para ver como fica, crie os dois arquivos que uma semana assim pode
deixar: uma anotação colada enquanto depurava, `notes.txt`:

```
2026-09-30 OpenRouter test - works with the key below, move it to the env file later
  sk-or-v1-example-0001
```

e o começo de um widget de atendimento para o site da loja, `page/widget.js`, que classifica a
mensagem do cliente no navegador:

```javascript
// Sort the customer's message in the browser before it is sent to us.
const OPENROUTER_KEY = "sk-or-v1-example-0001";
export async function sortMessage(text) {
  const r = await fetch("https://openrouter.ai/api/v1/chat/completions", {
    method: "POST",
    headers: { Authorization: `Bearer ${OPENROUTER_KEY}`, "Content-Type": "application/json" },
    body: JSON.stringify({ model: "meta-llama/llama-3.3-70b-instruct", messages: [{ role: "user", content: text }] }),
  });
  return (await r.json()).choices[0].message.content;
}
```

A chave neles é inventada, com o formato das do OpenRouter. O `keyscan.py` procura qualquer coisa
com o formato das chaves que este curso usou, e imprime só o começo do que acha:

```python
import pathlib
import re

# the shapes of the keys this course has used: OpenRouter's sk-or-, Anthropic's sk-ant-, OpenAI's sk-,
# Hugging Face's hf_
SHAPES = re.compile(r"\b(sk-or-[\w-]{6,}|sk-ant-[\w-]{6,}|sk-[\w-]{16,}|hf_\w{8,})")
for path in sorted(pathlib.Path(".").rglob("*")):
    if not path.is_file() or ".venv" in path.parts or "node_modules" in path.parts:
        continue
    for n, line in enumerate(path.read_text(errors="ignore").splitlines(), 1):
        for key in SHAPES.findall(line):
            print(f"{path}:{n}: {key[:6]}{'*' * (len(key) - 6)}")
```

```
ana@desk:~/desk$ python keyscan.py
notes.txt:2: sk-or-***************
page/widget.js:2: sk-or-***************
```

Dois achados, e o segundo é o sério. O `page/widget.js` é feito para ser servido a todo visitante do
site da loja: **uma chave numa página é uma chave publicada**, legível por qualquer um que abra as
ferramentas de desenvolvedor do navegador, e gastável de qualquer lugar. O modelo da aula 13 rodava
na página porque não precisava de chave; um modelo atrás de uma API precisa, então a chamada fica
num servidor que a ana controla, e a página fala com ele.

As regras que decorrem disso não custam nada:

- **O ambiente, não o código.** Uma chave num arquivo chega a toda cópia do arquivo: um commit, um
  backup, um trecho colado. Vale rodar a varredura acima antes de todo commit; os scanners de
  segredo dos serviços de código fazem o mesmo no push.
- **Uma chave por programa e por lugar onde ele roda.** Classificação e rascunho, teste e produção,
  cada um com a sua. Uma chave que vaza pode então ser revogada sozinha, e a página de uso do
  provedor diz que programa gastou o quê.
- **Revogue, depois substitua.** Uma chave que apareceu onde não devia é revogada no provedor na
  hora, antes de alguém descobrir se foi usada. Apagar o arquivo não a despublica.
- **Logs imprimem o começo de uma chave, nunca ela inteira.** A varredura mascara o que acha, e o
  relay imprimiu `ollama…` na aula 17 pelo mesmo motivo.
