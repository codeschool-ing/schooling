---
title: Docker Hub, GHCR, ECR, Artifact Registry e ACR
version: 1
---

**Todo registry hospedado fala a mesma API que o da Ana, então `docker push` e `docker pull`
funcionam com todos eles sem mudança.** O que muda é o endereço no nome da imagem e o jeito de fazer
login, e o login é onde cada provedor encaixa o seu próprio sistema de identidade. Nenhum dos logins
abaixo foi executado para este curso, porque o laboratório não tem conta em nenhum desses serviços;
os comandos são os que cada provedor documenta, e a documentação deles é onde conferi-los.

## Os cinco que você vai encontrar

| registry | nome da imagem | como fazer login |
| --- | --- | --- |
| Docker Hub | `docker.io/<user>/<repo>`, ou só `<user>/<repo>` | `docker login`, com uma conta Docker e um token de acesso |
| GitHub Container Registry | `ghcr.io/<owner>/<repo>` | `docker login ghcr.io`, com um token do GitHub que pode escrever pacotes |
| Amazon ECR | `<account>.dkr.ecr.<region>.amazonaws.com/<repo>` | `aws ecr get-login-password` encadeado no `docker login` |
| Google Artifact Registry | `<region>-docker.pkg.dev/<project>/<repo>/<image>` | `gcloud auth configure-docker <region>-docker.pkg.dev` |
| Azure Container Registry | `<name>.azurecr.io/<repo>` | `az acr login --name <name>` |

Por extenso, o login do ECR mostra o formato que a maioria dos registries de nuvem compartilha: uma
senha de vida curta produzida pela ferramenta de linha de comando da própria nuvem e entregue ao
`docker login` pela entrada padrão:

```sh
aws ecr get-login-password --region sa-east-1 \
  | docker login --username AWS --password-stdin 123456789012.dkr.ecr.sa-east-1.amazonaws.com
```

O número de conta ali é o exemplo da documentação. O token dura horas, não meses, então um token
vazado vale pouco, e é esse o motivo do desenho.

**O próprio pipeline de release desta plataforma é um exemplo.** O workflow dele faz login com
`gcloud auth configure-docker` e envia cinco imagens ao Artifact Registry, sob
`us-central1-docker.pkg.dev/…`; a aula 26 escreve um pipeline menor do mesmo formato para o `shelf`.
O antigo Container Registry do Google, `gcr.io`, foi aposentado em 2025 e o conteúdo dele passou ao
Artifact Registry; as imagens distroless que este curso usa continuam sendo baixadas pelos nomes
`gcr.io`.

## Escolhendo um

- **Use o registry perto de onde as imagens rodam.** Baixar da mesma nuvem e região é mais rápido,
  costuma não ter custo de transferência e é autenticado pela identidade que o servidor já tem, então
  nenhuma senha precisa morar nele.
- **Cuidado com os limites do Docker Hub para pulls anônimos.** O próprio laboratório deste curso foi
  recusado com `429 Too Many Requests` nos primeiros pulls, e é por isso que existe o ajuste
  `registry-mirrors` da aula 6. Uma frota de CI baixando as mesmas imagens base o dia inteiro bate na
  mesma parede; fazer login, ou ter um espelho próprio, evita isso.
- **Decida quem pode enviar.** O acesso para baixar pode ser amplo; o acesso para enviar é o poder de
  mudar o que todo servidor roda em seguida. Ele pertence ao pipeline, com um token de vida curta, e
  ao menor número possível de pessoas.
- **Planeje a limpeza.** Registries guardam toda imagem já enviada até alguém mandar apagar, e o
  armazenamento é cobrado. Todo registry hospedado tem regras de retenção, como manter as últimas
  cinquenta tags ou apagar imagens sem tag depois de um mês; configure-as no primeiro dia.
