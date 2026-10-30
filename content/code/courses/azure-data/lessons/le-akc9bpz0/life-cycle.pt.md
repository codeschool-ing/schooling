---
title: Regras de ciclo de vida, que movem e apagam por idade
version: 1
---

**Uma política de gerenciamento de ciclo de vida é um conjunto de regras que a conta de armazenamento
roda sozinha, uma vez por dia.** Elas movem blobs para tiers mais frios e os apagam por idade. São as
trocas de tier e a aritmética da lição 4 entregues à conta, para ninguém ter de lembrar de arquivar as
exportações do ano passado. Uma regra diz a que blobs se aplica e o que acontece com eles depois de
quantos dias, e trata separadamente o blob atual, as versões anteriores e os snapshots.

Políticas de ciclo de vida pertencem à conta, e só o plano de controle as define; o Azurite não tem
política nenhuma. Esta seção foi escrita a partir da documentação da Microsoft e conferida com o
Terraform.

## A regra da Quitanda para as exportações

As exportações são lidas por cerca de um mês, raramente por um ano, e precisam existir por sete anos.
A conta de exportações é ZRS, que a lição 4 mostrou não ter tier archive, então o passo mais frio aqui
é o cold. Salve isto ao lado do `account.tf`:

`lifecycle.tf`:

```hcl
resource "azurerm_storage_management_policy" "data" {
  storage_account_id = azurerm_storage_account.data.id

  rule {
    name    = "exports-age-out"
    enabled = true

    filters {
      blob_types   = ["blockBlob"]
      prefix_match = ["orders-raw/exports/"]
    }

    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than = 30
        tier_to_cold_after_days_since_modification_greater_than = 365
        delete_after_days_since_modification_greater_than       = 2555
      }
      version {
        delete_after_days_since_creation = 90
      }
    }
  }
}
```

```
ana@laptop:~/azure/tf/protect$ terraform validate -no-color
Success! The configuration is valid.

ana@laptop:~/azure/tf/protect$ sed -i 's/"blockBlob"/"BlockBlob"/' lifecycle.tf && terraform validate -no-color

Error: expected rule.0.filters.0.blob_types.0 to be one of ["blockBlob" "appendBlob"], got BlockBlob

  with azurerm_storage_management_policy.data,
  on lifecycle.tf line 9, in resource "azurerm_storage_management_policy" "data":
   9:       blob_types   = ["BlockBlob"]
```

Leia a regra do filtro para baixo. **O `prefix_match` começa com o nome do contêiner**, `orders-raw/`,
e depois o começo dos nomes de blob, então esta regra mexe nas exportações e em nada mais da conta.
`blob_types` a limita a block blobs, e a recusa mostra o provedor cobrando a grafia exata,
`blockBlob`: a mesma palavra com maiúscula não é um tipo. Depois, três idades para o blob atual,
contadas da última modificação: cool depois de 30 dias, cold depois de um ano, apagado depois de 2.555
dias, sete anos de 365 dias. E o bloco `version` apaga versões anteriores 90 dias depois de criadas, a
linha que impede o versionamento de crescer para sempre.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"A regra exports-age-out numa linha do tempo de dias em escala de raiz quadrada. O blob atual fica em hot nos primeiros 30 dias, em cool do dia 30 ao 365, em cold do dia 365 ao 2.555, e é apagado no dia 2.555. As versões anteriores ficam 90 dias desde a criação e depois são apagadas.\" data-fig=\"l05-lifeline\"><defs><marker id=\"l05-lifeline-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,4 L0,8 z\" fill=\"var(--wire)\"/></marker></defs><text x=\"30\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" font-weight=\"600\">o blob atual, por dias desde a última modificação</text><rect x=\"31.0\" y=\"40\" width=\"69.51697073924622\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"65.75848536962312\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">Hot</text><rect x=\"102.51697073924622\" y=\"40\" width=\"175.9395814468437\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"190.48676146266808\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">Cool</text><rect x=\"280.45655218608994\" y=\"40\" width=\"408.54344781391006\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"484.728276093045\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">Cold</text><line x1=\"690.0\" y1=\"36\" x2=\"690.0\" y2=\"82\" stroke=\"var(--amber)\" stroke-width=\"2\"/><text x=\"686.0\" y=\"96\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">apagado</text><path d=\"M30 110 L690 110\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"/><path d=\"M30.0 110 L30.0 116\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"/><text x=\"30.0\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M101.5 110 L101.5 116\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"/><text x=\"101.51697073924622\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">30</text><path d=\"M153.9 110 L153.9 116\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"/><text x=\"153.8710269237912\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">90</text><path d=\"M279.5 110 L279.5 116\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"/><text x=\"279.45655218608994\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">365</text><path d=\"M442.9 110 L442.9 116\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"/><text x=\"442.9034230793039\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1.000</text><path d=\"M690.0 110 L690.0 116\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"/><text x=\"690.0\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2.555</text><text x=\"690\" y=\"146\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">dias, em escala de raiz quadrada</text><text x=\"30\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" font-weight=\"600\">versões anteriores</text><rect x=\"31.0\" y=\"188\" width=\"121.87102692379119\" height=\"26\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"/><text x=\"91.9355134618956\" y=\"201\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">guardadas 90 dias</text><line x1=\"153.8710269237912\" y1=\"184\" x2=\"153.8710269237912\" y2=\"218\" stroke=\"var(--amber)\" stroke-width=\"2\"/><text x=\"161.8710269237912\" y=\"201\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">apagadas</text></svg>", "caption": "O que o lifecycle.tf declara. Cada mudança respeita os dias mínimos do tier: 335 em cool, cerca de seis anos em cold."}
```

## O que uma regra não sabe

**Uma regra não é instantânea.** A documentação da Microsoft diz que a política roda uma vez por dia,
e que uma política nova ou alterada pode levar até 24 horas para valer, e mais para as ações
terminarem numa conta grande. Uma regra escrita hoje não arquiva nada esta noite.

**Uma regra não sabe nada de dias mínimos.** A cobrança por saída antecipada da lição 4 vale para o
que uma regra move ou apaga, exatamente como se uma pessoa tivesse feito. Uma regra que movesse blobs
para cold aos 30 dias e os apagasse aos 60 pagaria os 90 do cold para cada um. A regra acima respeita
cada mínimo: 335 dias em cool, seis anos em cold.

**Contar da última modificação é o relógio seguro para arquivos escritos uma vez.** Os outros relógios
que o provedor listou, criação e último acesso, têm seus usos: o último acesso só desce um blob se
ninguém o lê, mas precisa do rastreamento de acesso ligado na conta, e ele é cobrado. Para as
exportações, escritas uma vez e nunca modificadas, os três relógios concordariam, e o mais simples é
o que não surpreende ninguém.
