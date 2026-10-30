---
title: O que uma assinatura prova, e o que ela não prova
version: 1
---

**Uma crença comum é que a assinatura prova que o app é seguro, ou que o Google o avalizou. Ela
não prova nenhuma das duas coisas.** Uma assinatura Android é feita com uma chave que você mesmo
gerou, num certificado que você mesmo assinou; nenhuma autoridade está por trás dele. O que ela
prova é mais estreito e mais útil: **toda versão deste app foi assinada por quem tem a mesma
chave.**

É nesse fato estreito que o sistema se apoia. Quando chega uma atualização, o Android compara o
certificado do pacote novo com o do app instalado. Se batem, a atualização substitui o app e mantém
os dados dele. Se não batem, a instalação é recusada, e nenhuma configuração do celular passa por
cima disso. Um estranho consegue publicar um app que se parece com o seu. Ele não consegue
publicar uma *atualização* do seu.

## A chave é o app

Duas coisas juntas fazem de um app Android o mesmo app durante toda a vida dele: o **nome do
pacote** no manifesto e a **chave de assinatura**. Mude qualquer uma e o sistema enxerga outro
app. Um nome de pacote novo é uma ficha nova, sem avaliações e sem instalações; uma chave nova no
mesmo nome de pacote é uma atualização que todo celular recusa.

| o que muda | o que faz um celular com a versão antiga |
|---|---|
| o código, a versão, o ícone | instala a atualização e mantém os dados |
| a chave de assinatura | recusa a atualização: as assinaturas não batem |
| o nome do pacote | instala um segundo app, separado, ao lado do primeiro |

**É por isso que uma chave perdida costumava acabar com um app.** Antes de o Google Play guardar
chaves para os desenvolvedores, perder o arquivo do keystore, ou a senha dele, significava que o
app nunca mais poderia ser atualizado. A única saída era um nome de pacote novo, uma ficha nova e
pedir a cada usuário que desinstalasse o app antigo e achasse o novo. Alguns nunca fizeram isso. A
seção "Play App Signing", mais adiante, é como isso deixou de ser o fim de costume.

## Duas coisas que uma chave também decide

**Permissões entre os seus próprios apps.** Uma permissão declarada com proteção `signature` só é
concedida a apps assinados com a mesma chave. Dois apps do mesmo desenvolvedor podem compartilhar
dados desse jeito, e um app assinado por outra pessoa não consegue pedi-la.

**Quais serviços acreditam que o app é seu.** Os serviços do próprio Google identificam um app pelo
nome do pacote *e* pela impressão digital SHA-256 do certificado de assinatura. Um login que
funciona no build de debug e falha no de release é, na maioria das vezes, uma impressão digital
registrada para a chave de debug e não para a de release. O Android Studio assina os builds de
debug com uma chave de debug gerada automaticamente em `~/.android/debug.keystore`, que é
diferente em cada computador e nunca é o que a loja recebe.

## A mesma ideia nas outras duas

| | Android | iOS | React Native |
|---|---|---|---|
| quem emite o certificado | você, com o `keytool` | a Apple, a partir de um pedido seu | cada plataforma, como acima: o JavaScript está dentro de um app nativo |
| o que a loja confere | a mesma chave assina toda atualização | o build foi assinado pelo certificado de distribuição da sua equipe | as duas coisas, uma por plataforma |
| o que um celular confere | a assinatura bate com a do app instalado | a assinatura da Apple no app | as duas coisas, uma por plataforma |

A lição 2 é a metade iOS, que funciona de um jeito diferente o bastante para precisar de uma lição
própria: lá, a Apple é a autoridade, e os certificados vencem todo ano.
