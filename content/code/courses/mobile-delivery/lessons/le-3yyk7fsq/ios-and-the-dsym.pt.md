---
title: iOS, e o dSYM
version: 1
---

**Um binário de release do iOS não leva nome de função nenhum; um crash nele é uma lista de
endereços, e o arquivo que os transforma de volta em nomes é o dSYM.** É a mesma ideia das duas
seções anteriores com outro mecanismo, e precisa de um Mac, então esta seção é lida. *Escrita a
partir da documentação da Apple sobre diagnosticar problemas com relatórios de crash, outubro de
2026; não rodada.*

## O que um crash iOS cru diz

Um relatório de crash do sistema, ou de um coletor que não tinha os símbolos, tem quadros na forma
deste, um por linha, com o nome do binário e dois endereços. Ele foi escrito aqui para mostrar a
forma, e não tirado de um crash de verdade:

```
3   Planner   0x0000000102f4a8c4 0x102f30000 + 108740
```

O primeiro endereço é onde o código estava rodando; o segundo é onde o binário do app foi carregado
na memória daquela vez. A diferença entre eles, 108740 aqui, é a mesma em todo celular que roda
este build, e é o que o dSYM consegue procurar.

## O dSYM e o UUID dele

Quando o Xcode arquiva um release, ele grava as informações de depuração num bundle separado,
`Planner.app.dSYM`, e as tira do app. **O binário e o dSYM dele compartilham um UUID**, gravado nos
dois pelo linker. Um dSYM de qualquer outro build, mesmo do mesmo commit, tem outro UUID e é
recusado: a mesma regra do mapeamento do R8, imposta pelo próprio arquivo.

Num Mac, o `dwarfdump --uuid` imprime o UUID de cada um, e o `atos` transforma um endereço numa
função e numa linha:

```sh
dwarfdump --uuid Planner.app.dSYM
atos -arch arm64 -o Planner.app.dSYM/Contents/Resources/DWARF/Planner -l 0x102f30000 0x0000000102f4a8c4
```

*Nenhum dos dois foi rodado aqui.* O **Organizer** do Xcode faz o mesmo para os crashes que a Apple
coleta, e o Crashlytics e o Sentry fazem para os deles, depois que o dSYM de cada build é enviado.

## De onde vem o dSYM

- **O archive do Xcode** o guarda dentro do `.xcarchive`, que o pipeline deveria guardar como
  artefato.
- **O bitcode acabou**, desde o Xcode 14, então o dSYM feito pelo seu build é o que bate com o que a
  Apple distribui. Instruções antigas sobre baixar dSYMs do App Store Connect são sobre builds com
  bitcode e não valem mais.
- **O `build_app` do Fastlane** grava o dSYM ao lado do `.ipa`, e o Crashlytics e o Sentry têm um
  comando de envio que uma lane pode chamar depois dele.

## A mesma regra, três vezes

| | o build grava | ele é casado por | sem ele |
|---|---|---|---|
| Android | `mapping.txt` | o identificador do mapeamento, na pilha | `a.b` e números de linha inventados |
| iOS | `.dSYM` | o UUID do binário | endereços |
| React Native | o source map | o bundle com que ele foi feito | linha 1 e uma coluna |
