---
title: A cadeia da Apple, lida em vez de executada
version: 1
---

**Esta seção é para ler, não para praticar**: tudo nela acontece no Xcode e no site de desenvolvedores da Apple,
num Mac, com uma assinatura paga do Apple Developer Program, e nada disso rodou para este curso. Ela vem da
documentação da Apple e da do Capacitor, e está aqui para as palavras quererem dizer algo quando você as
encontrar.

A assinatura da Apple tem mais partes que a do Android porque a Apple decide, para cada app, **em que aparelhos
ele pode rodar**. Quatro coisas se encontram:

| peça | o que é | de onde vem |
|---|---|---|
| **certificado** | a sua identidade de assinatura: um par de chaves no seu Mac, e um certificado que a Apple emitiu para a metade pública | o Xcode, ou a página Certificates do site de desenvolvedores |
| **App ID** | o identificador do bundle, registrado, com as capacidades que o app usa, como notificações | a página Identifiers; `com.example.studyplanner` para o planner |
| **lista de aparelhos** | os iPhones em que um build de desenvolvimento ou ad hoc pode rodar | registrados pelos identificadores deles |
| **perfil de provisionamento** | um arquivo assinado pela Apple que junta os três: este certificado pode assinar este app para estes aparelhos, ou para a loja | gerado a partir dos outros três |

**A assinatura automática do Xcode faz as quatro por você**: na aba **Signing & Capabilities** do projeto, marque
**Automatically manage signing** e escolha o seu time, e o Xcode cria o certificado, registra o App ID e busca os
perfis. A assinatura manual, com cada peça escolhida à mão, é o que times maiores e serviços de CI usam, porque
uma máquina de CI não tem uma conta da Apple conectada.

Um build para a loja é assinado com um certificado de **distribuição** e um perfil da **App Store**, e depois o
**Product, Archive** e o **Distribute App** da aula 13 o enviam ao App Store Connect. Dali ele chega aos
testadores pelo **TestFlight**, e a todo o resto pela revisão e pela App Store.

**A chave privada do certificado fica no Mac que o criou.** Exportada do Acesso às Chaves como um arquivo `.p12`,
com senha, ela é o que outro Mac ou um serviço de CI precisa para assinar como você, e merece o cuidado do
keystore do Android: dois backups, nunca num repositório.

## O app de Mac, fora da loja

Um app de Mac distribuído como `.dmg` é assinado com um certificado **Developer ID** e depois **notarizado**:
enviado à Apple com `xcrun notarytool submit`, examinado, e recebe um tíquete que o `xcrun stapler staple` anexa
ao app. O Gatekeeper, a parte do macOS que confere downloads, abre um app notarizado sem aviso. O empacotador do
Electron e o do Tauri executam esses passos quando recebem o certificado e um Apple ID; a documentação de cada
um tem uma página sobre isso.
