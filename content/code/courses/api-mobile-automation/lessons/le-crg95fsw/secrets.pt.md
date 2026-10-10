---
title: Onde segredos moram, e os lugares por onde vazam
version: 1
---

**Um segredo pertence ao ambiente do processo que o usa, e a nenhum lugar que seja copiado: nem ao
código, nem ao repositório, nem a um log.** Todo segredo desta lição até aqui esteve à vista, e de
propósito. `ci-secret`, `lab-only-staff-key` e o segredo de assinatura `lab-only-secret` estão
escritos no `boxoffice.mjs` como valores padrão, para que o laboratório funcione no momento em que
você o inicia. Num servidor de verdade, seriam a primeira coisa que um atacante tentaria.

## O segredo de assinatura, vindo do ambiente

O boxoffice lê `TOKEN_SECRET` e `STAFF_KEY` do ambiente e só recorre aos valores do laboratório
quando eles faltam. Crie um de verdade: 32 bytes aleatórios em base64url, gravados num arquivo
chamado `.env` sem nunca aparecer na tela:

```
ana@laptop:~/boxoffice$ echo "TOKEN_SECRET=$(node -e 'console.log(require("crypto").randomBytes(32).toString("base64url"))')" > .env
ana@laptop:~/boxoffice$ wc -c .env
57 .env
```

O `wc -c` confirma que o arquivo tem alguma coisa, 57 bytes, sem imprimi-la. O Node lê um arquivo
assim sozinho quando é iniciado com `--env-file`. Pare o boxoffice no segundo terminal e inicie-o
assim:

```
ana@laptop:~/boxoffice$ node --env-file=.env boxoffice.mjs
boxoffice listening on http://localhost:8080
```

Todo token assinado com o segredo antigo agora não vale nada. O `TOKEN` buscado antes:

```
ana@laptop:~/boxoffice$ curl -si localhost:8080/v1/orders/ord-1001 -H "authorization: Bearer $TOKEN" | grep -iE '^HTTP|^www'
HTTP/1.1 401 Unauthorized
www-authenticate: Bearer error="invalid_token", error_description="bad signature"
```

`bad signature`, a mesma recusa que um token editado recebeu na seção 04. Este também é um teste que
vale manter: **um servidor iniciado com o próprio segredo recusa tokens assinados com o padrão**. Uma
implantação que esqueceu de definir `TOKEN_SECRET` aceitaria um token que qualquer um consegue
fazer a partir do código-fonte, e esta requisição é como você descobre.

O resto do curso inicia o boxoffice com um `node boxoffice.mjs` simples e os valores do laboratório,
porque as transcrições dependem deles. Mantenha o `.env` pelo hábito, e pelo dia em que você testar
um servidor que não é seu.

## Fora do repositório

Um arquivo de segredos num diretório de projeto está a um `git add .` de ser publicado. O git pula os
arquivos nomeados em `.gitignore`, então o projeto ganha um. Abra seu editor, escreva estas duas
linhas e salve como `.gitignore`:

```
# Secrets live in .env, on this machine only.
.env
```

Depois transforme o projeto num repositório git, se ele ainda não for um; o pipeline da lição 6
pressupõe um. `git init` o cria, e `git status --short` lista o que o git ofereceria para commit:

```
ana@laptop:~/boxoffice$ git init -q
ana@laptop:~/boxoffice$ git status --short
?? .gitignore
?? boxoffice.mjs
?? openapi.yaml
```

Três arquivos, e o `.env` não está entre eles. **Confira isso antes do primeiro commit, não
depois**: um segredo que chegou a um repositório precisa ser tratado como vazado mesmo que o commit
seja removido, porque todo clone feito nesse meio-tempo ainda o tem. A correção, então, é trocar o
segredo, não reescrever o histórico.

## Fora do log

O log de um pipeline é lido por todo mundo que vê o projeto, e ele é guardado. O jeito mais fácil
de pôr um token nele é pedir ao shell que se explique. `bash -x` imprime cada comando antes de
rodá-lo, com as variáveis já substituídas, e pipelines o ligam para deixar falhas mais fáceis de ler:

```
ana@laptop:~/boxoffice$ bash -xc 'curl -s -o /dev/null localhost:8080/v1/orders/ord-1001 -H "authorization: Bearer $TOKEN"'
+ curl -s -o /dev/null localhost:8080/v1/orders/ord-1001 -H 'authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJjaS10ZXN0cyIsInNjb3BlIjoib3JkZXJzOnJlYWQgb3JkZXJzOndyaXRlIiwiaWF0IjoxNzkxNjYxMzg3LCJleHAiOjE3OTE2NjIyODd9.ZYNygARAi8VHK-A59GydT_uT2q6wG8ebDb8D67_sJQU'
```

O token inteiro, às claras, numa linha que parece depuração inofensiva. A lição 6 roda requisições
no GitHub Actions, que esconde os valores que você registra como segredos onde quer que apareçam
num log; **um token que o job buscou sozinho não está registrado, então nada o esconde**, a menos que
o passo o marque antes com `::add-mask::`. Isso não foi rodado para este curso, e a lição 6 mostra o
workflow. O que quem testa pode conferir em qualquer lugar é o próprio log: procure na saída de uma
execução por `Bearer ` e pelo começo de um JWT, `eyJ`, e trate qualquer um dos dois como defeito do
pipeline.

A mesma regra vale para relatórios de teste. Uma ferramenta que guarda toda requisição e resposta de
um teste que falhou guarda o cabeçalho `Authorization` junto, então um relatório anexado a um ticket
pode levar um token válido. Os reporters da lição 6 são o primeiro lugar a olhar.
