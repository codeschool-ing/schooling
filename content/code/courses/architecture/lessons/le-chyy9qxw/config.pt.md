---
title: III, configuração no ambiente
version: 1
---

**Configuração é tudo o que muda entre implantações do mesmo código**: o endereço do banco, a porta,
credenciais para outros serviços, o nome do bucket para onde vão os arquivos. Não são as rotas, as
regras de negócio nem a lista de produtos; isso é código, e é igual em todo lugar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Uma imagem no meio, os mesmos bytes, implantada em três ambientes: num laptop, em homologação e em produção. Cada ambiente dá ao processo um DATABASE_URL e uma PORT diferentes; a imagem não muda.\"><defs><marker id=\"l4-config-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"210\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"240\" y=\"24\" width=\"240\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">quitanda/catalogue:1.0.0</text><rect x=\"30\" y=\"110\" width=\"204\" height=\"96\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"132\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">laptop</text><text x=\"132\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">DATABASE_URL</text><text x=\"132\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">db:5432</text><path d=\"M360 70 L132 108\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l4-config-ah-amber)\"></path><rect x=\"258\" y=\"110\" width=\"204\" height=\"96\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">homologação</text><text x=\"360\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">DATABASE_URL</text><text x=\"360\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">pg-stg:5432</text><path d=\"M360 70 L360 108\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l4-config-ah-amber)\"></path><rect x=\"486\" y=\"110\" width=\"204\" height=\"96\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"588\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">produção</text><text x=\"588\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">DATABASE_URL</text><text x=\"588\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">pg-prod:5432</text><path d=\"M360 70 L588 108\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l4-config-ah-amber)\"></path></svg>", "caption": "Uma imagem, três ambientes. O que difere entre eles está no ambiente, nunca na imagem, então a imagem que passou nos testes é a imagem que roda.", "same": ["laptop"]}
```

O fator diz que configuração mora em variáveis de ambiente, e o catálogo lê duas delas. O contêiner
rodando as tem:

```
ana@vm:~/lab/twelve$ docker compose exec catalogue printenv DATABASE_URL PORT
postgresql://quitanda:quitanda@db:5432/quitanda
8000
```

O teste útil que o texto dos doze fatores dá é este: **o código poderia ser publicado como código
aberto agora, sem vazar uma única credencial?** Se uma senha está num arquivo versionado, a resposta é
não, e também é não a resposta para "a homologação pode usar outro banco sem mudar código".

## Falhar rápido

Uma configuração que falta deve parar o programa na partida, com uma frase que diz o que falta. O
catálogo faz isso com `DATABASE_URL`. Rode uma vez com a variável vazia:

```
ana@vm:~/lab/twelve$ docker compose run --rm -e DATABASE_URL= catalogue; echo "exit code $?"
 Container twelve-db-1 Running 
 Container twelve-db-1 Waiting 
 Container twelve-db-1 Healthy 
 Container twelve-catalogue-run-e35a295b088c Creating 
 Container twelve-catalogue-run-e35a295b088c Created 
DATABASE_URL is not set: give the catalogue the address of its database

exit code 1
```

**A alternativa é pior de um jeito fácil de não ver.** Um programa que iniciasse mesmo assim, com um
endereço padrão, subiria saudável e falharia na primeira requisição de verdade, talvez uma hora
depois, com um erro de conexão que cita um host que ninguém configurou. Um programa que se recusa a
iniciar falha na implantação, enquanto alguém está olhando.

`PORT` é do outro tipo: tem um padrão sensato, 8000, e o programa o usa quando nada mais é dito. **Dê
um padrão só quando existe um valor certo em quase todo lugar**; um endereço de banco nunca é.

## Variáveis de ambiente não são um cofre de segredos

Variáveis de ambiente podem ser lidas por qualquer coisa que consiga inspecionar o processo: o
`docker inspect` as imprime, e também um relatório de erro que despeja o ambiente. Elas são onde a configuração
é *entregue* ao programa. Onde o segredo *mora* é um gerenciador de segredos, Vault, AWS Secrets
Manager, Google Secret Manager, segredos do Kubernetes, que o injeta na partida, como variável ou como
arquivo, e mantém um registro de quem leu. O programa não precisa mudar para isso, e é esse o motivo de
ler a configuração do ambiente.
