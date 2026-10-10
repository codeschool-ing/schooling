---
title: Assinar sem uma chave para perder
version: 1
---

**Uma chave privada é um segredo que dura anos**, e tudo o que este curso diz sobre segredos nas aulas
9 a 11 vale para ela: ela precisa ser guardada, protegida, trocada, e revogada quando vaza, e uma chave
que assinou releases por três anos não pode ser trocada sem que todo verificador aprenda a nova. O
Sigstore, o projeto a que o `cosign` pertence, oferece um caminho em volta da chave de vida longa,
chamado assinatura **keyless**. Ainda há uma chave; ela vive alguns minutos.

1. Quem assina, quase sempre um job de CI, prova quem é a um provedor OpenID Connect: GitHub Actions,
   GitLab, Google, o da própria empresa. A prova é um token de vida curta que cita a identidade, como
   *o workflow de release do repositório X, na tag v1.3*.
2. O **Fulcio**, a autoridade certificadora do Sigstore, troca esse token por um certificado válido por
   dez minutos, que liga um par de chaves novo à identidade.
3. Quem assina assina o digest com essa chave, e a chave é jogada fora.
4. O **Rekor**, um log público de transparência, registra a assinatura e o certificado, com um carimbo
   de tempo provando que a assinatura aconteceu enquanto o certificado valia.

Verificar faz então uma pergunta diferente do `--key cosign.pub` deste curso: não "isto foi assinado
por esta chave?", e sim **"isto foi assinado por esta identidade, segundo este emissor?"**. Para um
release construído pelo GitHub Actions, a verificação cita o workflow e o emissor de tokens do GitHub:

```sh
cosign verify ghcr.io/fluxcd/source-controller:v1.9.6 \
  --certificate-identity-regexp='^https://github.com/fluxcd/' \
  --certificate-oidc-issuer=https://token.actions.githubusercontent.com
```

**Esse comando não foi executado para este curso**: a máquina de gravação não alcança os serviços
públicos do Sigstore, o Fulcio, o Rekor e a raiz de confiança que a verificação baixa. É assim que você
confere que uma imagem do Flux que está para rodar foi construída pelo workflow de release do próprio
Flux, e nada mais nesta aula muda com o keyless: a assinatura continua ao lado do artefato, e o Flux e
os controladores de admissão das próximas seções aceitam uma identidade e um emissor no lugar de uma
chave pública.

A troca é de confiança. Com um par de chaves você confia em quem guarda a chave privada. Com keyless
você confia no provedor de identidade e nos serviços do Sigstore, e o log de transparência deixa
qualquer um conferir depois que nenhuma assinatura foi feita num nome sem ser registrada. **Para
projetos de código aberto o keyless virou a norma**, porque não há chave para um mantenedor perder.
Uma empresa pode rodar o próprio Fulcio e o próprio Rekor para ter o mesmo arranjo dentro de casa.
