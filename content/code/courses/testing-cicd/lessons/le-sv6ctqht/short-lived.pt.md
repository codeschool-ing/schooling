---
title: Credenciais que expiram sozinhas
version: 1
---

Todo segredo até aqui é **de vida longa**: funciona até alguém revogá-lo. Uma credencial de vida longa
num pipeline é um passivo sem data de fim. Precisa ser guardada, pode ser copiada, e no dia em que
vaza ela funciona para quem ataca exatamente como funciona para você, até alguém perceber.

A alternativa é não guardar **credencial durável nenhuma**. O pipeline prova quem é no momento em que
precisa de acesso, e recebe uma credencial que expira sozinha, minutos ou uma hora depois. Em CI
hospedada o mecanismo é a **federação OpenID Connect (OIDC)**:

1. o job pede ao serviço de CI um token assinado que diz qual repositório, qual workflow e qual branch
   ou tag está rodando;
2. o job apresenta esse token ao provedor de nuvem;
3. o provedor confere a assinatura e **uma condição que o dono dele escreveu**, e devolve uma
   credencial de acesso de vida curta;
4. a credencial expira sozinha.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Uma sequência entre três partes: o job de deploy, o GitHub e o provedor de nuvem. 1, o job pede ao GitHub um token sobre esta execução. 2, o GitHub devolve um token assinado que nomeia o repositório, o workflow e a ref. 3, o job apresenta o token ao provedor, que confere a assinatura e a condição do repositório. 4, o provedor devolve uma credencial que expira em uma hora.\"><rect x=\"50\" y=\"14\" width=\"160\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"130\" y=\"31\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">job de deploy</text><path d=\"M130 48 L130 262\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></path><rect x=\"280\" y=\"14\" width=\"160\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"31\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">GitHub</text><path d=\"M360 48 L360 262\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></path><rect x=\"510\" y=\"14\" width=\"160\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"590\" y=\"31\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">provedor de nuvem</text><path d=\"M590 48 L590 262\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></path><path d=\"M130 82 L353 82\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M352 78 L360 82 L352 86 z\" fill=\"var(--paper-dim)\"></path><text x=\"245.0\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1. token sobre esta execução?</text><path d=\"M360 124 L137 124\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M138 120 L130 124 L138 128 z\" fill=\"var(--paper-dim)\"></path><text x=\"245.0\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">2. assinado: repositório, workflow, ref</text><path d=\"M130 166 L583 166\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><path d=\"M582 162 L590 166 L582 170 z\" fill=\"var(--phosphor)\"></path><text x=\"360.0\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">3. este token, conferido contra a condição</text><path d=\"M590 208 L137 208\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><path d=\"M138 204 L130 208 L138 212 z\" fill=\"var(--amber)\"></path><text x=\"360.0\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">4. uma credencial por uma hora</text><text x=\"360\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nada fica guardado antes do passo 1 nem depois da hora</text></svg>", "caption": "A troca descrita acima, em ordem de tempo. O único segredo envolvido é a chave de assinatura do GitHub, que nunca sai do GitHub.", "same": ["GitHub"]}
```

## O deploy deste repositório funciona assim

O job de deploy do workflow de release não guarda chave de nuvem nenhuma. O passo que obtém as
credenciais tem o nome do que faz:

```yaml
      - name: An hour of credentials, in exchange for a token about this repository
        uses: google-github-actions/auth@7c6bc770dae815cd3e89ee6cdf493a5fab2cc093 # v3.0.0
        with:
          workload_identity_provider: ${{ env.WORKLOAD_IDENTITY_PROVIDER }}
          service_account: ${{ env.DEPLOY_ACCOUNT }}
```

Do lado da nuvem, o Terraform do repositório declara em que tokens acreditar, e o comentário dele chama
uma linha de *a linha mais importante deste diretório*:

```hcl
  // Read the block comment above before touching this line.
  attribute_condition = "assertion.repository == \"${var.github_repository}\""
```

Sem essa condição o provedor confiaria em **qualquer** repositório do GitHub, já que qualquer um deles
consegue um token assinado válido. Com ela, só tokens sobre este repositório são trocados, e o vínculo
na conta de deploy estreita isso mais uma vez. O comentário no topo do arquivo põe o benefício numa
frase: *nada durável existe para vazar*.

## O que muda

| | chave de vida longa num segredo | federação |
|---|---|---|
| o que fica guardado na CI | a chave | nada |
| o que um log vazado poderia expor | uma chave que funciona até ser revogada | uma credencial que expira em uma hora |
| troca | uma tarefa que alguém precisa lembrar | não é preciso |
| o que decide o acesso | ter a chave | a identidade do workflow rodando, conferida toda vez |

A federação não tira a necessidade de menor privilégio: a conta que o pipeline assume ainda deveria
só conseguir fazer o deploy. Ela tira o segredo, o que tira o jeito mais comum de roubar acesso. A
maioria dos provedores de nuvem a suporta para GitHub Actions e GitLab CI, e é a primeira coisa a
configurar antes de um pipeline ganhar qualquer acesso à nuvem.
