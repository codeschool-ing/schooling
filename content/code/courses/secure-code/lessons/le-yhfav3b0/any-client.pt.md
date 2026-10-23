---
title: Um formulário é uma sugestão
version: 1
---

Um navegador é um jeito de enviar uma requisição, não o único. **O mesmo `POST` pode vir do `curl`,
de um script Python, de um teste, da integração de outra empresa ou de uma versão do aplicativo
escrita antes de o formulário mudar.** Nenhum deles executa os atributos HTML, porque nenhum deles
lê o HTML.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l03-paths\" aria-label=\"Três jeitos de um cadastro chegar ao servidor da Vereda, e por quais verificações cada um passa. Um paciente no navegador passa pelas verificações do navegador, required, maxlength, type email, antes de a requisição sair. Um script com curl e uma versão antiga do aplicativo enviam a requisição direto ao servidor e não passam por verificação de navegador nenhuma. Os três chegam à mesma rota, então só as verificações do servidor veem toda requisição.\"><defs><marker id=\"l03-paths-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"100.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">paciente, navegador</text><rect x=\"20\" y=\"130\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"100.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">um script com curl</text><rect x=\"20\" y=\"210\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"100.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">um app antigo</text><rect x=\"230\" y=\"30\" width=\"170\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"315.0\" y=\"47.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">verificações do navegador:</text><text x=\"315.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">required, maxlength,</text><text x=\"315.0\" y=\"72.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">type=email</text><path d=\"M180 60 L230 60\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-paths-ah-paper-dim)\"></path><rect x=\"470\" y=\"110\" width=\"140\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"540.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">POST /signup</text><rect x=\"470\" y=\"180\" width=\"230\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"585.0\" y=\"202.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">as verificações do servidor</text><path d=\"M400 60 L440 60 L440 125 L470 125\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-paths-ah-paper-dim)\"></path><path d=\"M180 150 L470 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-paths-ah-paper-dim)\"></path><path d=\"M180 230 L440 230 L440 145 L470 145\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-paths-ah-paper-dim)\"></path><path d=\"M540 154 L540 180\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-paths-ah-paper-dim)\"></path><text x=\"585\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">as únicas que toda requisição atravessa</text></svg>", "caption": "As verificações do navegador ficam num dos caminhos de entrada. As do servidor ficam em todos.", "same": ["required, maxlength,", "type=email"]}
```

A aplicação desta aula é a página de cadastro da Vereda. Crie a pasta e o repositório como antes:

```
(.venv) ana@vm:~/sc$ mkdir signup
(.venv) ana@vm:~/sc$ cd signup
(.venv) ana@vm:~/sc/signup$ git init -b main
Initialized empty Git repository in /home/ana/sc/signup/.git/
```

Esta é a versão em que toda regra mora no HTML. Salve como `app.py`:

```schooling-example
{"language": "python", "file": "app.py", "parts": [{"code": "from flask import Flask, render_template_string, request\n\napp = Flask(__name__)\nPATIENTS = []\n"}, {"code": "PAGE = \"\"\"<form method=\"post\" action=\"/signup\">\n  <label>Name <input name=\"name\" required maxlength=\"60\"></label>\n  <label>E-mail <input name=\"email\" type=\"email\" required maxlength=\"120\"></label>\n  <label>Birth date <input name=\"birth\" type=\"date\" required max=\"2026-11-01\"></label>\n  <button>Sign up</button>\n</form>\"\"\"\n\n", "note": "Toda regra está no HTML: três campos obrigatórios, dois tamanhos, um tipo e-mail, uma data de nascimento máxima. O navegador as aplica antes de enviar qualquer coisa."}, {"code": "@app.get(\"/signup\")\ndef form():\n    return render_template_string(PAGE)\n\n\n@app.post(\"/signup\")\ndef signup():\n    PATIENTS.append(dict(request.form))\n    return \"Welcome\", 201", "note": "O servidor guarda os campos que chegaram, todos eles, porque o formulário já verificou. Essa frase é a falha."}]}
```

Um navegador que abre `http://127.0.0.1:5000/signup` não deixa ninguém enviar esse formulário com o
nome vazio, com 61 caracteres ou com data de nascimento depois de 1º de novembro de 2026. Inicie a
aplicação com `flask --app app run` e, de um segundo terminal, envie um cadastro que o navegador
nunca teria enviado: nome vazio, um endereço sem `@` e uma data de nascimento cinco anos no futuro.

```
(.venv) ana@vm:~/sc/signup$ curl -s -w '\n%{http_code}\n' -d 'name=&email=lucia&birth=2031-01-01' http://127.0.0.1:5000/signup
Welcome
201
```

`Welcome`, e o código de status que o `curl -w` foi instruído a imprimir: 201. **O servidor guardou
os três valores.** O `curl -d` envia os campos do formulário exatamente como um navegador, codificados
do mesmo jeito, para a mesma rota, e o servidor não tem como notar a diferença, porque não há
diferença. Toda regra do HTML foi pulada simplesmente por não usar o HTML.

### As ferramentas do próprio navegador dizem o mesmo

Nem é preciso terminal. As ferramentas de desenvolvedor de todo navegador atual (F12, ou
`Ctrl+Shift+I`) deixam quem está no teclado editar a página: apagar o `required`, mudar o
`maxlength`, e então apertar o botão. O Firefox e o Chrome permitem isso de propósito, porque a
página é do usuário para inspecionar. **Tudo o que o navegador impõe, quem está no navegador pode
desligar**, e é exatamente por isso que a verificação que vale é a do servidor.
