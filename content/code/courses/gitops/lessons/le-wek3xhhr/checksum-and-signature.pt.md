---
title: O que um checksum prova, e o que não prova
version: 1
---

**Todo download deste curso foi conferido contra um checksum**, do `kind` na aula 1 ao `flux` na aula
4. A aula 1 prometeu perguntar o que isso prova. Prova que o arquivo que você recebeu é o arquivo cujo
hash está no arquivo de checksum. Não prova quem fez nenhum dos dois.

O arquivo de checksum veio do mesmo lugar que o binário: a mesma página de release, o mesmo servidor.
Alguém que conseguisse trocar o binário ali conseguiria trocar o checksum ao lado, e o `sha256sum
--check` imprimiria `OK` para o arquivo dessa pessoa. **Um checksum protege contra um download
danificado; não protege contra uma fonte desonesta.**

Uma **assinatura** responde a segunda pergunta. Quem publica guarda uma chave privada que nunca sai das
mãos dele, e publica a chave pública correspondente uma vez, num lugar onde você a consegue de forma
independente: a documentação dele, um servidor de chaves, um repositório em que você já confia.
Assinar calcula, com a chave privada, um valor sobre o digest do artefato que só a chave privada
conseguiria produzir; verificar confere, com a chave pública, que o valor bate com o digest que você
tem. **Um artefato mudado falha, e um artefato assinado por qualquer outra pessoa também.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" xmlns=\"http://www.w3.org/2000/svg\" role=\"img\" aria-label=\"Assinar e verificar. Quem publica assina o digest do artefato com uma chave privada que nunca sai das mãos dele. A assinatura fica ao lado do artefato no registry. Um verificador com a chave pública confere a assinatura contra o digest que baixou, e recusa se não bater.\"><rect x=\"0\" y=\"0\" width=\"720\" height=\"270\" fill=\"var(--ink)\"/><rect x=\"20\" y=\"30\" width=\"170\" height=\"50\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\"/><text x=\"105.0\" y=\"50.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">chave privada</text><text x=\"105.0\" y=\"68.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">guardada por quem publica</text><rect x=\"20\" y=\"190\" width=\"170\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"105.0\" y=\"210.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">chave pública</text><text x=\"105.0\" y=\"228.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">publicada uma vez</text><rect x=\"270\" y=\"110\" width=\"180\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"360.0\" y=\"135.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">registry</text><text x=\"360.0\" y=\"153.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">artefato + assinatura</text><rect x=\"530\" y=\"110\" width=\"170\" height=\"60\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\"/><text x=\"615.0\" y=\"135.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">verificador</text><text x=\"615.0\" y=\"153.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">o lado do cluster</text><line x1=\"190\" y1=\"60\" x2=\"259.9\" y2=\"119.8\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"266,125 262.8,116.4 257.0,123.2\" fill=\"var(--paper-dim)\"/><text x=\"200\" y=\"105\" text-anchor=\"start\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">assina o digest</text><line x1=\"450\" y1=\"140\" x2=\"518.0\" y2=\"140.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"526,140 518.0,135.5 518.0,144.5\" fill=\"var(--paper-dim)\"/><text x=\"470\" y=\"130\" text-anchor=\"start\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">baixa</text><line x1=\"190\" y1=\"215\" x2=\"518.1\" y2=\"161.3\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"/><polygon points=\"526,160 517.4,156.9 518.8,165.7\" fill=\"var(--paper-dim)\"/><text x=\"330\" y=\"232\" text-anchor=\"start\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">confere com</text><text x=\"615\" y=\"200\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--amber)\">chave errada ou</text><text x=\"615\" y=\"216\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--amber)\">bytes mudados: recusa</text></svg>", "caption": "Uma assinatura amarra o digest de um artefato a uma chave. O verificador precisa só da chave pública, e essa é a única coisa que ele precisa obter de um lugar em que já confia.", "same": ["registry"]}
```

Para o GitOps a pergunta é mais afiada do que para um download, porque ninguém olha o que é publicado:
um agente baixa por referência e roda. A aula 7 fez dessa referência um digest, para os bytes não
mudarem por baixo dela. Esta aula faz o lado do cluster conferir **quem produziu esses bytes**, e faz
de um artefato sem assinatura uma recusa, e não um deploy.
