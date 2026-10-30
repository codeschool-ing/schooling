---
title: Gatilhos e substituições
version: 1
---

**Um gatilho é a regra que inicia um build, e uma substituição é como o build descobre o que o
iniciou.** O `cloudbuild.yaml` da seção anterior diz o que fazer; não diz nada sobre quando. Um
gatilho liga uma origem (um repositório, um tópico do Pub/Sub, um webhook, ou uma pessoa apertando um
botão) a um arquivo de build, e quando a origem muda, o Cloud Build lê o arquivo naquele commit e o
executa. **Nada desta seção roda no seu computador**: gatilhos vivem no Cloud Build, e nada os imita.
Ela é ensinada pela documentação do Google, e os comandos dela não foram executados.

## Qual evento inicia um build

Um gatilho ligado a um repositório do GitHub pode disparar com três tipos de evento:

| evento | o que casa | para que a loja o usa |
|---|---|---|
| push num branch | uma expressão regular sobre o nome do branch, como `^main$` | todo merge em `main` constrói uma imagem |
| push de uma tag | uma expressão regular sobre a tag, como `^v[0-9]+\.[0-9]+\.[0-9]+$` | uma tag de release constrói a imagem que vai para produção |
| pull request | o branch base que o pull request tem como alvo | os testes rodam antes de alguém revisar |

Mais dois campos decidem se um push que casa faz build mesmo. **`includedFiles` e `ignoredFiles`** são
globs sobre os caminhos que um commit mudou: um gatilho com `includedFiles: ["api/**"]` ignora um commit
que só mexeu na documentação. Deixá-los de fora faz build a cada commit, o que é seguro e custa minutos
de build; errá-los significa uma mudança em `api/` que nunca é construída, e essa é a falha cara,
porque nada a relata.

Para um pull request, o gatilho também pode exigir um comentário, `/gcbrun`, de um colaborador antes de
fazer o build. **Um pull request vindo de um fork roda código que um estranho escreveu, com a conta de
serviço do gatilho**, e esse comentário é a linha entre "os testes rodam" e "qualquer um pode rodar
qualquer coisa como a nossa conta de build".

O gatilho da loja, como o `gcloud` o cria para um repositório já ligado ao Cloud Build:

```sh
gcloud builds triggers create github \
  --name=shop-api-main \
  --region=southamerica-east1 \
  --repository=projects/planner-dev/locations/southamerica-east1/connections/github/repositories/shop \
  --branch-pattern='^main$' \
  --included-files='api/**,cloudbuild.yaml' \
  --build-config=cloudbuild.yaml \
  --service-account=projects/planner-dev/serviceAccounts/shop-build@planner-dev.iam.gserviceaccount.com
```

Ele não foi executado: os emuladores não têm Cloud Build. `cloudbuild.yaml` está em `--included-files`
porque uma mudança no próprio build deve ser construída.

## Substituições

O arquivo de build da seção anterior escreveu três nomes com cifrão. Eles são trocados antes de o build
começar, e vêm em dois tipos.

**Substituições embutidas** são definidas pelo Cloud Build a partir do evento: `$PROJECT_ID` e
`$BUILD_ID` sempre, e a partir de um gatilho de repositório `$COMMIT_SHA`, `$SHORT_SHA` (os sete
primeiros caracteres dele), `$BRANCH_NAME`, `$TAG_NAME` e `$REPO_NAME`. Um build iniciado à mão com
`gcloud builds submit` não tem commit, então `$SHORT_SHA` fica vazio ali; marcar uma imagem com ele
produziria o nome `api:`, que o registro recusa.

**Substituições definidas pelo usuário** começam com sublinhado, como `_REGION`. O arquivo dá um valor
padrão em `substitutions`, e um gatilho pode sobrescrevê-lo, que é como um arquivo de build serve a dois
gatilhos: `_REGION=southamerica-east1` para um, outra região para o outro.

Dois detalhes são onde os builds quebram:

- **Um cifrão destinado ao shell se escreve `$$`.** Em `args: ["-c", "echo $$HOME"]` o shell do passo
  recebe `$HOME`. Escrito `$HOME`, o Cloud Build tenta substituí-lo, não acha essa substituição e recusa
  o build.
- **Uma substituição desconhecida é erro, a não ser que você diga o contrário.** Um gatilho que passa
  `_REGOIN` com um erro de digitação faz o build falhar em vez de ignorá-lo, e esse é o padrão que você
  quer. `options.substitutionOption: ALLOW_LOOSE` desliga o erro, e com ele a única verificação do
  erro de digitação.

## A conta de serviço, de novo

Um gatilho roda o build com a conta de serviço que ele nomeia, e é essa conta que decide o que o build
pode tocar: enviar para um repositório do Artifact Registry, escrever logs, e nada mais no build da
loja. **Um build é código do repositório, rodando com as permissões da conta**, então quem pode fazer
merge em `main` pode fazer tudo o que aquela conta pode. Esse é o motivo de a conta ser pequena e o
motivo de `gcp-foundations` dedicar a lição 8 a contas de serviço.
