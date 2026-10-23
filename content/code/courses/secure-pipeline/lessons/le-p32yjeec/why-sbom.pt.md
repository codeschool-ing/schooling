---
title: Para que serve um SBOM
version: 1
---

Um software bill of materials costuma ser apresentado como um documento de conformidade: uma lista
que um cliente ou um regulador pede, produzida uma vez, arquivada em algum lugar. Lido assim é
burocracia, e times que o tratam como burocracia fazem um antes de uma auditoria e nunca mais o abrem.
**Um SBOM se paga numa manhã específica: aquela em que chega um aviso de segurança e alguém pergunta
"somos afetados?"**

### A manhã do aviso

Em 29 de março de 2024 o backdoor no xz 5.6.0 e 5.6.1 se tornou público, e a aula 12 contou a
história. Toda organização que rodava Linux tinha a mesma pergunta naquele dia: quais das nossas
imagens e máquinas contêm o xz, em qual versão, e onde estão rodando? Há dois jeitos de responder.

- **Sem um registro**, alguém baixa toda imagem de todo registry, escaneia ou abre cada uma, e entra em
  toda máquina, enquanto o aviso está no noticiário e a lista de imagens não para de crescer. Leva
  dias, e a resposta só é tão boa quanto a lista de lugares que alguém lembrou de olhar.
- **Com um registro feito no build**, a pergunta é uma consulta sobre arquivos que já existem: uma
  lista por imagem, cada uma nomeando todo pacote e toda versão lá dentro. Leva minutos, e cobre imagens
  que já não rodam em lugar nenhum, o que importa quando a pergunta é "estávamos expostos no mês
  passado?".

Esse segundo arranjo é todo o argumento a favor de um SBOM. **A lista precisa existir antes da
pergunta**, porque na manhã do aviso o build que fez a imagem já sumiu faz tempo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" data-fig=\"sp-l13-life\" aria-label=\"A vida de um SBOM. No dia do build, o pipeline constrói e envia a imagem e escreve o SBOM dela ao lado da execução. Meses depois um aviso é publicado. Sem o SBOM, alguém baixa e inspeciona cada imagem e cada máquina, o que leva dias. Com ele, uma consulta sobre os arquivos guardados responde em minutos, inclusive para imagens que já não rodam.\"><defs><marker id=\"sp-l13-life-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"sp-l13-life-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">dia do build</text><rect x=\"20\" y=\"35\" width=\"140\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">build e push</text><rect x=\"185\" y=\"35\" width=\"140\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"255.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">escrever o SBOM</text><rect x=\"20\" y=\"110\" width=\"305\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"172.5\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">guardado ao lado da execução</text><path d=\"M160 58 L183 58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l13-life-ah-paper-dim)\"></path><path d=\"M255 81 L255 108\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l13-life-ah-phosphor)\"></path><line x1=\"352\" y1=\"15\" x2=\"352\" y2=\"225\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 4\"></line><text x=\"380\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">meses depois</text><rect x=\"380\" y=\"35\" width=\"150\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"455.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">chega um aviso</text><rect x=\"555\" y=\"35\" width=\"150\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">somos afetados?</text><path d=\"M530 58 L553 58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l13-life-ah-paper-dim)\"></path><rect x=\"380\" y=\"110\" width=\"325\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"542.5\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">sem ele</text><text x=\"542.5\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">baixar e abrir cada imagem: dias</text><rect x=\"380\" y=\"175\" width=\"325\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"542.5\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">com ele</text><text x=\"542.5\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">uma consulta nos arquivos: minutos</text><path d=\"M325 140 L340 140 L340 198 L378 198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#sp-l13-life-ah-phosphor)\"></path></svg>", "caption": "A lista precisa ser escrita no dia do build, porque a pergunta chega muito depois de o build sumir."}
```

### O que há num SBOM

Um SBOM é uma lista legível por máquina dos componentes de um software, cada um com identidade
suficiente para ser comparado com outros dados: um nome, uma versão, um fornecedor, a licença, muitas
vezes um hash, e um **package URL**, o `purl`, que nomeia um pacote sem ambiguidade entre ecossistemas:
`pkg:pypi/gunicorn@22.0.0` é o gunicorn do PyPI, `pkg:deb/debian/libc6@2.41-12+deb13u4` é um pacote do
Debian. SBOMs melhores também registram qual componente depende de qual.

Em 2021 a NTIA, dos Estados Unidos, publicou os "elementos mínimos" que um SBOM deveria ter. Eles são uma lista útil para ler um: o fornecedor, o nome e a versão do componente, um identificador único como
o purl, as relações de dependência, o autor do SBOM e um carimbo de tempo. O Cyber Resilience Act da
União Europeia também exige que fabricantes de produtos com software elaborem um. Você vai conferir a
saída do syft contra essa lista nas próximas seções.

### O que ele não é

- **Não é um relatório de vulnerabilidades.** Um SBOM lista o que está lá; se algo é vulnerável é uma
  pergunta feita à lista, hoje, contra os avisos de hoje. É por isso que o mesmo SBOM vale ser
  escaneado de novo no mês que vem, e a seção sobre scan mostra isso.
- **Não é prova de nada.** Uma lista que qualquer um poderia ter editado diz o que o autor escreveu. A
  aula 14 a assina e a anexa à imagem, o que a transforma numa afirmação feita pelo pipeline.
- **Não é completo por definição.** Contém o que o gerador conseguiu achar. A última seção desta aula
  nomeia o que o syft não consegue ver na imagem do linkbox.

### A primeira pergunta do linkbox

A aula 8 notou que a imagem do linkbox leva um pacote, `packaging`, que o `requirements.txt` nunca
fixou, e a aula 12 prometeu que a lista o encontraria. Essa é a pergunta que esta aula responde com um
SBOM, e a resposta mostra algo que nenhum scan do `requirements.txt` conseguiria: **a imagem contém o
que o instalador decidiu instalar, que é mais do que o projeto pediu.**
