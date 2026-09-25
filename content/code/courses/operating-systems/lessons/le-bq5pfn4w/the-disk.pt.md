---
title: APFS: um contêiner, vários volumes
version: 1
---

Na aula 2 o Windows cortou o disco em partições, cada uma com tamanho fixo. O macOS formata o disco
interno com **APFS**, o *Apple File System*, e faz diferente.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Um disco interno de Mac desenhado como um contêiner APFS, um só estoque de espaço livre, com cinco volumes. Macintosh HD, o sistema, selado e só de leitura. Macintosh HD - Data, seus arquivos, apps e ajustes, onde tudo muda. Preboot, o que dá a partida no Mac. Recovery, o sistema de reparo. E VM, o swap. Nenhum tem tamanho fixo; cada um pega espaço do mesmo estoque conforme precisa. O Finder mostra um disco só, Macintosh HD.\"><defs><marker id=\"ap-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"20\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">o disco interno</text><rect x=\"20\" y=\"34\" width=\"680\" height=\"150\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"36\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">um contêiner APFS: um só estoque de espaço livre</text><rect x=\"36\" y=\"70\" width=\"150\" height=\"96\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"111.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Macintosh HD</text><text x=\"111.0\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o sistema</text><text x=\"111.0\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">selado, só leitura</text><rect x=\"196\" y=\"70\" width=\"190\" height=\"96\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"291.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Macintosh HD - Data</text><text x=\"291.0\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">seus arquivos, apps, ajustes</text><text x=\"291.0\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">onde tudo muda</text><rect x=\"396\" y=\"70\" width=\"92\" height=\"96\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"442.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Preboot</text><text x=\"442.0\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o que dá a partida</text><rect x=\"498\" y=\"70\" width=\"100\" height=\"96\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"548.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Recovery</text><text x=\"548.0\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o sistema de reparo</text><rect x=\"608\" y=\"70\" width=\"76\" height=\"96\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"646.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">VM</text><text x=\"646.0\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">swap</text><path d=\"M36 196 L386 196\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M36 190 L36 196\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M386 190 L386 196\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"211\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">O Finder mostra um disco só: Macintosh HD</text></svg>", "caption": "Diferente das partições do Windows da aula 2, nenhum volume tem tamanho próprio. Eles dividem o espaço livre do contêiner, e o Finder mostra os dois primeiros como um disco só.", "same": ["swap"]}
```

O disco guarda um **contêiner APFS**, e o contêiner guarda **volumes**. Um volume parece um disco no
Finder, mas não tem tamanho próprio: todo volume pega espaço do espaço livre comum do contêiner conforme
precisa. Ninguém tem que adivinhar de antemão o tamanho do sistema.

## Dois volumes que parecem um

Os dois que importam são estes:

- **Macintosh HD** é o sistema. Ele é **selado**: só de leitura, e conferido contra uma assinatura da
  Apple toda vez que o Mac inicia. Nada, nem um administrador, grava nele com o macOS rodando. Uma
  atualização o substitui inteiro.
- **Macintosh HD - Data** guarda tudo o que muda: as pastas dos usuários, os apps que eles instalam,
  os ajustes.

O Finder junta os dois e mostra um disco só, **Macintosh HD**. É essa divisão que torna possível a
primeira opção da seção 04: o macOS pode ser trocado sem mexer nos dados ao lado.

## Criptografia desde o começo

No Apple silicon, e nos Macs Intel com o chip de segurança T2, o disco interno está **sempre
criptografado pelo hardware**. O que o **FileVault** acrescenta é que a chave fica trancada atrás da
senha de um usuário, então o disco não pode ser lido até alguém entrar. A seção 05 o liga.

É também por isso que apagar um Mac moderno é rápido. Destruir a chave torna ilegível cada byte do
disco, então nada precisa ser sobrescrito.

## Vendo isso

O **Utilitário de Disco**, em *Aplicativos > Utilitários* e na tela da Recuperação, mostra o contêiner e
seus volumes; escolha *Visualizar > Mostrar Todos os Dispositivos*, senão ele mostra só os volumes. Pelo
Terminal:

```sh
diskutil list                            # every disk, container and volume
diskutil apfs list                       # the APFS containers, with shared free space
```

**Nenhum dos dois foi rodado para esta aula.** Um disco externo para Windows e Mac é formatado em
**exFAT**, que os dois leem e gravam; um disco APFS não é legível no Windows sem software extra.
