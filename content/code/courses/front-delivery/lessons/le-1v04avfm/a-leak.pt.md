---
title: Um segredo num commit, e a manhã seguinte
version: 1
---

**Um segredo que chega a um commit vazou, e o conserto é trocá-lo em quem o emitiu.** Apagar a linha,
apagar o arquivo e até reescrever o histórico vêm depois, e nenhum deles é o conserto, porque nenhum
alcança as cópias que já existem: cada clone, cada fork, cada cache de um repositório público, e cada
scanner automático que lê commits novos minutos depois de um push.

## Como ele chega lá

O `.gitignore` do template deixa de fora `*.local`, e é só isso que mantém o `.env.local` fora do
repositório. O `git check-ignore` diz qual regra vale para um caminho:

```
ana@dev:~/planner$ git check-ignore -v .env.local .env
.gitignore:13:*.local	.env.local
```

O `.env.local` é ignorado pela linha 13; o `.env` não é ignorado de jeito nenhum, porque o template
espera que o `.env` guarde valores que todo mundo compartilha. **Um segredo no `.env` vai para o
repositório no próximo `git add .`**, que é exatamente o que acontece aqui:

```
ana@dev:~/planner$ echo 'SUPPORT_TOKEN=tok-demo-not-a-real-secret' > .env
ana@dev:~/planner$ git add .
ana@dev:~/planner$ git commit -qm "Support widget settings"
ana@dev:~/planner$ git show --stat --oneline HEAD
4d59503 Support widget settings
 .env | 1 +
 1 file changed, 1 insertion(+)
```

Aí o erro é percebido, e o arquivo sai do repositório e entra no `.gitignore`:

```
ana@dev:~/planner$ git rm -q --cached .env
ana@dev:~/planner$ echo '.env' >> .gitignore
ana@dev:~/planner$ git commit -qam "Keep .env out of the repository"
ana@dev:~/planner$ git ls-files .env .env.staging
.env.staging
```

O arquivo sumiu do commit mais recente. **O histórico ainda o tem**, e também quem fez fetch no meio
tempo:

```
ana@dev:~/planner$ git log --oneline -p -- .env | head -12
b6d9312 Keep .env out of the repository
diff --git a/.env b/.env
deleted file mode 100644
index 9e2d192..0000000
--- a/.env
+++ /dev/null
@@ -1 +0,0 @@
-SUPPORT_TOKEN=tok-demo-not-a-real-secret
4d59503 Support widget settings
diff --git a/.env b/.env
new file mode 100644
index 0000000..9e2d192
```

## A ordem que funciona

1. **Troque o segredo no serviço que o emitiu**, e revogue o antigo. É o único passo que torna inútil a
   cópia vazada, então vem primeiro, antes de qualquer coisa sobre git, e não é opcional porque o
   repositório era privado, o push foi rápido ou ninguém parece ter notado.
2. **Veja o que o antigo fez** enquanto estava solto: os logs do próprio serviço dizem se alguém o usou.
3. **Depois arrume o repositório.** Tire o arquivo e ignore-o, como acima. Reescrever o histórico para
   removê-lo, com uma ferramenta como o `git filter-repo` e um force-push, vale a pena num repositório
   que outros vão clonar, e não muda nada sobre o segredo, que o passo 1 já resolveu.

O GitHub roda **secret scanning** nos repositórios, e com **push protection** ligado ele recusa um push
que contenha uma chave num formato que ele reconhece, antes de o commit chegar lá. Isso pega os formatos
comuns dos serviços comuns. Não pega um token num formato que ele nunca viu, como o desta seção, então é
uma rede sob a regra, nunca a regra.

## Desfazendo a demonstração

Os dois commits acima nunca foram enviados, então podem sair do seu histórico sem prejudicar ninguém. É
a única situação em que isso é seguro:

```
ana@dev:~/planner$ git reset -q --hard HEAD~2 && rm .env
ana@dev:~/planner$ git log --oneline
4c6079f Declare the variables the planner reads
4ea0d5e A staging mode
567e767 Take the title from VITE_TITLE
f58474d Serve dist/ the way a static host does
833a261 The study planner
ana@dev:~/planner$ git status --short
```

Se tivessem sido enviados, a ordem acima valeria por inteiro, começando pelo passo 1.
