---
title: Regras, e o que decide a conformidade
version: 1
---

Uma **regra do Config** olha itens de configuração e diz, para cada recurso no seu escopo, `COMPLIANT` ou
`NON_COMPLIANT`. A AWS escreve várias centenas de **regras gerenciadas**, nomeadas por um identificador, e
uma equipe as usa pelo nome, com parâmetros quando a regra aceita. Duas para os buckets da loja: uma que
reprova um bucket legível pelo público, e uma que reprova um bucket sem tag `owner`. A segunda recebe o
parâmetro como uma string JSON dentro do JSON, o que é mais fácil de manter num arquivo.

`required-owner.json`:

```json
{
  "ConfigRuleName": "required-owner",
  "Source": { "Owner": "AWS", "SourceIdentifier": "REQUIRED_TAGS" },
  "InputParameters": "{\"tag1Key\":\"owner\"}",
  "Scope": { "ComplianceResourceTypes": ["AWS::S3::Bucket"] }
}
```

```
ana@laptop:~/aws/config$ aws configservice put-config-rule --config-rule '{"ConfigRuleName":"s3-public-read","Source":{"Owner":"AWS","SourceIdentifier":"S3_BUCKET_PUBLIC_READ_PROHIBITED"},"Scope":{"ComplianceResourceTypes":["AWS::S3::Bucket"]}}'
ana@laptop:~/aws/config$ aws configservice put-config-rule --config-rule file://required-owner.json
ana@laptop:~/aws/config$ aws configservice describe-config-rules --query 'ConfigRules[].[ConfigRuleName,Source.SourceIdentifier,ConfigRuleState]' --output text
required-owner	REQUIRED_TAGS	ACTIVE
s3-public-read	S3_BUCKET_PUBLIC_READ_PROHIBITED	ACTIVE
```

As duas regras estão `ACTIVE`. Uma regra é **disparada** de um de dois jeitos: por uma **mudança de
configuração** num recurso do seu escopo, que é o que as duas fazem, então um bucket é julgado minutos
depois de ser mudado; ou **periodicamente**, a cada uma a vinte e quatro horas, para regras sobre coisas
que não são a configuração de um recurso, como se o CloudTrail está ligado na conta.

O moto conhece os nomes das regras gerenciadas, e recusa uma que não existe, como a AWS:

```
ana@laptop:~/aws/config$ aws configservice put-config-rule --config-rule '{"ConfigRuleName":"tags","Source":{"Owner":"AWS","SourceIdentifier":"REQUIRED_TAG"}}' 2>&1 | tail -1
aws: [ERROR]: An error occurred (InvalidParameterValueException) when calling the PutConfigRule operation: The sourceIdentifier REQUIRED_TAG is invalid.  Please refer to the documentation for a list of valid sourceIdentifiers that can be used when AWS is the Owner
```

## O veredito, que o laboratório não tem

```
ana@laptop:~/aws/config$ aws configservice get-compliance-details-by-config-rule --config-rule-name required-owner 2>&1 | grep -m1 ERROR
aws: [ERROR]: An error occurred (500) when calling the GetComplianceDetailsByConfigRule operation (reached max retries: 2): <!doctype html>
```

**O moto não avalia regra nenhuma.** Na AWS, `get-compliance-details-by-config-rule` listaria cada bucket
com o resultado: `tmp-test-ana` fora de conformidade em `required-owner`, e cada bucket sem bloqueio de
acesso público avaliado por `s3-public-read` pela política e ACLs reais. Os resultados também são um
histórico parecido com o de configuração: o Config guarda quando cada recurso saiu de conformidade e
quando foi corrigido, que é a evidência que um auditor pede, e o motivo de as equipes usarem o Config e
não um script.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Uma linha do tempo com três itens de configuração do bucket shop-exports. Primeiro, descoberto, sem tag de dono e sem bloqueio de acesso público, julgado NON_COMPLIANT. Depois, tag acrescentada, owner=data, ainda sem bloqueio, ainda NON_COMPLIANT. Depois, bloqueio ligado, as quatro opções ligadas, julgado COMPLIANT. Na AWS o veredito da regra sobre cada item é guardado como histórico ao lado.\"><defs><marker id=\"hst-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M40 150 L690 150\" stroke=\"var(--wire)\" stroke-width=\"1.5\" fill=\"none\"></path><rect x=\"25\" y=\"52\" width=\"190\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"120.0\" y=\"76.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">descoberto</text><text x=\"120.0\" y=\"91.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sem dono, sem bloqueio</text><path d=\"M120 118 L120 144\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"50\" y=\"162\" width=\"140\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"120.0\" y=\"177.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">NON_COMPLIANT</text><rect x=\"265\" y=\"52\" width=\"190\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"76.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">tag acrescentada</text><text x=\"360.0\" y=\"91.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">owner=data, sem bloqueio</text><path d=\"M360 118 L360 144\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"290\" y=\"162\" width=\"140\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"177.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">NON_COMPLIANT</text><rect x=\"505\" y=\"52\" width=\"190\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"600.0\" y=\"76.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">bloqueio ligado</text><text x=\"600.0\" y=\"91.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">owner=data, os quatro ligados</text><path d=\"M600 118 L600 144\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"530\" y=\"162\" width=\"140\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"600.0\" y=\"177.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">COMPLIANT</text><text x=\"40\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">itens de configuração de shop-exports na AWS, do mais antigo; o moto guarda só o último</text><text x=\"40\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o veredito da regra sobre cada item; na AWS, guardado como histórico ao lado</text></svg>", "caption": "Toda mudança é um item novo, e todo item recebe um veredito: o histórico diz quando um recurso ficou em conformidade, e não só se está."}
```

Aquilo de que uma regra decide é o item de configuração da seção anterior, e nada mais. A próxima seção
escreve uma regra à mão, para ver isso.
