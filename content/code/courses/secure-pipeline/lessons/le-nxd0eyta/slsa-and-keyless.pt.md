---
title: Níveis da SLSA, assinatura sem chave e a porta do cluster
version: 1
---

A aula 12 desenhou a cadeia de suprimentos com as letras da SLSA, os pontos em que uma fonte, um
build ou um pacote podem ser adulterados. **A SLSA, Supply-chain Levels for Software Artifacts,
também é uma escada**: uma lista curta de níveis, cada um um conjunto de exigências sobre como um
artefato é construído e o que ele carrega sobre o próprio build. A versão 1.0 da especificação tem
uma trilha, a trilha Build, e é a ela que pertence a proveniência desta aula.

### A trilha Build, e onde este pipeline está

| nível | a exigência, em resumo | o que ela impede |
|---|---|---|
| Build L0 | nenhuma | nada |
| Build L1 | existe proveniência, que descreve como o artefato foi construído | enganos: um release construído do commit errado pode ser descoberto |
| Build L2 | o build roda numa plataforma de build hospedada, que escreve e assina ela mesma a proveniência | adulteração depois do build: uma proveniência forjada falha na assinatura |
| Build L3 | a plataforma é endurecida: execuções não interferem umas nas outras, e a chave que assina a proveniência fica fora do alcance dos próprios passos do build | adulteração durante o build, por quem controla os passos de um build |

**Seja preciso sobre este pipeline, porque é tentador afirmar mais do que ele faz.** Ele produz
proveniência para toda imagem, então atende ao Build L1. Ele assina essa proveniência, o que é a
forma do Build L2 sem a substância: o builder é um hook num laptop, rodado pela mesma pessoa que
escreve o código, então a assinatura diz "a máquina da Ana responde pelo build da Ana". E ele
claramente não é Build L3, pelo motivo que a seção do pipeline apontou: o `ci/sign.sh` vem do commit
que está sendo construído, então os próprios passos de um build conseguem ler a chave.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" data-fig=\"sp-l14-levels\" aria-label=\"Os quatro níveis da trilha Build da SLSA, de L0 a L3. Este pipeline atende ao Build L1: a proveniência existe. Ele tem a forma do L2, uma proveniência assinada, sem uma plataforma de build hospedada. O L3 exige a chave de assinatura fora do alcance dos próprios passos do build, e este pipeline não faz isso.\"><defs><marker id=\"sp-l14-levels-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"sp-l14-levels-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"50\" width=\"160\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Build L0</text><text x=\"100.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">nenhuma garantia</text><path d=\"M180 77 L198 77\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l14-levels-ah-paper-dim)\"></path><rect x=\"198\" y=\"50\" width=\"160\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"278.0\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Build L1</text><text x=\"278.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a proveniência existe</text><path d=\"M358 77 L376 77\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l14-levels-ah-paper-dim)\"></path><rect x=\"376\" y=\"50\" width=\"160\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"456.0\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Build L2</text><text x=\"456.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">plataforma hospedada assina</text><path d=\"M536 77 L554 77\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l14-levels-ah-paper-dim)\"></path><rect x=\"554\" y=\"50\" width=\"160\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"634.0\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Build L3</text><text x=\"634.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">endurecida, chave isolada</text><text x=\"278\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">este pipeline</text><path d=\"M278 38 L278 48\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l14-levels-ah-phosphor)\"></path><text x=\"456\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">só a forma: assinada, mas num laptop</text><text x=\"712\" y=\"150\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">ci/sign.sh vem do commit</text></svg>", "caption": "Cada nível acrescenta uma exigência sobre quem constrói e quem assina. Uma assinatura feita pela própria máquina de quem desenvolve não sobe a escada."}
```

Chegar ao L2 é questão de levar o build para uma plataforma que quem desenvolve não controla, como
uma CI hospedada. Chegar ao L3 exige que essa plataforma mantenha a assinatura fora do job: o job
pede, e a plataforma assina. A documentação do GitHub descreve as suas **artifact attestations**,
feitas pela action `actions/attest-build-provenance`, como proveniência de Build L2, e de L3 quando o
build roda num workflow reutilizável que o repositório que o chama não consegue editar. **Nada disso
foi executado para este curso**: os runners hospedados do GitHub não são alcançáveis da máquina de
gravação, e nada aqui pode ser assinado pelo GitHub.

### Assinatura sem chave, pela documentação do Sigstore

O `cosign.key` é um segredo que dura anos, com todos os problemas que a aula 17 descreve para
segredos que duram: ele precisa ser guardado, rotacionado e revogado quando vaza, e todo
verificador precisa aprender a nova chave pública quando ela muda. A resposta do Sigstore é a
assinatura **keyless**, sem chave guardada: ainda existe uma chave, mas ela vive alguns minutos.

1. O job de CI prova quem é para um provedor OpenID Connect. No GitHub Actions é um token de vida
   curta que o job pode pedir quando o workflow concede `id-token: write`, e que nomeia o
   repositório, o workflow e a ref.
2. O **Fulcio**, a autoridade certificadora do Sigstore, troca o token por um certificado válido por
   dez minutos, que liga um par de chaves novo àquela identidade.
3. O job assina o digest com a chave nova e joga a chave fora.
4. O **Rekor**, o log de transparência público, registra a assinatura e o certificado, para que
   qualquer um possa conferir depois que a assinatura foi feita enquanto o certificado valia.

A verificação passa então a nomear uma identidade e um emissor em vez de uma chave:

```sh
cosign verify ghcr.io/example/linkbox@sha256:<digest> \
  --certificate-identity=https://github.com/example/linkbox/.github/workflows/ci.yml@refs/heads/main \
  --certificate-oidc-issuer=https://token.actions.githubusercontent.com
```

**Esse comando não foi executado**, e não poderia ser: o Fulcio, o Rekor e a raiz de confiança que a
verificação busca são serviços públicos do Sigstore, e a máquina de gravação não alcança nenhum
deles. O repositório `example/linkbox` é uma ilustração. A aula 8 de `gitops` percorre os mesmos
quatro passos com mais detalhe. O que muda para o pipeline é a troca: com um par de chaves você
confia em quem guarda o `cosign.key`; sem chave você confia no provedor de identidade, nos serviços
do Sigstore e num log público em que toda assinatura feita em seu nome aparece, inclusive uma que
você não fez.

### Verificação na porta do cluster

Tudo o que esta aula verificou, verificou à mão ou num script. **O lugar que vê todo pod antes de
ele rodar é a admissão**, e a ValidatingAdmissionPolicy da aula 10 não dá conta deste trabalho: as
regras CEL dela leem o objeto que está sendo admitido e não conseguem buscar uma assinatura num
registry. Dois controladores de admissão conseguem, e os dois são ensinados aqui pela documentação,
**sem terem sido executados**:

| | como se escreve uma regra | o que ela confere |
|---|---|---|
| **Kyverno** | uma `ClusterPolicy` com uma regra `verifyImages`: quais imagens, qual chave ou identidade, quais atestações | a assinatura, e o predicado de uma atestação contra condições; ele pode reescrever a tag do pod para o digest que verificou |
| **Sigstore policy-controller** | uma `ClusterImagePolicy`: quais imagens, quais autoridades | a assinatura, e atestações contra uma política CUE ou Rego, só nos namespaces com o label `policy.sigstore.dev/include=true` |

A aula 8 de `gitops` mostra uma regra `verifyImages` do Kyverno para uma chave como a desta aula. Os
dois projetos publicam as imagens em registries que a máquina de gravação não alcança, e é por isso
que nenhum dos dois rodou aqui. Duas propriedades importam antes de instalar qualquer um: eles
precisam verificar **digests**, para que o pod rode exatamente o que foi conferido; e uma regra que
recusa toda imagem sem assinatura também recusa a imagem do próprio controlador no próximo reinício,
a menos que os namespaces do sistema fiquem de fora, e por isso os dois são testados primeiro num
modo de auditoria.

A política em `~/deploy.cue` é a pergunta que um controlador assim faz, e a regra da aula 10 sobre de
qual registry uma imagem pode vir também é. A diferença é que uma checagem de assinatura precisa da
resposta do registry, e por isso mora num controlador que consegue buscá-la.
