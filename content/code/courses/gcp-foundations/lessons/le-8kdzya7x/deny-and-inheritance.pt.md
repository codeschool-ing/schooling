---
title: Políticas de negação, e como a árvore resolve um pedido
version: 1
---

**As políticas de permissão se somam árvore abaixo, e nada mais abaixo pode tirar uma concessão.** Um
papel na organização vale em todo projeto; a política de um projeto não consegue removê-lo, porque a
política de um projeto só consegue acrescentar vinculações. É a herança da lição 2, aplicada ao IAM, e é
o motivo de existir um segundo tipo de política.

Uma **política de negação** nomeia principals e permissões que são recusados, diga o que disser qualquer
política de permissão. Ela é anexada à organização, a uma pasta ou a um projeto, é herdada como uma
política de permissão, e é **avaliada primeiro**. A ordem em que o Google avalia um pedido, simplificada
aos dois tipos que esta lição cobre:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l07-evaluation\" aria-label=\"Como um pedido é julgado, de cima para baixo. Primeiro, as políticas de negação, da organização até o recurso: se alguma nega a permissão ao principal, o pedido é recusado e mais nada é lido. Depois, as políticas de permissão, da organização até o recurso: se alguma vinculação no caminho concede um papel com a permissão, o pedido é permitido. Se nenhuma das duas, o pedido é recusado: nenhuma concessão é uma recusa.\"><defs><marker id=\"l07-evaluation-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l07-evaluation-af-ah-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker><marker id=\"l07-evaluation-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"250.0\" y=\"14.0\" width=\"220.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"31.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">chega um pedido</text><path d=\"M360.0 48.0 L360.0 70.0\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l07-evaluation-af-ah-paper)\"></path><rect x=\"190.0\" y=\"72.0\" width=\"340.0\" height=\"50.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"360.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">1. negações, da organização ao recurso</text><text x=\"360.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">alguma nega esta permissão a este principal?</text><path d=\"M532.0 97.0 L596.0 97.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l07-evaluation-af-ah-amber)\"></path><text x=\"564.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">sim</text><rect x=\"600.0\" y=\"78.0\" width=\"104.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"652.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">recusado</text><path d=\"M360.0 122.0 L360.0 156.0\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l07-evaluation-af-ah-paper)\"></path><text x=\"372.0\" y=\"139.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">não</text><rect x=\"190.0\" y=\"158.0\" width=\"340.0\" height=\"50.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"360.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">2. permissões, da organização ao recurso</text><text x=\"360.0\" y=\"194.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">alguma vinculação concede um papel com ela?</text><path d=\"M532.0 183.0 L596.0 183.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l07-evaluation-af-ah-phosphor)\"></path><text x=\"564.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">sim</text><rect x=\"600.0\" y=\"164.0\" width=\"104.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"652.0\" y=\"183.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">permitido</text><path d=\"M360.0 208.0 L360.0 242.0\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l07-evaluation-af-ah-paper)\"></path><text x=\"372.0\" y=\"225.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">não</text><rect x=\"260.0\" y=\"244.0\" width=\"200.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"360.0\" y=\"263.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">recusado: concessão nenhuma</text><text x=\"20.0\" y=\"140.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a negação é lida antes,</text><text x=\"20.0\" y=\"156.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">e nenhuma permissão a desfaz</text></svg>", "caption": "Primeiro a negação, depois a permissão, depois a recusa."}
```

1. **Políticas de negação**, da organização até o recurso. Se qualquer uma nega a permissão ao
   principal, o pedido é recusado, e mais nada é lido.
2. **Políticas de permissão**, da organização até o recurso. Se qualquer vinculação no caminho concede um
   papel que tenha a permissão, o pedido é permitido.
3. Fora isso, recusado. **Nenhuma concessão é uma recusa**: o IAM não permite nada por padrão.

Há outras camadas por cima no modelo completo do Google, as principal access boundaries e as políticas
da organização da lição 4 entre elas, e elas também podem recusar. As duas acima são as que todo pedido
encontra.

## Uma negação para o planner

Duas coisas nunca deveriam acontecer na produção, venha o papel de onde vier: apagar o projeto e apagar
um tópico. Acrescente uma política de negação ao `~/gcp/policy`, salva como `deny.tf`:

```hcl
resource "google_iam_deny_policy" "production_guard" {
  parent       = urlencode("cloudresourcemanager.googleapis.com/projects/planner-prod")
  name         = "production-guard"
  display_name = "Nobody deletes the project or a topic"
  rules {
    description = "Only the break-glass group may delete."
    deny_rule {
      denied_principals = ["principalSet://goog/public:all"]
      exception_principals = [
        "principalSet://goog/group/break-glass@example.com",
      ]
      denied_permissions = [
        "cloudresourcemanager.googleapis.com/projects.delete",
        "pubsub.googleapis.com/topics.delete",
      ]
    }
  }
}
```

Três coisas nela diferem de uma política de permissão. **Os principals são escritos na forma
`principalSet://`**: `principalSet://goog/public:all` é todo mundo, e `principalSet://goog/group/...` um
grupo do Google. **As permissões são escritas com o endereço do serviço na frente**,
`pubsub.googleapis.com/topics.delete` em vez de `pubsub.topics.delete`. E as **`exception_principals`**
recortam a quem a negação não se aplica, que é como um grupo de emergência guarda a única porta de que
uma emergência real precisa.

```
ana@laptop:~/gcp/policy$ terraform plan -input=false -no-color | sed -n '/# google_iam_deny_policy/,/^    }/p'
  # google_iam_deny_policy.production_guard will be created
  + resource "google_iam_deny_policy" "production_guard" {
      + deletion_policy = (known after apply)
      + display_name    = "Nobody deletes the project or a topic"
      + etag            = (known after apply)
      + id              = (known after apply)
      + name            = "production-guard"
      + parent          = "cloudresourcemanager.googleapis.com%2Fprojects%2Fplanner-prod"

      + rules {
          + description = "Only the break-glass group may delete."

          + deny_rule {
              + denied_permissions   = [
                  + "cloudresourcemanager.googleapis.com/projects.delete",
                  + "pubsub.googleapis.com/topics.delete",
                ]
              + denied_principals    = [
                  + "principalSet://goog/public:all",
                ]
              + exception_principals = [
                  + "principalSet://goog/group/break-glass@example.com",
                ]
            }
        }
    }
```

O `parent` saiu como `cloudresourcemanager.googleapis.com%2Fprojects%2Fplanner-prod`: o nome completo de
recurso da lição 2 sem o `//` do começo, com toda `/` escrita como `%2F`, porque a API de políticas de
negação recebe o pai como uma parte do próprio endereço. Foi isso que o `urlencode` do arquivo fez.

**Nem toda permissão pode ser negada.** As políticas de negação aceitam uma lista de permissões que cresce
a cada serviço, e uma permissão fora dela é recusada quando a política é criada: mais uma coisa que um
plano não enxerga. O papel para gerenciá-las, `roles/iam.denyAdmin`, fica na organização, pelo mesmo
motivo do administrador de políticas da lição 4: as pessoas a quem uma negação se dirige não devem ser as
que podem levantá-la. Nada disto rodou contra o Google.
