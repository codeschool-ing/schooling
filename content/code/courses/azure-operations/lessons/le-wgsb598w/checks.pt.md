---
title: Aprovações e verificações, onde o deploy chega
version: 1
---

**Uma verificação fica presa à coisa que recebe o deploy, não à esteira.** No Azure Pipelines isso é o
ambiente, ou a service connection, ou o pool de agentes. Ponha uma aprovação numa esteira e a equipe dona da
esteira pode apagá-la num pull request; ponha-a em `shop-production` e toda esteira que mira aquele ambiente,
escrita hoje ou no ano que vem, espera por ela. É o mesmo argumento que a lição 1 fez para templates
obrigatórios: a proteção pertence ao lugar onde o deploy chega.

O ambiente de produção da loja tem cinco. Elas são configuradas na interface web do Azure DevOps ou na API
REST dele, e **não foram executadas** aqui, porque o laboratório não tem organização do Azure DevOps. Escritas
como lista, são:

```yaml
# what the environment shop-production carries, as checks
approvals:          # one of the two on-call engineers, never the person who queued the run
business-hours:     # Monday to Friday, 09:00 to 17:00, America/Sao_Paulo
query-alerts:       # Azure Monitor: no fired alert on rg-shop in the last 15 minutes
required-template:  # the run extends secure-build.yml@platform
exclusive-lock:     # one deployment at a time; a newer run supersedes a waiting one
```

Quando um job de deployment chega ao ambiente, **todas as verificações são avaliadas, e o job só começa
quando cada uma passa**. Elas rodam em paralelo, e uma verificação que falha ou estoura o tempo faz o estágio
falhar.

**Aprovação** diz quem pode aprovar, e quantos. A opção útil é a que recusa quem enfileirou a execução: uma
aprovação que o autor concede a si mesmo é uma espera, e não um segundo par de olhos. Uma aprovação aguarda
um tempo configurável e depois falha, que é a direção certa; um deploy que ninguém aprovou não deveria
acontecer sozinho às três da manhã.

**Horário comercial** segura o job até uma janela abrir. Ela codifica a regra de uma equipe de que ninguém
implanta quando não há ninguém para observar, e não custa nada manter.

**Consultar alertas do Azure Monitor** é um gate: pergunta se algum alerta dos tipos que você indicar disparou
num escopo, e só passa se nenhum disparou. A loja o usa para um deploy não começar enquanto a produção já está
em apuros, quando uma versão nova deixaria o incidente mais difícil de ler. Os alertas em si são assunto da
lição 12. **Invocar Azure Function** e **invocar API REST** são a forma geral: um gate que chama um endpoint
seu e passa conforme a resposta, reavaliado a intervalos até passar ou estourar o tempo.

**Lock exclusivo** deixa uma execução de cada vez entrar no ambiente. Dois deploys correndo um contra o outro
para o mesmo slot é uma falha que ninguém projeta, e que ninguém percebe até o mais antigo vencer.
