---
title: Um vetor, ou a mesma imagem em todos os tamanhos
version: 1
---

**Uma imagem num app é ou um vetor, desenhado a partir de formas e nítido em qualquer tamanho, ou
um raster, feito de pixels e nítido só no tamanho em que foi salvo.** Quase toda a confusão sobre
"assets em três tamanhos" vem de tratar toda imagem como raster. Ícones, o sinal de mais do planner
e os símbolos das abas, são formas, e formas podem ser descritas uma vez. A foto da capa de um
curso é feita de pixels, e não pode.

## O vetor, em cada plataforma

| plataforma | o formato vetorial | onde ele fica |
|---|---|---|
| Android | um *vector drawable*, um arquivo XML de caminhos e cores | um arquivo em `res/drawable/`, sem pasta de densidade |
| iOS | SF Symbols, os símbolos da própria Apple, ou um PDF ou SVG seu | o asset catalog, uma entrada |
| React Native | um SVG, por meio de uma biblioteca, ou os símbolos da própria plataforma | um arquivo |

**A documentação do Android sobre densidades diz para preferir gráficos vetoriais**, e diz por quê
numa linha: um vector drawable é um arquivo que serve a todas as densidades. Ela diz também que o
Android não lê SVG diretamente, então um SVG vindo de um designer é convertido antes em vector
drawable, com o Vector Asset Studio do Android Studio. As diretrizes da Apple indicam PDF ou SVG
para ícones planos que precisam escalar, e o SF Symbols é uma biblioteca de milhares de símbolos
que as diretrizes descrevem como alinhados com a fonte do sistema em todo peso e tamanho.

Um vetor não sai de graça. Ele é desenhado a partir dos caminhos, o que custa tempo de processador
na thread principal da aula 6, e a mesma documentação diz que vetores servem melhor para ilustrações
como ícones, não para fotografias. Para um sinal de mais de 24 dp, o custo não vale a medição.

## O raster, em todos os tamanhos

**Uma foto, uma textura ou uma ilustração complicada continua raster, e aí ela é fornecida uma vez
por densidade.** Os nomes dos arquivos vêm direto do fim da saída da seção anterior:

| plataforma | onde cada tamanho fica | como o certo é escolhido |
|---|---|---|
| Android | `res/drawable-mdpi/`, `drawable-hdpi/` … `drawable-xxxhdpi/`, o mesmo nome de arquivo em cada | o sistema escolhe a pasta do bucket da tela |
| iOS | uma entrada do asset catalog com uma imagem @2x e uma @3x | o sistema escolhe pelo fator de escala da tela |
| React Native | `ic_session.png`, `ic_session@2x.png`, `ic_session@3x.png` lado a lado | o bundler entrega a da densidade da tela |

A documentação do React Native sobre imagens usa os mesmos sufixos @2x e @3x do iOS, nas duas
plataformas, e diz que, quando nenhum arquivo corresponde à densidade, o mais próximo é usado. A
documentação do Android descreve o mesmo recurso: sem arquivo para o bucket da tela, o sistema pega
o mais próximo e o redimensiona, então um arquivo de 48x48 feito para mdpi é esticado para 72x72
numa tela hdpi. **Esticado, um raster fica borrado; encolhido, ele desperdiça memória.** Nenhum dos
dois é uma falha que trava o app, e é por isso que um tamanho faltando é achado olhando o app, e
não por um erro.

## O ícone do próprio app é um caso à parte

O ícone na tela inicial não é desenhado pelo app. Um launcher o desenha, e a documentação do
Android avisa que alguns launchers o mostram até 25% maior do que o bucket da tela pede. Então o
Android guarda os ícones do app em pastas `mipmap-`, uma por bucket, que são todas mantidas no app,
e o launcher pode pegar a mais nítida no bucket de cima. O iOS guarda o ícone do app como uma
entrada própria no asset catalog. As imagens que uma loja pede são a aula 4 do `mobile-delivery`,
sobre a página da loja; aqui basta saber que ele é a única imagem que o app entrega para outro
desenhar.

## No planner

**Todo ícone do planner é um vetor**: o sinal de mais para uma sessão nova, a marca de concluída, os
símbolos das abas. Um arquivo cada, nítido em toda densidade, em toda tela. O único raster seria uma
foto que um aluno anexa a um curso, e ela vem da câmera no tamanho que a câmera escolheu, então o
app a redimensiona para o tamanho em que a mostra, em pixels que ele calcula exatamente com a conta
que o `density.ts` roda.
