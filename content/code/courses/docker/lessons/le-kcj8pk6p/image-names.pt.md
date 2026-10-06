---
title: O que o nome de uma imagem diz
version: 1
---

**Um registry é um servidor que guarda imagens e as entrega, e o nome de uma imagem diz a qual
registry perguntar, em qual repositório procurar e qual versão levar.** A aula 3 apresentou a
especificação que os registries falam; esta aula usa um. Antes, porém, os nomes, porque quase
sempre boa parte de um nome fica de fora.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"O nome completo docker.io/library/alpine:3.22@sha256:5291… dividido em partes. docker.io é o registry, o servidor. library é o namespace, uma conta ou organização. alpine é o repositório. 3.22, depois dos dois-pontos, é a tag, um rótulo móvel. sha256:5291…, depois da arroba, é o digest, o conteúdo exato. Embaixo, o nome curto alpine:3.22 preenche docker.io e library por padrão.\"><rect x=\"20\" y=\"40\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"80\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">docker.io</text><text x=\"80\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">registry</text><text x=\"80\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o servidor</text><text x=\"145\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">/</text><rect x=\"150\" y=\"40\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"210\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">library</text><text x=\"210\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">namespace</text><text x=\"210\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">conta ou organização</text><text x=\"275\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">/</text><rect x=\"280\" y=\"40\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"340\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">alpine</text><text x=\"340\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">repositório</text><text x=\"340\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o nome da imagem</text><text x=\"405\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">:</text><rect x=\"410\" y=\"40\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"470\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">3.22</text><text x=\"470\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">tag</text><text x=\"470\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um rótulo móvel</text><text x=\"535\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">@</text><rect x=\"540\" y=\"40\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"600\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">sha256:5291…</text><text x=\"600\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">digest</text><text x=\"600\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o conteúdo exato</text><text x=\"20\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o que se costuma digitar:</text><text x=\"200\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">alpine:3.22</text><text x=\"20\" y=\"182\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o docker preenche docker.io e library, e a tag latest se nenhuma for dada</text></svg>", "caption": "Cinco partes, duas delas quase sempre omitidas. Uma tag pode ser movida para outra imagem; um digest, não.", "same": ["registry", "namespace", "tag", "digest"]}
```

`alpine:3.22` é a forma curta de **`docker.io/library/alpine:3.22`**: registry `docker.io`, o Docker
Hub; namespace `library`, as imagens oficiais; repositório `alpine`; tag `3.22`. Um nome sem tag quer
dizer `latest`, que é o assunto da aula 16. A Ana pode pedir a imagem por qualquer um dos dois nomes
e recebe a mesma:

```
ana@vm:~$ docker image ls alpine
IMAGE         ID             DISK USAGE   CONTENT SIZE   EXTRA
alpine:3.22   5291449c3df7       12.8MB         3.88MB        
ana@vm:~$ docker image inspect alpine:3.22 --format "{{json .RepoDigests}}"
["alpine@sha256:5291449c3df73caf6ed85e649dec1b9e818b39a5d8c871e97afc13e9cd5e8fa8"]
ana@vm:~$ docker image inspect docker.io/library/alpine:3.22 --format "{{.Id}}"
sha256:5291449c3df73caf6ed85e649dec1b9e818b39a5d8c871e97afc13e9cd5e8fa8
ana@vm:~$ docker image inspect alpine:3.22 --format "{{.Id}}"
sha256:5291449c3df73caf6ed85e649dec1b9e818b39a5d8c871e97afc13e9cd5e8fa8
```

Duas coisas nessa saída merecem atenção. **O id é o digest**: `sha256:5291…`, o mesmo hash que a aula
3 encontrou nomeando o índice da imagem. E o `RepoDigests` guarda o digest junto do repositório de
onde ele veio, que é como o Docker se lembra de qual conteúdo uma tag apontava quando a imagem foi
baixada.

## Tag ou digest

**Uma tag é um rótulo num registry, e quem pode enviar para o repositório pode movê-la.** A `3.22`
aponta para um build mais novo toda vez que o Alpine publica uma correção, e deve ser assim; é para
isso que serve uma tag móvel. **Um digest é o hash do conteúdo, e ninguém consegue movê-lo**:
`alpine@sha256:5291…` nomeia exatamente os bytes que a Ana tem, hoje e daqui a cinco anos, em
qualquer registry que os guarde.

Com isso, escolher o que escrever é escolher quem decide quando as coisas mudam:

| você escreve | você recebe | quem decide quando muda |
| --- | --- | --- |
| `alpine` | o que for `latest` hoje | quem publica, sem avisar |
| `alpine:3.22` | o build 3.22 mais novo | quem publica, dentro da 3.22 |
| `alpine:3.22.6` | aquela versão, refeita só para correções | quem publica, raramente |
| `alpine@sha256:5291…` | exatamente estes bytes | você, quando muda a linha |

O `FROM` de um Dockerfile e a referência de imagem de um deploy são onde a escolha mais pesa, e a
aula 16 transforma isso em hábito. A próxima etapa envia o `shelf` para um registry da própria Ana e
o traz de volta pelo digest.
