---
title: Chaves no código
version: 1
---

**Uma chave escrita no código-fonte é legível por todo mundo que consegue ler o repositório, em toda
máquina que já o clonou, enquanto existir qualquer cópia. Apagar a linha depois a tira de um arquivo
e de nenhuma das cópias.** É o erro criptográfico mais comum que existe, e aquele por onde a aula 14
prometeu começar.

## Cinco semanas no portal

Em 4 de maio, o Bruno acrescentou ao portal da Vereda a verificação dos webhooks: o HMAC da aula 6,
com a chave que o provedor de pagamentos emitiu. Para fazer funcionar, escreveu a chave no
`settings.py`. Em 10 de junho, depois de uma revisão, trocou-a por uma leitura do ambiente. Estes
comandos criam a mesma história no seu laboratório: os dois commits, com o nome dele e as datas em
que os fez, e a chave de webhook da aula 6 no primeiro. O Git nomeia um commit por um resumo
exatamente dessas coisas, então os seus ganham os mesmos nomes:

```sh
cd ~/lab
export GIT_AUTHOR_NAME="Bruno Reis" GIT_AUTHOR_EMAIL=bruno.reis@vereda.example
export GIT_COMMITTER_NAME="Bruno Reis" GIT_COMMITTER_EMAIL=bruno.reis@vereda.example
git init -q -b main portal
cat > portal/settings.py <<EOF
DATABASE_HOST = "db.vereda.example"
WEBHOOK_KEY = bytes.fromhex("$(cat keys/webhook.hex)")
EOF
git -C portal add settings.py
GIT_AUTHOR_DATE="2026-05-04T10:12:00-03:00" GIT_COMMITTER_DATE="2026-05-04T10:12:00-03:00" \
  git -C portal commit -q -m "Verify the payment provider's webhooks"
cat > portal/settings.py <<'EOF'
import os

DATABASE_HOST = "db.vereda.example"
WEBHOOK_KEY = bytes.fromhex(os.environ["VEREDA_WEBHOOK_KEY"])
EOF
GIT_AUTHOR_DATE="2026-06-10T16:40:00-03:00" GIT_COMMITTER_DATE="2026-06-10T16:40:00-03:00" \
  git -C portal commit -q -am "Read the webhook key from the environment"
unset GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL
```

O arquivo de hoje está limpo:

```
ana@lab:~/lab$ git -C portal log --oneline
d9cfbcd Read the webhook key from the environment
761abf7 Verify the payment provider's webhooks
ana@lab:~/lab$ grep -n WEBHOOK portal/settings.py
4:WEBHOOK_KEY = bytes.fromhex(os.environ["VEREDA_WEBHOOK_KEY"])
```

O histórico, não. A chave está no diff que a acrescentou e no diff que a removeu, e uma busca por 64
dígitos hexadecimais acha os dois:

```
ana@lab:~/lab$ git -C portal log -p | grep -nE '[0-9a-f]{64}'
15:-WEBHOOK_KEY = bytes.fromhex("5c6e1f566813609ed2f6eea08c669f64aa8c3235959b5f59b78b280d94a4111a")
31:+WEBHOOK_KEY = bytes.fromhex("5c6e1f566813609ed2f6eea08c669f64aa8c3235959b5f59b78b280d94a4111a")
```

O `git log -S` lista todo commit que acrescentou ou removeu um certo texto, e é assim que quem revisa
pergunta "desde quando, e até quando":

```
ana@lab:~/lab$ git -C portal log --oneline -S "$(cat keys/webhook.hex)"
d9cfbcd Read the webhook key from the environment
761abf7 Verify the payment provider's webhooks
```

Por cinco semanas, todo clone do portal levou a chave junto: os notebooks de três desenvolvedores, os
runners de CI, o prestador que consertou a página de agendamento e o backup noturno do servidor git.
Todas essas cópias ainda a têm. **Remover a linha não revogou nada.** Reescrever o histórico com
`git filter-repo` limpa as cópias que a Vereda controla e nenhuma das outras.

## A única correção é uma chave nova

Uma chave que chegou a um repositório é tratada como publicada. A resposta é a que a seção 05
descreve: emitir uma chave nova no provedor, implantá-la, revogar a antiga e procurar nos logs do
provedor uso da chave antiga vindo de algum lugar inesperado. O trabalho é o mesmo seja o
repositório público ou privado, porque "privado" só diz quem deveria ter acesso.

## Manter as chaves de fora

A chave pertence ao ambiente onde o código roda, colocada lá por um gerenciador de segredos ou pelo
mecanismo da própria plataforma, nunca ao código que é implantado nele:

```py
import os

WEBHOOK_KEY = bytes.fromhex(os.environ["VEREDA_WEBHOOK_KEY"])
```

Essa linha falha ruidosamente quando a variável não existe, e a falha ruidosa é de propósito.
`os.environ.get("VEREDA_WEBHOOK_KEY", "dev-key")` rodaria, verificaria webhooks com uma chave que de
novo está no código, e não daria sinal nenhum de que algo estava errado.

Duas verificações automáticas pegam o que a revisão deixa passar:

- **Um scanner antes do commit.** Ferramentas como o gitleaks e o TruffleHog rodam como gancho de
  pre-commit e recusam um commit que contenha algo com formato de chave: o cabeçalho PEM de uma chave
  privada, o prefixo de chave de um provedor de nuvem, um texto longo de alta entropia.
- **O mesmo scanner na CI, sobre todo o histórico**, mais a varredura de segredos da própria
  plataforma de hospedagem, onde existir. O GitHub, por exemplo, reconhece o formato de chave de
  muitos provedores e consegue bloquear um push que contenha uma.

A mesma regra vale para todo lugar por onde o código viaja: imagens de contêiner, aplicativos de
celular e JavaScript mandado ao navegador são todos entregues a pessoas que conseguem lê-los. A aula
11 mostrou por que esconder uma chave dentro deles, com Base64 ou um embaralhamento caseiro, não muda
nada. Uma chave que o cliente precisa guardar não é segredo, e o projeto tem de aceitar isso.
