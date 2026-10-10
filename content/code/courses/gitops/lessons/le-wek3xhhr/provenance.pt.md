---
title: Como ela foi construída
version: 1
---

**Uma assinatura diz quem responde por uma imagem. A proveniência diz como ela foi feita**: de qual
código, em qual commit, com qual builder e quais argumentos. É uma declaração anexada à imagem, num
formato chamado proveniência SLSA, e o builder do Docker vem escrevendo uma para cada imagem deste
curso sem que ninguém pedisse. A aula 7 a encontrou no índice, como o manifesto marcado
`attestation-manifest`. Eis o que ela diz sobre `bulletin:1.2`:

```
ana@laptop:~/signing$ docker buildx imagetools inspect localhost:5001/bulletin:1.2 --format '{{json .Provenance.SLSA}}' | jq '.buildDefinition.externalParameters.request.root.request.args'
{
  "vcs:localdir:context": ".",
  "vcs:localdir:dockerfile": ".",
  "vcs:revision": "eeb36366262959f88c6fc5eecb28bdfc97c04060",
  "vcs:source": "http://localhost:3000/ana/bulletin.git"
}
ana@laptop:~/signing$ git -C ~/bulletin rev-parse v1.2
eeb36366262959f88c6fc5eecb28bdfc97c04060
```

Duas linhas importam: `vcs:source`, o repositório de onde veio o contexto do build, e
`vcs:revision`, o commit em que ele estava, que é exatamente o commit que a tag `v1.2` nomeia. O
Docker leu os dois do diretório `.git` no contexto do build e os escreveu no atestado da imagem,
então **a própria imagem diz de qual commit foi construída**.

**A proveniência vale o que vale quem a escreveu.** Esta foi escrita pelo builder no laptop da Ana, e
nada impede um laptop de escrever a declaração que quiser. Ela vira evidência quando um builder que o
desenvolvedor não controla a escreve e a assina: um serviço de CI que registra o repositório e o
commit que fez checkout e assina a declaração com uma identidade própria. É isso que os níveis do
SLSA graduam, de "existe proveniência" até "a proveniência é produzida por um serviço de build
endurecido que nem os mantenedores do projeto conseguem adulterar".

O `cosign` assina uma declaração dessas como **atestação**, com `cosign attest`, e a confere com
`cosign verify-attestation`, que também confere o conteúdo da declaração contra uma política:
*construída a partir deste repositório, neste builder*. Os controladores de admissão do fim desta
aula podem exigir o mesmo na porta do cluster. Este curso assina a imagem e para aí; a atestação é a
mesma chave e o mesmo registry, com uma declaração no lugar de nada.
