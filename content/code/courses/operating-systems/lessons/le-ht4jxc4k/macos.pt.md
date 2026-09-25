---
title: macOS: a App Store, imagens de disco e o Homebrew
version: 1
---

A **App Store do Mac** é o caminho da loja no Mac, e os apps dela ficam isolados e se atualizam
sozinhos. Muitos apps profissionais não estão nela, e chegam de uma de duas outras formas:

- **Um `.dmg`**, uma *imagem de disco*. Abri-lo o monta como um pendrive, em geral mostrando o app e uma
  seta para *Aplicativos*. **Instalar é arrastar o app para Aplicativos**, e remover é arrastá-lo para o
  Lixo. Ejete a imagem depois; rodar o app de dentro dela é o motivo mais comum de "ele some depois de
  reiniciar".
- **Um `.pkg`**, um pacote instalador, que passa por etapas e pede a senha de um administrador porque
  grava fora das pastas do usuário.

## Gatekeeper

A primeira vez que um app baixado abre, o macOS o confere. O *Gatekeeper* permite apps da App Store e
de *desenvolvedores identificados* cujos apps a Apple *notarizou*, examinou e assinou. Qualquer
outro é recusado com uma mensagem dizendo que não pode ser verificado. O próprio download carrega uma
marca, o atributo de *quarentena*, dizendo de onde veio; é essa marca que dispara a checagem.

## Homebrew

O Mac não tem gerenciador de pacotes da Apple. O **Homebrew** é o que quase todo mundo usa, instalado
uma vez a partir do site dele:

```sh
brew search --cask firefox                  # Homebrew: formulae are tools, casks are apps
brew install tree
brew install --cask firefox
brew upgrade                                # everything Homebrew installed
xattr -l ~/Downloads/Tool.dmg               # com.apple.quarantine: where it came from
```

**Nada disso foi rodado para esta aula.** As *formulae* são ferramentas de linha de comando, como no
apt; os *casks* são apps comuns do Mac, baixados dos fabricantes como o winget faz. O `brew upgrade`
atualiza tudo o que ele instalou.

## A mesma regra nos três

**Instale pelo caminho mais gerenciado que tiver o programa**, mantenha uma lista do que cada máquina
tem, e remova o que ninguém usa. Todo programa instalado é mais uma coisa que precisa de atualizações, e
a aula 16 é sobre o que acontece com os que não as recebem.
