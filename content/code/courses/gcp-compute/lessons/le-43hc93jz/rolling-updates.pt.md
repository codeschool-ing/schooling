---
title: Atualizações graduais, e o canário
version: 1
---

Um template novo não faz nada com as máquinas que já existem. **O grupo as substitui conforme a sua
política de atualização, algumas de cada vez, para o serviço continuar respondendo enquanto cada
máquina é trocada por uma feita do template novo.** A política decide quantas, e errar nisso é como
um lançamento derruba um serviço.

## Dois números

A política gira em torno de dois números, e toda atualização gradual é uma troca entre eles:

- **`max_surge`**: quantas máquinas acima da meta o grupo pode criar durante a atualização. O surge
  acrescenta capacidade antes de tirar qualquer uma, ao preço de pagar pelas máquinas extras enquanto
  elas rodam.
- **`max_unavailable`**: quantas máquinas podem ficar fora de serviço ao mesmo tempo. A
  indisponibilidade atualiza sem máquinas extras, ao preço de menos capacidade durante a atualização.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Quatro passos de uma atualização gradual de um grupo de três, com max_surge 3 e max_unavailable 0. Passo 1: três máquinas no template antigo, servindo. Passo 2: três máquinas novas sobem ao lado, seis no total, enquanto as três antigas continuam servindo. Passo 3: as novas passam nas verificações de saúde e servem, e as antigas são apagadas. Passo 4: três máquinas no template novo. Em nenhum passo menos de três máquinas saudáveis servem.\"><defs><marker id=\"l4r-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"160\" height=\"260\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"32\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">passo 1</text><text x=\"100\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">três antigas, servindo</text><rect x=\"40\" y=\"84\" width=\"120\" height=\"25\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"96.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">antiga</text><rect x=\"40\" y=\"115\" width=\"120\" height=\"25\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"127.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">antiga</text><rect x=\"40\" y=\"146\" width=\"120\" height=\"25\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"158.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">antiga</text><rect x=\"195\" y=\"20\" width=\"160\" height=\"260\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"207\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">passo 2</text><text x=\"275\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">três novas subindo</text><rect x=\"215\" y=\"84\" width=\"120\" height=\"25\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"275.0\" y=\"96.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">antiga</text><rect x=\"215\" y=\"115\" width=\"120\" height=\"25\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"275.0\" y=\"127.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">antiga</text><rect x=\"215\" y=\"146\" width=\"120\" height=\"25\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"275.0\" y=\"158.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">antiga</text><rect x=\"215\" y=\"177\" width=\"120\" height=\"25\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"275.0\" y=\"189.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">nova, subindo</text><rect x=\"215\" y=\"208\" width=\"120\" height=\"25\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"275.0\" y=\"220.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">nova, subindo</text><rect x=\"215\" y=\"239\" width=\"120\" height=\"25\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"275.0\" y=\"251.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">nova, subindo</text><rect x=\"370\" y=\"20\" width=\"160\" height=\"260\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"382\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">passo 3</text><text x=\"450\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">novas servindo, antigas apagadas</text><rect x=\"390\" y=\"84\" width=\"120\" height=\"25\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"450.0\" y=\"96.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">antiga, saindo</text><rect x=\"390\" y=\"115\" width=\"120\" height=\"25\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"450.0\" y=\"127.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">antiga, saindo</text><rect x=\"390\" y=\"146\" width=\"120\" height=\"25\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"450.0\" y=\"158.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">antiga, saindo</text><rect x=\"390\" y=\"177\" width=\"120\" height=\"25\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"189.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">nova</text><rect x=\"390\" y=\"208\" width=\"120\" height=\"25\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"220.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">nova</text><rect x=\"390\" y=\"239\" width=\"120\" height=\"25\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"251.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">nova</text><rect x=\"545\" y=\"20\" width=\"160\" height=\"260\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"557\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">passo 4</text><text x=\"625\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">três novas, servindo</text><rect x=\"565\" y=\"84\" width=\"120\" height=\"25\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"625.0\" y=\"96.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">nova</text><rect x=\"565\" y=\"115\" width=\"120\" height=\"25\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"625.0\" y=\"127.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">nova</text><rect x=\"565\" y=\"146\" width=\"120\" height=\"25\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"625.0\" y=\"158.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">nova</text></svg>", "caption": "Com surge e sem indisponibilidade, o grupo paga por até seis máquinas por alguns minutos e nunca serve com menos de três."}
```

A escolha da loja é surge e nenhuma indisponibilidade: a atualização nunca roda com menos de três
máquinas saudáveis. Acrescente a política dentro do recurso do grupo:

```hcl
# group/main.tf, update policy
  update_policy {
    type                         = "PROACTIVE"
    minimal_action               = "REPLACE"
    max_surge_fixed              = 3
    max_unavailable_fixed        = 0
    instance_redistribution_type = "PROACTIVE"
  }
```

```
ana@laptop:~/gcp/group$ terraform plan -no-color | grep -E 'max_surge_fixed|max_unavailable_fixed|minimal_action|"PROACTIVE"|^Plan'
          + max_surge_fixed       = 3
          + max_unavailable_fixed = 0
          + minimal_action        = "REPLACE"
          + type                  = "PROACTIVE"
Plan: 3 to add, 0 to change, 0 to destroy.
```

`PROACTIVE` quer dizer que o grupo começa a substituir máquinas assim que o template muda; o outro
tipo, `OPPORTUNISTIC`, só aplica o template novo às máquinas que o grupo cria por algum outro motivo.
`REPLACE` quer dizer uma máquina nova com nome novo, em vez de reiniciar a antiga. Este é o único
bloco em que o provider verifica uma palavra, como fez com o agendamento de snapshots na lição 3.
Escreva `SOMETIMES` no lugar de `PROACTIVE` na linha `type` e rode o plan de novo:

```
ana@laptop:~/gcp/group$ grep -n "type " main.tf
18:  machine_type = "e2-standard-2"
67:    type                         = "SOMETIMES"
71:    instance_redistribution_type = "PROACTIVE"
ana@laptop:~/gcp/group$ terraform plan -no-color

Error: expected update_policy.0.type to be one of ["OPPORTUNISTIC" "PROACTIVE"], got SOMETIMES

  with google_compute_region_instance_group_manager.web,
  on main.tf line 67, in resource "google_compute_region_instance_group_manager" "web":
  67:     type                         = "SOMETIMES"
```

Ponha `PROACTIVE` de volta antes de seguir.

**Num grupo regional, um surge ou uma indisponibilidade fixos precisam ser zero ou pelo menos o
número de zonas**, porque o grupo move máquinas zona por zona. Três zonas, então `max_surge_fixed = 3`
ou nada; o plan não verifica essa regra, e o Compute Engine recusa um 2 quando o grupo é criado.

## O canário

Substituir todas as máquinas de uma vez funciona até o template novo estar errado. **Um canário manda
uma pequena parte do grupo para o template novo primeiro e deixa o resto no antigo**, para um erro
aparecer numa máquina em vez de em todas. O Terraform escreve isso como dois blocos `version`, o
segundo com um `target_size`. No lugar do bloco `version` único da seção 03:

```hcl
# group/main.tf, canary
  version {
    name              = "stable"
    instance_template = "projects/planner-dev/global/instanceTemplates/web-stable"
  }

  version {
    name              = "canary"
    instance_template = google_compute_instance_template.web.id

    target_size {
      fixed = 1
    }
  }
```

```
ana@laptop:~/gcp/group$ terraform plan -no-color | grep -E '^      \+ version|instance_template = |name += "(stable|canary)"|^              \+ fixed|^Plan'
      + version {
          + instance_template = "projects/planner-dev/global/instanceTemplates/web-stable"
          + name              = "stable"
      + version {
          + instance_template = (known after apply)
          + name              = "canary"
              + fixed = 1
Plan: 3 to add, 0 to change, 0 to destroy.
```

Uma máquina das três roda o template novo e duas ficam no antigo. Compare os erros e a latência do
canário com os das outras; se ele estiver pior, remova o segundo bloco e o grupo põe as três de volta
no template estável. Se ele aguentar, o passo seguinte é tornar o template novo a única versão. O nome
do template estável está escrito por extenso porque ele já existe e o Terraform não o gerencia neste
arquivo: o canário é um momento entre dois lançamentos, não uma forma permanente.

Cada um desses passos é uma mudança num grupo em funcionamento, então este laboratório consegue
planejá-los e não consegue mostrá-los acontecendo. O que um leitor confere aqui é o arquivo: a forma
da política e das versões sobre as quais o Compute Engine agiria.
