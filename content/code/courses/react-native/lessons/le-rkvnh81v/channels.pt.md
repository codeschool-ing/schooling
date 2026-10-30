---
title: Canais, liberação gradual, e o caminho de volta
version: 1
---

**O EAS Update é o servidor de atualizações do Expo**, e vale a pena aprender as palavras dele, porque elas
dizem para onde uma atualização vai:

- **Um branch** é uma linha de atualizações, como um branch do git: cada `eas update` acrescenta uma a um
  branch.
- **Um canal** é fixado num build quando ele é construído: o perfil `production` do `eas.json` ganha o canal
  `production`, o `preview` ganha o `preview`. Um build pede atualizações ao canal dele.
- **Um canal aponta para um branch.** Apontar o `production` para outro branch muda o que todo build de
  produção recebe, sem construir nada.

Então o caminho seguro para uma correção é o que testa antes:

1. `eas update --branch preview --message "Keep the week total when the server is slow"` publica para os
   builds de preview, que quem testa tem.
2. Depois de experimentada lá, a mesma atualização vai para a produção, **primeiro para uma porcentagem**: o
   EAS Update consegue mandar uma atualização para, digamos, 10 por cento dos builds de produção, e aumentar
   a fatia enquanto os relatórios de falha continuam quietos.
3. Se der errado, o **`eas update:rollback`** aponta o canal de volta para a atualização anterior, ou para o
   bundle embutido do próprio build, que todo build carrega.

*Nenhum desses comandos foi executado para este curso, porque os servidores do Expo recusaram a máquina que
o gravou; eles vêm da documentação do Expo, para o `eas-cli` 27.*

## Quando a própria atualização quebra

O `expo-updates` protege um celular do pior caso: uma atualização cujo JavaScript cai antes de o app ter
aberto direito é marcada como ruim, e a abertura seguinte roda a atualização anterior, ou o bundle embutido.
Isso é uma rede, não um plano. **Uma atualização é um release**: passa pelos mesmos testes, pela mesma revisão
de uma pessoa, e por um canal com quem testa antes do canal com todo mundo, porque, ao contrário de um
release de loja, ela chega a todo celular em horas.

**E uma atualização nunca consegue consertar um build que não abre.** Se uma falha nativa acontece antes de o
JavaScript rodar, aquele build nunca vai baixar atualização nenhuma. Esse caso é um release de loja.
