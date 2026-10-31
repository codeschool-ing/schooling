---
title: Infrastructure Manager, o Terraform rodado pelo Google
version: 1
---

**O Infrastructure Manager roda o seu Terraform por você, dentro do Google Cloud, e guarda o estado ele
mesmo.** A configuração é o mesmo HCL da lição 5, sem bloco de provider apontando para emulador; o que
muda é quem roda o `terraform apply`, onde o estado vive e quem pode lê-lo. Ele responde às perguntas da
lição 6 tirando-as do caminho: o estado fica num bucket que o Google gerencia para o deployment, travado
pelo serviço e versionado a cada revisão. Nada disso foi executado aqui: não há projeto onde executar.

## Um deployment e suas revisões

Um **deployment** é uma configuração do Terraform gerenciada pelo Infrastructure Manager. Cada apply cria
uma **revisão**, que registra a configuração aplicada, o resultado e o estado depois dele. O da loja,
criado a partir de um diretório num repositório Git:

```sh
gcloud infra-manager deployments apply projects/planner-dev/locations/southamerica-east1/deployments/shop \
  --service-account=projects/planner-dev/serviceAccounts/shop-infra@planner-dev.iam.gserviceaccount.com \
  --git-source-repo=https://github.com/example/shop-infra \
  --git-source-directory=tf/shop \
  --git-source-ref=main
```

Uma **prévia** (preview) é o plano: `gcloud infra-manager previews create` roda o `terraform plan` no mesmo
ambiente e guarda o resultado, então quem revisa lê o plano que o Infrastructure Manager vai aplicar, e não
um calculado no laptop de alguém com outras credenciais.

A conta de serviço é a identidade com que o deployment age, e a única: as credenciais do laptop de ninguém
entram depois que o deployment existe. É o mesmo movimento da personificação da lição 5, tornado
permanente.

## O que ele não faz

- **Não corrige drift.** Entre applies, uma mudança feita à mão fica até a próxima revisão, exatamente como
  com o Terraform rodado em qualquer outro lugar. O Config Connector é a opção que corrige.
- **Não muda o que o Terraform consegue fazer.** Um recurso que o provider não consegue importar (lição 6)
  continua impossível de importar; uma configuração que destruiria um bucket continua destruindo. O plano
  continua sendo o que se lê.
- **Fixa uma versão do Terraform** por deployment, escolhida entre as versões que o Google suporta, e não a
  mais nova que existir.

## Sem preço aqui

O Infrastructure Manager tem preço próprio, pelo tempo em que o Terraform roda e pelo estado que guarda. A
página de preços dele não pôde ser lida a partir da máquina em que este curso foi escrito, então nenhum
número é citado; leia a página atual antes de escolhê-lo pelo custo.
