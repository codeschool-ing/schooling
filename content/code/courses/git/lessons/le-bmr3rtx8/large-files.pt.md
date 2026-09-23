---
title: Arquivos grandes, e o Git LFS
version: 1
---

**O Git guarda toda versão de todo arquivo, em todo clone.** Para texto isso é barato: uma linha mudada
custa alguns bytes depois de comprimida. Para uma fotografia não é, porque uma versão nova de uma
imagem é uma imagem inteira nova, e imagens não comprimem:

```
ana@vm:~/site$ du -sh .git
500K	.git
ana@vm:~/site$ du -h photo.jpg
1.0M	photo.jpg
ana@vm:~/site$ du -sh .git
3.6M	.git
```

Três versões de uma foto de 1 MB, e o repositório cresceu uns três megabytes. Apagar a foto depois não
ajudaria, pelo mesmo motivo que um segredo apagado fica: toda versão antiga continua no histórico. Toda
pessoa que clona o repositório baixa todas elas, para sempre. Os serviços de hospedagem também põem um
limite: o GitHub avisa sobre arquivos acima de 50 MB e recusa arquivos acima de 100 MB.

## Git LFS

O **Git LFS**, *Large File Storage*, é uma extensão que mantém arquivos grandes fora do histórico e põe
um pequeno arquivo de texto no lugar deles. Ele é instalado à parte do Git, e depois ligado uma vez por
conta:

```
ana@vm:~/photos$ git lfs install
Updated Git hooks.
Git LFS initialized.
ana@vm:~/photos$ git lfs track "*.jpg"
Tracking "*.jpg"
ana@vm:~/photos$ cat .gitattributes
*.jpg filter=lfs diff=lfs merge=lfs -text
ana@vm:~/photos$ git add .gitattributes front.jpg
ana@vm:~/photos$ git commit -qm "Add the shop front photo"
ana@vm:~/photos$ git lfs ls-files
9bc1b2a288 * front.jpg
ana@vm:~/photos$ git show HEAD:front.jpg
version https://git-lfs.github.com/spec/v1
oid sha256:9bc1b2a288b26af7257a36277ae3816a7d4f16e89c1e7e77d0a5c48bad62b360
size 1048576
```

O `git lfs track "*.jpg"` escreveu uma linha no `.gitattributes`, que vai num commit com o projeto
para o Git de todo mundo tratar arquivos `.jpg` do mesmo jeito. Daí em diante, adicionar uma foto a
guarda com o LFS, e o `git lfs ls-files` lista os arquivos que ele está administrando.

O último comando mostra o que o histórico guarda de fato. **Não a foto: um ponteiro, de três linhas**
— a versão do formato do ponteiro, o hash da foto e o tamanho dela. O megabyte em si foi para um
armazenamento separado, e no `git push` ele vai para o armazenamento LFS do serviço de hospedagem, não
para o repositório. Um clone baixa os ponteiros com o histórico e busca só as versões das fotos de que
de fato faz checkout.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 234\" role=\"img\" aria-label=\"À esquerda, o repositório que todo clone copia: cada commit guarda, para o front.jpg, só um ponteiro de três linhas com a versão, o hash e o tamanho. À direita, um armazenamento LFS separado no serviço de hospedagem guarda o megabyte de cada versão. Uma seta do ponteiro até o arquivo guardado diz: buscado só para o que está em checkout.\"><defs><marker id=\"lf-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"320\" height=\"170\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"180\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">o repositório — todo clone</text><rect x=\"40\" y=\"70\" width=\"280\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"52\" y=\"87\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">front.jpg</text><text x=\"150\" y=\"87\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">oid sha256:… size 1048576</text><rect x=\"40\" y=\"112\" width=\"280\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"52\" y=\"129\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">front.jpg</text><text x=\"150\" y=\"129\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">oid sha256:… size 1048576</text><rect x=\"40\" y=\"154\" width=\"280\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"52\" y=\"171\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">front.jpg</text><text x=\"150\" y=\"171\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">oid sha256:… size 1048576</text><rect x=\"440\" y=\"30\" width=\"260\" height=\"170\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"570\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">armazenamento LFS</text><text x=\"570\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no serviço de hospedagem</text><rect x=\"470\" y=\"70\" width=\"200\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"570\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1 MB</text><path d=\"M322 87 L466 87\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lf-ah)\" stroke-dasharray=\"3 3\"></path><rect x=\"470\" y=\"112\" width=\"200\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"570\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1 MB</text><path d=\"M322 129 L466 129\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lf-ah)\" stroke-dasharray=\"3 3\"></path><rect x=\"470\" y=\"154\" width=\"200\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"570\" y=\"171\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1 MB</text><path d=\"M322 171 L466 171\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lf-ah)\" stroke-dasharray=\"3 3\"></path><text x=\"180\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">um ponteiro de três linhas por versão</text><text x=\"570\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o próprio arquivo, cada versão</text><text x=\"393\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">buscado só para o que</text><text x=\"393\" y=\"221\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">está em checkout</text></svg>", "caption": "O histórico carrega alguns bytes por versão. Os megabytes ficam num lugar só e viajam só quando alguém precisa deles."}
```

## Quando usar, e quanto custa

Use para arquivos grandes **e** que mudam: arquivos de design, imagens, áudio, conjuntos de dados,
builds compilados que você realmente precisa guardar. Não use para tudo: um logo pequeno que nunca muda
não custa nada no Git comum.

Os custos são reais. Todo mundo na equipe precisa do Git LFS instalado, ou recebe os ponteiros em vez
dos arquivos. Os serviços de hospedagem dão uma cota gratuita de armazenamento e transferência LFS e
cobram além dela. E passar para o LFS arquivos que já foram para commits reescreve o histórico, com a
regra da aula 6 junto. Decidir antes do primeiro arquivo grande ir para commit é muito mais barato do
que decidir depois.
