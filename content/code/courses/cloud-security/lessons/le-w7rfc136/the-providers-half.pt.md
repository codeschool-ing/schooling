---
title: A metade do provedor, até onde dá para ver
version: 1
---

**Você não pode testar a metade do provedor, então lê o que um auditor independente escreveu sobre
ela, e a página mais útil desse relatório é a que lista o que o auditor supôs que *você* faria.** Esta
seção é ensinada pela documentação dos provedores: os relatórios ficam atrás de uma conta, e nada aqui
foi executado.

## Os relatórios

Cada um dos três grandes provedores publica a mesma família de atestações, e cada um as guarda num
portal próprio: o **AWS Artifact** no console da AWS, o **Service Trust Portal** na Microsoft, e o
**Compliance Reports Manager** no Google Cloud. Alguns são públicos; a maioria exige uma conta, e
alguns exigem aceitar um acordo de confidencialidade antes do download.

| relatório | o que ele diz |
|---|---|
| certificado **ISO/IEC 27001** | existe um sistema de gestão de segurança da informação, e ele foi certificado; as ISO/IEC 27017 e 27018 acrescentam controles para serviços de nuvem e para dados pessoais neles |
| **SOC 2 Tipo II** | um auditor testou controles nomeados ao longo de meses e diz se funcionaram |
| **SOC 3** | um resumo público e curto do SOC 2, sem nenhum detalhe |
| atestado de conformidade **PCI DSS** | quais serviços podem guardar dados de cartão, e em que condições |

Um certificado diz que um sistema existe. **O SOC 2 Tipo II é o que um engenheiro de segurança lê**,
porque diz o que foi testado, como, ao longo de quais meses, e o que falhou.

## Lendo um SOC 2 Tipo II

Quatro partes dele decidem se ele responde à sua pergunta:

1. **O escopo.** Quais serviços e quais regiões a auditoria cobriu. Um serviço fora da lista não foi
   examinado, por mais famoso que seja.
2. **O período.** Os meses ao longo dos quais os controles foram observados. Um relatório do ano
   passado não diz nada sobre uma mudança feita neste ano.
3. **A opinião e as exceções.** A opinião do auditor vem primeiro e, mais adiante, cada controle
   testado com o resultado. Um teste em que algumas amostras falharam aparece como *exceção*, com a
   resposta do provedor ao lado.
4. **Os controles complementares da entidade usuária.** Uma lista, quase sempre perto do fim, de
   controles que o provedor supõe que seus clientes operam, sem os quais os controles dele não atingem
   o objetivo.

A quarta é a linha da responsabilidade compartilhada escrita na língua de um auditor. Itens como "os
clientes são responsáveis por conceder e revisar o acesso dos próprios usuários" ou "por configurar a
criptografia dos dados que guardam" são as camadas acima da linha, e um relatório aprovado é um
relatório aprovado **na suposição de que você as faz**. Quando alguém diz "o provedor é certificado",
a resposta honesta é que o certificado conta com você.

## O que nenhum relatório consegue dizer

Um relatório descreve o provedor, para todos os clientes, no passado. Ele não diz nada sobre a sua
conta: nenhum dos seus buckets, chaves ou regras de rede está nele. Então os dois tipos de prova da
primeira seção desta aula não são alternativas. O relatório cobre o que você não vê, a API cobre o que
você vê, e **uma auditoria do seu sistema precisa dos dois**: o relatório do provedor para as camadas
abaixo da linha, e as suas próprias transcrições para as camadas acima dela. A aula 17 monta exatamente
essa pilha para um auditor.
