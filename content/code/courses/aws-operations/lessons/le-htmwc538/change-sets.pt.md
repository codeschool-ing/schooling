---
title: Change sets, e a palavra Replacement
version: 1
---

Atualizar uma stack direto, com `update-stack`, aplica a mudança assim que ela é calculada. **Um change
set a calcula e para**: lista o que aconteceria com cada recurso e espera que alguém o execute ou o
descarte. É o `terraform plan` do CloudFormation, guardado na AWS, e para qualquer coisa em produção é
o único jeito de atualizar uma stack.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Um fluxo de quatro caixas: o template shop.yaml vira um change set, calculado e esperando; uma pessoa o revisa; executá-lo muda a stack. Abaixo, o que um change set lista por recurso, em três colunas: Action, LogicalResourceId e Replacement. Duas linhas de exemplo: Modify WebLogs False, em que a retenção muda no lugar; e Modify Uploads True, em que um nome novo de bucket significa um bucket novo e o antigo apagado.\"><defs><marker id=\"cs-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"130\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"85.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">template</text><text x=\"85.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">shop.yaml</text><rect x=\"205\" y=\"30\" width=\"150\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"280.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">change set</text><text x=\"280.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">calculado, esperando</text><rect x=\"410\" y=\"30\" width=\"130\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"475.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">revisão</text><text x=\"475.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">uma pessoa lê</text><rect x=\"590\" y=\"30\" width=\"110\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"645.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">executar</text><text x=\"645.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a stack muda</text><path d=\"M152 58 L203 58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cs-ah)\"></path><path d=\"M357 58 L408 58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cs-ah)\"></path><path d=\"M542 58 L588 58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cs-ah)\"></path><rect x=\"20\" y=\"120\" width=\"680\" height=\"130\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"36\" y=\"138\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">o que um change set lista, por recurso</text><text x=\"60\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Action</text><text x=\"220\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">LogicalResourceId</text><text x=\"420\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Replacement</text><text x=\"60\" y=\"188\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Modify</text><text x=\"220\" y=\"188\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">WebLogs</text><text x=\"420\" y=\"188\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">False</text><text x=\"490\" y=\"188\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a retenção muda no lugar</text><text x=\"60\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Modify</text><text x=\"220\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Uploads</text><text x=\"420\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\" font-weight=\"600\">True</text><text x=\"490\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">nome novo: um bucket novo, o antigo apagado</text></svg>", "caption": "As duas linhas de exemplo seguem a documentação da AWS; o moto não calcula change set de uma stack existente.", "same": ["change set", "template"]}
```

## As três colunas que importam

Para cada recurso um change set diz:

| campo | valores | o que procurar |
|---|---|---|
| `Action` | `Add`, `Modify`, `Remove`, `Import` | um `Remove` que ninguém pretendia |
| `Replacement` | `True`, `False`, `Conditional` | **`True`**: o recurso é apagado e criado de novo |
| `Scope` e `Details` | quais propriedades mudaram | a propriedade que causou a substituição |

`Replacement: True` é a linha onde parar. Algumas propriedades mudam no lugar, como a retenção de um
grupo de logs ou o nome de exibição de um tópico. Outras não, e mudá-las faz o CloudFormation criar um
recurso novo e apagar o antigo: **o nome de um bucket, o identificador de um banco, o nome de uma
fila**. Num bucket, o antigo é apagado com o conteúdo, a menos que `UpdateReplacePolicy` diga `Retain`,
e é por isso que esta lição o acrescentou. `Conditional` significa que a resposta depende de um valor
que o CloudFormation só vai saber durante a atualização; leia como `True`.

## Contra o moto

A loja aumenta a retenção de logs para 30 dias. A única mudança é um parâmetro, então o change set
deveria dizer `Modify`, sem substituição, só para `WebLogs`:

```
ana@laptop:~/aws/cfn$ aws cloudformation create-change-set --stack-name shop-base --change-set-name retention-30 --template-body file://shop.yaml --parameters ParameterKey=Retention,ParameterValue=30 --query Id --output text
arn:aws:cloudformation:sa-east-1:123456789012:changeSet/retention-30/4ae1b614-db59-4089-b7f2-a2b4aee5a64a
ana@laptop:~/aws/cfn$ aws cloudformation wait change-set-create-complete --stack-name shop-base --change-set-name retention-30
ana@laptop:~/aws/cfn$ aws cloudformation describe-change-set --stack-name shop-base --change-set-name retention-30 --query 'Changes[].ResourceChange.[Action,LogicalResourceId,Replacement]' --output text
Add	WebLogs	None
Add	Uploads	None
Add	Alerts	None
```

**O moto responde `Add` para os três recursos**, o que um change set de uma stack existente nunca diz
para recursos que já existem; ele calcula todo change set como se a stack estivesse vazia, e não
informa substituição nenhuma. Na AWS, esse change set teria uma linha: `Modify WebLogs False`. Esta é
a parte da lição que o laboratório não consegue mostrar, então ela é ensinada pela documentação da
AWS, e o hábito é o mesmo de qualquer jeito: **leia o change set antes de executá-lo, e nunca execute
um que tenha um `Replacement: True` que você não sabe explicar**.

## Numa esteira

Uma esteira faz a mesma coisa em duas ações: uma cria o change set, uma aprovação manual o mostra a uma
pessoa, e uma segunda ação o executa. A ação de CloudFormation do CodePipeline tem os dois modos,
`CHANGE_SET_REPLACE` e `CHANGE_SET_EXECUTE`, então o estágio de aprovação da lição 1 fica entre eles.
