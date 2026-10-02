---
title: O que sai da sua máquina
version: 1
---

Toda requisição que um assistente faz leva alguns dos seus arquivos para o computador de outra
pessoa. É assim que funciona, e para a maior parte do código está tudo bem: a sua empresa tem um
acordo com o provedor, ou o código é seu. O problema é o arquivo que ninguém quis mandar. **Um
segredo que chega a um provedor de modelos saiu do seu controle**, e agora está num registro de
requisições que você não pode ler nem apagar.

## O que o `.gitignore` não faz

O projeto da ana tem os dois lugares onde um segredo costuma se esconder: um arquivo `.env` com um
token, que o git ignora, e um `settings.py` com uma chave digitada no código, que é um erro, mas um
erro comum. Os dois valores são do laboratório e não abrem nada.

```
ana@dev:~/shop$ git status --short --ignored
 M shop/cart.py
?? .gitignore
?? settings.py
!! .env
!! lab/
```

`!! .env` quer dizer que o git ignora o arquivo. **O editor não liga.** Um arquivo ignorado
continua sendo um arquivo no disco, e uma aba é uma aba. A ana faz uma pergunta com os dois
abertos:

```
ana@dev:~/shop$ assist ask "Why might a payment fail?" --open shop/cart.py .env settings.py
context sent (384 of 3000 tokens):
    332  shop/cart.py
     52  settings.py
  refused .env: it holds something shaped like a secret
---
Nothing in the files shown takes a payment: shop/cart.py computes the total and settings.py only holds a key for the payment service. A payment that fails is failing in code that is not in this context. Look at whatever reads PAYMENTS_KEY.
```

O `assist` recusou o `.env`, porque o conteúdo casou com o padrão de um segredo, e mandou o
`settings.py`, que não casou. A chave foi junto, e o registro do labllm a tem:

```
ana@dev:~/shop$ grep -c pk_lab_4f9a8c7e1d2b3a6f /var/log/labllm/requests.jsonl
1
```

**Uma checagem por padrão é uma rede com furos.** O `assist` procura `token`, `secret`,
`password` ou `api_key` seguidos de um valor longo. `PAYMENTS_KEY = "pk_lab_…"` é um segredo em
qualquer leitura, e passou porque o nome dele não está na lista. Ferramentas reais têm padrões
melhores e ainda deixam coisas passar, porque um segredo é um fato sobre um valor e um padrão só
vê a forma dele.

## Uma lista de exclusão

A segunda defesa é uma lista de caminhos que o assistente nunca deve ler. Os assistentes reais dão
nomes diferentes a ela (uma configuração, ou um arquivo na raiz do projeto), e ela faz o mesmo
trabalho do `.assistignore` do `assist`:

```
ana@dev:~/shop$ printf "settings.py\n*.pem\nsecrets/\n" > .assistignore
ana@dev:~/shop$ assist ask "Why might a payment fail?" --open shop/cart.py .env settings.py 2>&1 >/dev/null
context sent (332 of 3000 tokens):
    332  shop/cart.py
  refused .env: it holds something shaped like a secret
  skipped settings.py: listed in .assistignore
---
```

`skipped settings.py: listed in .assistignore`. **A lista é escrita por uma pessoa que sabe onde
estão os segredos**, e é por isso que funciona onde um padrão não funciona, e por isso só funciona
para os lugares em que alguém pensou.

## As regras que protegem de verdade

- **Mantenha segredos fora dos arquivos que o editor abre.** Variáveis de ambiente, um gerenciador
  de segredos, um arquivo fora do projeto. A chave no `settings.py` foi o erro; o assistente só o
  tornou visível. A aula 10 trata a chave do próprio provedor do mesmo jeito.
- **Exclua o que você sabe nomear**: `.env`, certificados e chaves, o diretório onde ficam as
  credenciais. Faça commit da lista de exclusão, para ela proteger todo mundo que clonar o
  projeto.
- **Saiba o que a sua organização permite.** Algumas empresas proíbem mandar o código delas a um
  terceiro, algumas só permitem uma ferramenta aprovada com um contrato que diz que o código não é
  guardado nem usado para treino. Essa é uma pergunta de política com uma resposta real, e é
  respondida antes de você instalar a extensão, não depois.
- **Se um segredo saiu, troque-o.** Não há como chamar uma requisição de volta. Revogue a chave,
  emita uma nova, e trate a antiga como pública.
