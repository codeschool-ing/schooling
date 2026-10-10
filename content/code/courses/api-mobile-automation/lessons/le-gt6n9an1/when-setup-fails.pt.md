---
title: Quando a instalação mobile falha
version: 1
---

A metade mobile falha em mais lugares que a primeira, porque há mais programas envolvidos: o Android
Studio, o Gradle, o emulador, o adb, o app e o boxoffice, e qualquer um deles pode parar os outros.
Estas são as falhas mais frequentes, cada uma com o sinal que dá e o que fazer. Só a primeira foi
produzida na máquina de gravação, que por acaso é um computador que a mostra; as outras são descritas
a partir das próprias mensagens do Android.

## O emulador não inicia: sem aceleração

Num computador cuja virtualização do processador está desligada, ou ausente, o emulador se recusa a
rodar uma imagem x86_64. O Android Studio mostra um diálogo; a linha de comando diz por quê:

```
ana@laptop:~$ emulator -accel-check
accel:
3
KVM requires a CPU that supports vmx or svm
accel
```

Essa é a máquina onde este curso foi gravado: uma máquina virtual sem virtualização repassada, e é por
isso que nenhum emulador aparece nesta metade. A correção num computador de verdade fica nas
configurações do firmware (*Intel Virtualization Technology*, *VT-x*, *SVM* ou *AMD-V*, conforme o
fabricante), e no Windows também em *Ativar ou desativar recursos do Windows*, onde a *Plataforma do
Hipervisor do Windows* precisa estar marcada. Rode `emulator -accel-check` de novo depois: num
computador que roda o emulador, ele nomeia o acelerador que encontrou em vez de `KVM requires a CPU`.
Se o seu computador não pode tê-la de jeito nenhum, siga o caminho do celular da seção 03.

## O `adb devices` não lista nada, ou diz `unauthorized`

Uma lista vazia com um emulador aberto significa que o adb iniciou antes do emulador e o perdeu de
vista; `adb kill-server` e depois `adb devices` o reiniciam do zero. Com um celular, `unauthorized` ao
lado do número de série significa que o celular ainda está perguntando se confia neste computador:
desbloqueie-o e aceite o aviso na tela. Se ele nunca pergunta, tente outro cabo; muitos cabos de
carregar não transmitem dados.

## O app mostra *Could not reach the box office*

O app rodou e a requisição dele falhou. Em ordem:

1. **O boxoffice está rodando?** `curl localhost:8080/health` no seu computador, como na lição 1.
2. **O app pergunta no endereço certo?** `10.0.2.2` a partir de um emulador, `localhost` a partir de
   um celular depois de `adb reverse tcp:8080 tcp:8080`. O endereço é o `baseUrl` em `Shows.kt`.
3. **A regra de rede chegou?** O Android recusa HTTP puro para qualquer endereço que o arquivo de
   segurança de rede da seção 05 não nomeia, e registra isso no log do aparelho, que o Android Studio
   mostra na janela *Logcat*, com as palavras `CLEARTEXT communication to 10.0.2.2 not permitted by
   network security policy`. Essa frase significa que o arquivo falta, tem o nome errado ou não é
   mencionado no manifesto.
4. No Windows com o boxoffice no WSL, abra `http://localhost:8080/health` num navegador do Windows. Se
   o Windows não o alcança, o emulador também não.

## O build falha com uma referência não resolvida

O erro do Gradle nomeia o arquivo e a linha, como `Unresolved reference 'banner'` ou parecido. Quase
sempre um arquivo foi salvo na pasta errada, com o nome errado, ou um dos nove não foi salvo. Compare
as pastas na visão *Project* com os caminhos da seção 05; um layout salvo em `res/layouts` em vez de
`res/layout` é o caso clássico.
