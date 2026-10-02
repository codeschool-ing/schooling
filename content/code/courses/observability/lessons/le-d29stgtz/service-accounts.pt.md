---
title: Uma conta para um robô
version: 1
---

Scripts também falam com o Grafana: uma esteira de deploy que marca cada versão nos painéis, uma
tarefa que faz backup dos painéis, uma ferramenta que cria pastas. **Nenhum deles deveria ter a
senha de administrador.** A resposta do Grafana é uma **conta de serviço** (service account): uma
identidade para um programa, com um papel, e tokens que podem ser revogados um a um. Uma é criada
para a esteira de deploy, com o papel `Editor`, e recebe um token:

```
ana@obs:~/shop$ curl -s -u admin:$(cat .grafana-password) -H 'Content-Type: application/json' -d '{"name": "deploy-bot", "role": "Editor"}' localhost:3000/api/serviceaccounts | jq -c '{id, name, role}'
{"id":2,"name":"deploy-bot","role":"Editor"}
ana@obs:~/shop$ curl -s -u admin:$(cat .grafana-password) -H 'Content-Type: application/json' -d '{"name": "annotations"}' localhost:3000/api/serviceaccounts/2/tokens | jq -r .key > .grafana-token && wc -c < .grafana-token
47
```

O token foi direto para um arquivo, 47 bytes contando a quebra de linha, e nunca para a tela. Com ele, o robô consegue ler
o que um editor lê, e não consegue apagar uma fonte de dados, o que só um administrador pode:

```
ana@obs:~/shop$ curl -s -o /dev/null -w '%{http_code}\n' -H "Authorization: Bearer $(cat .grafana-token)" localhost:3000/api/search
200
ana@obs:~/shop$ curl -s -o /dev/null -w '%{http_code}\n' -H "Authorization: Bearer $(cat .grafana-token)" -X DELETE localhost:3000/api/datasources/uid/prometheus
403
```

**200 para a busca, 403 para o apagar.** Essa recusa é o ponto do exercício: um token que vaza dos
logs de uma esteira consegue anotar e editar painéis, e não consegue remover as fontes de dados de
que todo painel depende. Toda chamada daqui até o fim da aula usa o token em vez da senha, e é esse o
hábito que vale copiar: **a senha de administrador é para configurar, e um token com o menor papel que
funcione é para tudo o que é automático**.
