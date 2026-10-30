---
title: Dry run primeiro, e lendo as violações
version: 1
---

**Um perímetro ligado sem dry run quebra algo de que ninguém se lembrava.** Um job noturno em outro projeto que lê as
exportações, uma ferramenta de painel chamando o BigQuery de fora, o laptop de alguém do suporte: cada um é uma
requisição legítima que o perímetro recusaria, e cada um é descoberto pelas pessoas que ele quebra. A configuração da
loja usa `use_explicit_dry_run_spec = true` e põe tudo em `spec`, que é a configuração de **dry run**: o Cloud Audit
Logs registra cada requisição que o perímetro *recusaria*, e nada é recusado. Esta seção vem da documentação do
Google; nada foi executado.

## Lendo as recusas que teriam acontecido

Uma violação de dry run é uma entrada de log de auditoria, achada no Cloud Logging com um filtro do tipo da lição 9:

```localised
protoPayload.metadata.@type="type.googleapis.com/google.cloud.audit.VpcServiceControlAuditMetadata"
protoPayload.metadata.dryRun=true
```

Cada entrada nomeia o perímetro, o serviço e o método, quem chamou e de onde veio a requisição, e um
`violationReason`. Uma semana de dry run dá uma lista para ler com três colunas em mente: **quem, de onde, fazendo
o quê**. Cada linha é uma de três coisas:

- **uma requisição legítima**, que vira um nível de acesso (uma faixa de endereços conhecida) ou uma regra de entrada
  ou de saída (uma identidade, um serviço, um método);
- **uma requisição que ninguém sabe explicar**, que é o perímetro fazendo o trabalho dele mais cedo, e um incidente
  (lição 15);
- **ruído de uma ferramenta que sonda tudo**, que se corrige na ferramenta.

Quando uma semana passa só com o segundo e o terceiro tipos, a configuração vai de `spec` para `status`, a
configuração aplicada, e as mesmas entradas começam a aparecer sem `dryRun=true`, agora como recusas.

## O perímetro num incidente

Uma recusa aplicada devolve `403` com um erro que nomeia o VPC Service Controls e um id único. Alguém cujo job quebra
depois da aplicação vê esse id; buscar o id nos logs de auditoria dá a regra exata que recusou a requisição. **Esse id
é a primeira coisa a pedir** quando alguém relata "permissão negada mas eu tenho o papel": ele diz se foi o IAM ou o
perímetro que recusou, que são duas conversas diferentes.

## O que custa e o que exige

O VPC Service Controls em si não tem cobrança. O que ele custa é atenção: toda integração nova que cruza a linha
precisa de uma regra, escrita e revisada, e um time que acrescenta regras sem ler os logs de dry run acaba com um
perímetro cheio de buracos, que é um perímetro só no nome. **Para a loja, as exportações de pedidos são os únicos
dados que valem o custo**: dados de pagamento não são guardados, e a lista de preços é pública. Traçar a linha em
volta de tudo significaria manter regras para tudo; traçá-la em volta do único projeto que guarda dados pessoais
mantém a lista curta o bastante para ser lida.
