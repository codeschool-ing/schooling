---
title: Rotação, destruição e o custo de uma chave
version: 1
---

**A vida de uma versão de chave tem quatro estados, e o último não pode ser desfeito.** Versões **habilitadas**
criptografam e descriptografam. As **desabilitadas** não fazem nenhum dos dois e podem ser reabilitadas na hora. As
**agendadas para destruição** ficam desabilitadas com uma contagem regressiva, 30 dias por padrão, durante a qual a
destruição pode ser cancelada. As **destruídas** sumiram, e os dados que embrulharam junto, como `rm kek/v1.bin`
mostrou. Nada nesta seção rodou contra o Cloud KMS; a destruição foi mostrada com um arquivo na segunda seção.

## A proteção é a espera

Destruir uma versão no Cloud KMS não acontece quando é pedido:

```sh
gcloud kms keys versions destroy 1 --key=orders --keyring=shop --location=southamerica-east1
```

Esse comando (não executado) agenda a versão 1 para destruição, e a versão só é destruída quando o período agendado
termina. O período é definido por chave quando a chave é criada, de 1 a 120 dias, 30 por padrão. **Trinta dias é a
janela em que alguém percebe**: um job que não consegue ler as exportações do mês passado, um teste de restauração que
não descriptografa um backup. Um alerta baseado em log (lição 10) na entrada de auditoria de `DestroyCryptoKeyVersion`
garante que alguém perceba no primeiro dia e não no vigésimo nono. Cancelar é um comando,
`gcloud kms keys versions restore`, que deixa a versão desabilitada, para ser habilitada quando o motivo for
entendido.

## Rotação, de novo, com o serviço real

A rotação automática acrescenta uma versão no prazo e a torna primária; nada é recriptografado, como a segunda seção
mostrou. Para CMEK, o Cloud Storage e os outros serviços usam a versão primária para escritas novas e a versão
registrada para leituras, então um bucket escrito ao longo de dois anos guarda objetos embrulhados por oito versões
diferentes, todas legíveis, todas necessárias. **Nunca destrua uma versão antiga para arrumar**, a não ser que os
dados que ela embrulha devam mesmo sumir. Recriptografar dados antigos sob a versão nova é um job à parte, uma
reescrita de cada objeto, e só vale a pena quando se suspeita que uma versão foi comprometida.

## Quanto custa uma chave

Pela página de preços, lida em 30 de outubro de 2026: cada versão de chave de software **ativa** custa **0,06 USD por
mês**, e ativa inclui habilitada, desabilitada e agendada para destruição; operações criptográficas custam **0,03 USD
por 10.000**, depois de 10.000 grátis por mês; operações administrativas são grátis. Versões HSM custam mais.

A chave `orders` da loja, girada a cada trimestre, tem quatro versões ativas depois de um ano: 0,24 USD por mês. Se
toda leitura de um pedido exportado precisasse de um desembrulho, 100.000 leituras por mês seriam 90.000 operações
acima da franquia gratuita, 0,27 USD. **A criptografia de envelope é o que torna isso barato**: o Cloud KMS recebe
pedidos de poucos bytes de chave por objeto, nunca do objeto em si, seja qual for o tamanho dele.
