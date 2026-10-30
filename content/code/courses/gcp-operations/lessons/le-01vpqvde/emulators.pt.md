---
title: O que responde no seu computador, e o que não responde
version: 1
---

**Nada no seu computador responde como o plano de controle do Google Cloud.** Para a AWS existe um
programa de código aberto que imita boa parte da API; para o Google Cloud não existe nada do tipo. O
Google publica emuladores para um punhado de serviços de dados, a comunidade imita o Cloud Storage, e
é só: nenhum projeto, nenhum IAM, nenhuma rede, nenhum build, nenhum monitoramento responde em
`localhost`. Então este curso faz três coisas diferentes, e diz a você toda vez qual delas está fazendo.

1. **Roda a coisa de verdade onde a coisa de verdade roda localmente.** Um passo de build é um
   contêiner, e o Docker roda contêineres. O Terraform calcula um plano no seu computador. Um
   OpenTelemetry Collector é um programa que você pode iniciar. O código de uma Cloud Function roda
   sob o Functions Framework do Google. Isso é praticado, e cada transcrição disso é real.
2. **Usa um emulador onde existe um.** O Pub/Sub é o emulador do próprio Google; o Cloud Storage é o
   `fake-gcs-server`. Os dois guardam o que recebem e respondem como a API, e nenhum aplica permissão,
   cobra qualquer coisa ou guarda qualquer coisa depois de parar.
3. **Ensina o resto pela documentação do Google, e marca como não executado.** Um alerta que dispara,
   uma regra de WAF que bloqueia, um perímetro que recusa: nada disso acontece sem uma conta. Esses
   trechos não têm transcrição nem saída inventada, e dizem isso.

## Onde a linha cai, lição por lição

| lições | o que roda no seu computador | o que não roda, e é ensinado pela documentação |
|---|---|---|
| 1 a 4: build e entrega | os passos do build como contêineres; um registro local; renderizar um release; assinar e verificar uma imagem | um gatilho, o próprio Cloud Build, um release e sua promoção, a verificação de admissão |
| 5 a 7: Terraform | o provider google, seu plano, buckets no `fake-gcs-server`, o estado remoto e sua trava | criar qualquer coisa que não seja um bucket; Config Connector; Infrastructure Manager |
| 8 a 12: observabilidade | logs estruturados que o seu programa escreve; um OpenTelemetry Collector recebendo traces; planos de painéis, sinks e métricas | Cloud Monitoring, Cloud Logging, Error Reporting, Trace e Profiler recebendo qualquer coisa disso |
| 13 a 15: SLOs, alertas, incidentes | a aritmética de orçamentos de erro e taxas de queima; planos das políticas | um alerta sendo avaliado, um chamado sendo enviado |
| 16 a 20: segurança | planos das políticas; criptografia de envelope com uma chave no seu disco | Cloud Armor, Secret Manager, Cloud KMS, VPC Service Controls e Security Command Center aplicando ou achando qualquer coisa |
| 21 a 25: custo | uma notificação de orçamento levada pelo emulador de Pub/Sub até uma função; linhas de faturamento consultadas com SQLite | uma fatura, um orçamento, uma recomendação |

**Leia os trechos marcados com a mesma seriedade das transcrições.** Um plano que o Terraform imprimiu
prova que a configuração está bem formada e que o provider conhece cada argumento dela. Não prova nada
sobre o Google aceitá-la, sobre sua conta poder criá-la, ou sobre quanto custa.

## Preços

Os emuladores não conhecem preço nenhum. Cada custo deste curso é lido das páginas públicas de preço
do Google para o serviço, com a data da leitura e a região para a qual a página o dá, e a última seção
da lição 1 mostra como. Um preço é o preço de lista naquela data: desconto, crédito ou imposto não
estão nele, e a lição 21 é sobre os descontos.

## Uma conta de verdade, se você quiser uma

Nada neste curso precisa de uma conta do Google Cloud, e nada nele fica mais fácil com uma. **Se você
abrir uma mesmo assim**, a lição 1 de `gcp-foundations` tem a seção sobre fazer isso com segurança, e a
ordem é a parte a lembrar: proteja a conta com um segundo fator, depois crie um orçamento com alerta,
antes de qualquer outra coisa. O período de teste gratuito e o nível gratuito são uma possibilidade de
conta pequena, nunca uma promessa: o que cobrem muda, e um recurso esquecido é cobrado quer você
quisesse mantê-lo, quer não. Esses passos não podem ser gravados sem uma conta, então não foram
executados para este curso e nenhuma transcrição deles aparece.

Duas regras valem de qualquer jeito. **Nunca ponha uma chave real de conta de serviço num arquivo que
este curso manda você criar**, e nunca cole uma numa pergunta ou num fórum. E os comandos destas lições
foram escritos para os emuladores: apontados para um projeto de verdade, vários deles criam coisas que
custam dinheiro por hora.
