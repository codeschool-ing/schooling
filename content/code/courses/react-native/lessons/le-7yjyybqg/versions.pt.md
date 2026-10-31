---
title: Nomes de versão e números de versão
version: 1
---

**Todo release tem duas versões, uma para as pessoas e outra para as lojas.**

| | para as pessoas | para a loja |
|---|---|---|
| no `app.json` | `version`, como `"1.2.0"` | `android.versionCode`, `ios.buildNumber` |
| o que é | o que a página da loja mostra | um número que só sobe |
| regra | qualquer coisa legível | todo envio maior que o anterior, ou é recusado |

O `1.2.0` pode ser enviado várias vezes enquanto se testa, cada uma com um `versionCode` maior; a página da
loja continua mostrando `1.2.0`. Esquecer de aumentar o número é a recusa de envio mais comum, que é o motivo
de o `autoIncrement` do `eas.json` existir.

**Um build também tem uma *runtime version*, de que a aula 21 precisa.** Ela descreve o lado nativo, as
bibliotecas com código nativo e as versões delas, e decide quais atualizações over-the-air um build pode
receber. O número da versão diz quando; a runtime version diz o que o build consegue rodar.
