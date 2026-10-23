---
title: Onde os segredos se escondem
version: 1
---

Um **segredo** é qualquer valor que dá acesso por ser conhecido: a chave com que o Flask assina os
cookies de sessão, a senha de um banco de dados, o token com que um provedor de SMS cobra uma
mensagem, uma chave privada. Quem o tem consegue agir como a aplicação, e nada registra que ele foi
copiado. A defesa é decidir **onde um segredo mora**, e mantê-lo fora de todos os outros lugares.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l16-paths\" aria-label=\"Onde um segredo deve morar e onde não deve. À esquerda, os lugares de onde um segredo vaza: o código, um arquivo de configuração no commit, o histórico do repositório, uma linha de log, uma captura de tela num chamado. À direita, o caminho que um segredo deve fazer: fica num cofre de segredos ou num arquivo de ambiente que o git ignora, chega ao processo em execução como variável de ambiente, e o processo se recusa a iniciar sem ele. Só o processo o lê.\"><defs><marker id=\"l16-paths-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"170\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">de onde segredos vazam</text><rect x=\"20\" y=\"40\" width=\"300\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"170.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">o código</text><rect x=\"20\" y=\"86\" width=\"300\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"170.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">um arquivo de configuração no commit</text><rect x=\"20\" y=\"132\" width=\"300\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"170.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">o histórico do repositório</text><rect x=\"20\" y=\"178\" width=\"300\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"170.0\" y=\"196.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">uma linha de log</text><rect x=\"20\" y=\"224\" width=\"300\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"170.0\" y=\"242.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">uma captura de tela num chamado</text><text x=\"540\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">onde um segredo deve ficar</text><rect x=\"400\" y=\"40\" width=\"280\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"540.0\" y=\"58.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">cofre de segredos, ou .env</text><text x=\"540.0\" y=\"71.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">(ignorado pelo git)</text><rect x=\"400\" y=\"120\" width=\"280\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"540.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">variável de ambiente</text><rect x=\"400\" y=\"190\" width=\"280\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"540.0\" y=\"208.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o processo</text><text x=\"540.0\" y=\"221.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">se recusa a iniciar sem ele</text><path d=\"M540 90 L540 120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-paths-ah-paper-dim)\"></path><path d=\"M540 160 L540 190\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-paths-ah-paper-dim)\"></path></svg>", "caption": "Um segredo chega ao processo pelo ambiente, e nada que é compartilhado ou guardado o contém."}
```

Os lugares da esquerda têm uma propriedade em comum: **são copiados, guardados e compartilhados por
natureza.** O código vai para um serviço de hospedagem e é clonado em notebooks. O histórico de um
repositório guarda toda versão de todo arquivo enquanto o repositório existir. Logs são enviados a um
serviço que várias pessoas leem. Uma captura de tela num chamado é vista por todos no chamado. Um
segredo escrito em qualquer um deles foi entregue a todos que um dia vão lê-lo.

### A versão do portal

A pasta desta aula é `~/sc/secrets`:

```
(.venv) ana@vm:~/sc$ mkdir secrets
(.venv) ana@vm:~/sc$ cd secrets
(.venv) ana@vm:~/sc/secrets$ git init -b main
Initialized empty Git repository in /home/ana/sc/secrets/.git/
```

Eis a parte do portal que manda lembretes por SMS, como foi escrita primeiro, com a chave do
provedor digitada ao lado da chave de sessão da aula 18. A chave aqui é inventada e não abre nada.
Salve como `app.py`:

```python
# app.py
from flask import Flask

app = Flask(__name__)
app.secret_key = "vereda-dev"
SMS_API_KEY = "sms_live_4f9a1c7e2b8d6a3f"


@app.get("/health")
def health():
    return {"sms": bool(SMS_API_KEY)}
```

Tudo funciona. O worker de lembretes consegue mandar mensagens e as sessões são assinadas. E no dia
em que este arquivo vai para o repositório remoto, os dois segredos passam a ser de todos que leem o
repositório, o que numa empresa do tamanho da Vereda costuma incluir um ou dois prestadores de anos
atrás.
