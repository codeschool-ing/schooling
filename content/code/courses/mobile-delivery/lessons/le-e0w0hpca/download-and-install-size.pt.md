---
title: Tamanho de download e tamanho instalado
version: 1
---

**Um app tem dois tamanhos, e eles respondem a perguntas diferentes.** O **tamanho de download** é o
que viaja pela rede até o celular, comprimido; ele decide quanto tempo a instalação leva e quanto do
plano de dados de alguém ela custa. O **tamanho instalado** é o que o app ocupa no celular depois de
desempacotado, e ele cresce conforme o app guarda dados; ele decide se o app é o apagado quando o
celular enche.

## O que as lojas impõem e mostram

- **O Google Play limita o download comprimido de um app bundle a 200 MB**, segundo a documentação do
  Android sobre reduzir o tamanho do app, lida em outubro de 2026. Apps maiores entregam o resto pelo
  Play Feature Delivery e pelo Play Asset Delivery, depois da instalação.
- **A Apple limita o tamanho descomprimido de um app a 4 GB**, pela referência do App Store Connect
  sobre tamanhos de build. No celular, as configurações do iPhone deixam a pessoa escolher ser
  perguntada antes de um app grande baixar pelos dados móveis.
- **As duas lojas mostram o tamanho na ficha**, a página da lição 4, ao lado da nota e das capturas,
  então ele é lido antes da decisão.

A documentação do Android diz com todas as letras: as pessoas muitas vezes evitam baixar apps que
parecem grandes demais, **principalmente em mercados emergentes**, onde os aparelhos têm menos espaço
e os dados custam mais. Para um planner de estudos voltado a estudantes no Brasil, esse é o público,
e não um caso de canto.

## O que deixa um app grande

| o quê | por que cresce | a cura |
|---|---|---|
| imagens | uma cópia por densidade de tela, cada uma maior | publicar por densidade, o que a próxima seção mede; vetores onde couberem |
| bibliotecas nativas | uma cópia por arquitetura de processador | publicar por arquitetura; app bundles fazem isso |
| código | bibliotecas trazidas para uma função só | o R8 remove o que nada usa, lição 13 |
| fontes, sons, modelos | acrescentados uma vez, guardados para sempre | baixá-los sob demanda, depois da instalação |

## A mesma pergunta nas três plataformas

O tamanho de um app em Kotlin é medido a partir do app bundle dele com a ferramenta da próxima seção.
O de um app em Swift é informado pelo **App Thinning Size Report** do Xcode, que lista o tamanho de
cada variante de aparelho que a App Store vai produzir; a Apple fatia por aparelho com o mesmo
espírito. Um app React Native leva os dois, mais o bundle JavaScript e o motor Hermes, e é por isso
que o menor tamanho dele começa mais alto que o de um app nativo.
