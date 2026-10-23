---
title: Quando o lado de fora manda um objeto inteiro
version: 1
---

A maior parte deste curso tratou de valores: um sobrenome, um termo, um recado. Esta aula trata de dois
recursos que aceitam algo maior de fora do portal: um objeto serializado, e um arquivo. Cada um
é uma versão maior da mesma pergunta, *o que o código faz com o que recebeu?*, e cada um tem um hábito
que a responde mal.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" data-fig=\"l14-two\" aria-label=\"Dois recursos que aceitam um objeto inteiro de fora do portal. Em cima, um cookie de preferências: lido com pickle, os bytes decidem que objetos são reconstruídos e que funções rodam; lido como JSON e validado, os bytes só viram strings, números, listas e dicionários, e só os valores permitidos passam. Embaixo, um envio de exame: quem envia escolhe o nome, o tipo declarado e o tamanho; o portal passa a escolher o nome, ler o tipo pelos primeiros bytes, limitar o tamanho, guardar fora da pasta servida e devolver o arquivo como download.\"><defs><marker id=\"l14-two-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"370\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">antes</text><text x=\"600\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">depois</text><rect x=\"20\" y=\"34\" width=\"180\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">um cookie do navegador</text><rect x=\"240\" y=\"34\" width=\"250\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"365.0\" y=\"62.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">pickle.loads</text><text x=\"365.0\" y=\"75.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">os bytes decidem o que é construído</text><rect x=\"510\" y=\"34\" width=\"190\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"605.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">json.loads + lista de permissão</text><text x=\"605.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">só dados, só valores permitidos</text><path d=\"M200 69 L240 69\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-two-ah-paper-dim)\"></path><rect x=\"20\" y=\"140\" width=\"180\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">um arquivo enviado</text><rect x=\"240\" y=\"140\" width=\"250\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"365.0\" y=\"168.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">nome, tipo e tamanho de quem envia</text><text x=\"365.0\" y=\"181.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">aceitos como vieram</text><rect x=\"510\" y=\"140\" width=\"190\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"605.0\" y=\"169.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">nome do portal, tipo pelos bytes,</text><text x=\"605.0\" y=\"181.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">um limite, guardado fora de static/</text><path d=\"M200 175 L240 175\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-two-ah-paper-dim)\"></path></svg>", "caption": "Nos dois recursos a correção é o mesmo movimento: o portal decide o que o lado de fora pode fazê-lo construir.", "same": ["pickle.loads"]}
```

### Desserialização

Para guardar um valor entre requisições, um programa o *serializa* em bytes e depois *desserializa*
os bytes de volta em valor. Os formatos diferem no que os bytes podem descrever:

- **Formatos de dados**, o JSON entre eles, descrevem dados: strings, números, listas, objetos com
  chaves. Lê-los constrói isso e nada mais.
- **Formatos de objetos**, o `pickle` do Python, a serialização nativa do Java, o `unserialize` do PHP,
  descrevem **como reconstruir um objeto**, incluindo que classe criar e que funções chamar ao criá-lo.
  Lê-los roda o que os bytes descrevem.

A documentação do Python põe a consequência no topo da página do `pickle`: o módulo não é seguro, e
só se deve desfazer o pickle de dados em cuja origem se confia, porque um pickle pode ser construído
para rodar código ao ser carregado. **Um cookie vem do navegador, e tudo o que vem do navegador pode ser
editado**, então um portal que desfaz o pickle de um cookie roda bytes escolhidos por quem o manda. A
regra: **nunca desserialize um formato de objetos vindo de
fora da fronteira de confiança do próprio programa; use um formato de dados, e valide o que ele traz.**

### Envio de arquivos

Um envio de arquivo entrega ao servidor um nome, um tipo declarado e alguns bytes, e os três são
escolhidos por quem envia. Os hábitos que dão errado são, cada um, um valor em que se confiou demais:

- **O nome** usado como caminho, então um nome com `../` grava em outro lugar.
- **O tipo declarado ou a extensão** tomados como verdade, então um arquivo de texto chamado `scan.pdf`
  é guardado, e depois servido, como PDF.
- **Nenhum limite de tamanho**, então uma requisição enche o disco.
- **Armazenamento numa pasta que o servidor web serve**, com o nome original, então o arquivo enviado
  volta com o tipo que um navegador resolver lhe dar.

As testemunhas que esta aula usa são comuns: um nome com `../` na frente, como um cliente com defeito
poderia mandar, um arquivo de texto puro com a extensão errada, e um arquivo simplesmente grande demais.
