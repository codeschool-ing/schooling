---
title: O mesmo registro no Azure e no Google Cloud
version: 1
---

**Todo provedor grande registra por padrão as chamadas à sua API de gerenciamento e deixa desligado
por padrão o registro da leitura de dados.** Os nomes diferem, e os padrões também nas beiradas, e as
beiradas são onde uma investigação fica sem registros. A aula 5 pôs os três provedores lado a lado em
geral; esta seção faz isso para os logs de auditoria. Nada nela foi executado aqui: vem da
documentação da Microsoft e do Google.

| a pergunta | AWS | Azure | Google Cloud |
|---|---|---|---|
| quem mudou a configuração de um recurso | eventos de gerenciamento do CloudTrail | o **Activity Log**, por assinatura | os logs de auditoria **Admin Activity** |
| quem leu ou gravou os dados dentro de um recurso | eventos de dados do CloudTrail, escolhidos por recurso | **logs de recurso**, escolhidos por recurso com uma configuração de diagnóstico | os logs de auditoria **Data Access** |
| quem entrou, e como | CloudTrail, `ConsoleLogin` e as chamadas de federação | os logs de entrada e de auditoria do **Microsoft Entra ID** | Cloud Audit Logs, mais os registros de entrada do provedor de identidade em uso |
| guardado sem configurar nada | 90 dias de eventos de gerenciamento, como histórico de eventos | 90 dias de Activity Log | Admin Activity por 400 dias |
| guardado por mais tempo | uma trilha, num bucket seu | uma configuração de diagnóstico, para um workspace do Log Analytics, uma conta de armazenamento ou um event hub | um coletor de logs (*sink*), para um bucket, o BigQuery ou outro projeto |

## Azure

O **Activity Log** registra operações do plano de controle de uma assinatura: uma conta de
armazenamento criada, um papel atribuído, uma regra de rede mudada. Ele está ligado, não custa nada e
guarda 90 dias. Ler um blob é uma operação do *plano de dados* e não aparece ali; ela está nos logs de
recurso da conta de armazenamento, que só existem depois que alguém acrescenta uma configuração de
diagnóstico que os mande para algum lugar.

**As entradas são um log separado, no Microsoft Entra ID**, porque a identidade mora lá e não na
assinatura. Por quanto tempo o Entra guarda os logs de entrada e de auditoria depende da licença, de
dias a um mês, então uma investigação que começa tarde não acha nada se eles não foram exportados.

## Google Cloud

O Cloud Audit Logs tem quatro tipos, e dois padrões importam:

- os logs **Admin Activity** registram mudanças de configuração. São gravados sempre, não podem ser
  desligados e ficam guardados por 400 dias sem custo;
- os logs **Data Access** registram leituras de configuração e leituras e gravações de dados do
  usuário. Ficam **desligados por padrão**, exceto para o BigQuery, porque podem ser enormes, e são
  cobrados quando ligados;
- os logs **System Event** registram o que os sistemas do próprio Google fizeram nos seus recursos;
- os logs **Policy Denied** registram chamadas recusadas por uma política de segurança, como um
  perímetro do VPC Service Controls.

## O que vale em todo lugar

Três hábitos são os mesmos em todo provedor, seja qual for o nome do produto:

1. **Decida os eventos de dados antes de precisar deles.** O padrão responde quem mudou uma
   configuração. Quem leu os arquivos dos pacientes fica desligado em todo lugar, e ninguém consegue
   ligar isso para trás.
2. **Mande os registros para fora da conta que eles descrevem.** Uma conta de arquivo de logs, um
   projeto separado, uma assinatura separada: algum lugar onde os administradores registrados não
   consigam apagar.
3. **Leia os horários em UTC.** Os três gravam os horários em UTC, e uma linha do tempo em horário
   local é montada depois de os registros serem lidos, nunca no lugar deles.
