---
title: Duas plataformas, dois donos
version: 1
---

**Um celular roda um de dois sistemas operacionais, e quem é dono de cada um explica a maior parte
das diferenças que você vai encontrar.** O Android é feito pelo Google e distribuído de graça: o
código-fonte é publicado como Android Open Source Project, e centenas de fabricantes montam
aparelhos sobre ele, do celular mais barato da banca da esquina a um tablet que dobra. O iOS é feito
pela Apple para o iPhone, e só a Apple fabrica iPhones. Uma empresa escreve o sistema, desenha o
hardware e mantém a única loja que a maioria dos usuários vai ver na vida.

A imagem comum é a de dois rivais fazendo o mesmo trabalho com cores diferentes. O trabalho é o
mesmo, e a maior parte das regras que este curso ensina também. **O dono não é**, e ele decide três
coisas que quem desenvolve sente toda semana:

| | Android | iOS |
|---|---|---|
| quem fabrica os aparelhos | muitos fabricantes, em toda faixa de preço | só a Apple |
| como o sistema é atualizado | o fabricante decide quando, e por quanto tempo | a Apple entrega cada versão a todo iPhone suportado ao mesmo tempo |
| de onde vêm os apps | Google Play, outras lojas e um arquivo que o usuário instala | a App Store; na União Europeia, também os marketplaces alternativos que a Apple passou a permitir em 2024 |

**As atualizações são a diferença de maior alcance.** Quando a Apple lança um iOS novo, a maioria
dos iPhones que podem recebê-lo recebe no mesmo dia. Uma versão do Android chega a um aparelho quando
o fabricante a adapta, e alguns aparelhos nunca a recebem. Por isso um app Android suporta uma faixa
de versões do sistema ao mesmo tempo, e declara a mais antiga em que roda como *minimum SDK*; um app
iOS suporta uma faixa mais curta e abandona versões antigas mais cedo. O curso `android-apps` define
esse número na aula 1, e o `ios-apps` define o do iOS na sua própria aula 1.

**As linguagens seguem os donos.** O Google recomenda **Kotlin** para Android, com Java ainda
suportado, e desenha telas com o **Jetpack Compose**. A linguagem da Apple é **Swift**, com
Objective-C por trás, e as telas são desenhadas com **SwiftUI** ou com o UIKit, mais antigo. Nenhuma
plataforma roda o código da outra. É por isso que a trilha se divide depois deste curso: você
escolhe uma linguagem e um kit, ou uma terceira rota que escreve um app para as duas, e a aula 2 põe
as três lado a lado.

**As ferramentas também seguem os donos, e esta é a diferença que custa dinheiro.** O Android Studio,
o editor do Google, roda em Windows, macOS e Linux. O Xcode, a única ferramenta que gera um app iOS,
roda só no macOS, então gerar um app para iPhone exige um Mac. Uma seção mais adiante nesta aula diz
o que isso significa para este curso, que é nada, e para os que vêm depois.
