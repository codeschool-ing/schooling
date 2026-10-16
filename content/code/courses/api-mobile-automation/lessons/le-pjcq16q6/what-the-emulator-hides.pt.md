---
title: O que o emulador esconde
version: 1
---

**O emulador roda o Android com fidelidade e o celular sem ela.** Um defeito na lógica do app, nas
telas, nos layouts em outro idioma ou tamanho, nas permissões ou no tratamento de uma requisição que
falhou aparece no emulador exatamente como num celular. Um defeito que mora no hardware, nas mudanças
de um fabricante ou no mundo em volta do celular não aparece. São esses que os usuários relatam
com as palavras *só acontece no meu celular*.

A crença comum é que um teste no emulador com a versão do Android e o tamanho de tela certos é um
teste "daquele celular". É um teste do Android do Google naquela versão, numa máquina muito rápida e
muito regular. Estes são os lugares em que ele se separa de um celular no bolso de alguém.

## Velocidade e memória

O emulador empresta o processador do seu computador, e o processador de um notebook costuma ser mais
rápido que o de um celular barato, com mais memória atrás. **Uma lista que rola macia no emulador
pode engasgar num celular de três anos que custa um décimo do notebook.** Num celular com pouca
memória, o Android fecharia um app que usa memória demais. Num aparelho virtual com sobra, o mesmo
app continua rodando. O emulador deixa você dar menos memória e menos núcleos a um aparelho quando o
cria, o que traz parte disso de volta. Nada disso deixa o processador mais lento.

## O desenho da tela

Um celular desenha com o próprio chip gráfico e o driver do fabricante. O emulador desenha com o seu,
ou em software quando não consegue:

```
ana@laptop:~$ emulator -help-gpu | head -16

  Use -gpu <mode> to override the mode of hardware OpenGL ES emulation
  indicated by the AVD. The following <mode> values should cover most
  use cases:

     auto (default)       -> Auto-select the renderer.
     auto-no-window       -> Auto-select the renderer when
                             running headless. This will use the same
                             gpu selection mechanism as running without
                             the "-no-window" flag and the "-gpu auto"
                             option. See auto for details on the behavior.
     host                 -> Use the host system's OpenGL driver.
     swiftshader_indirect -> Use SwiftShader software renderer on the
                             host, which can be beneficial if you are
                             experiencing issues with your GPU drivers
                             or need to run on systems without GPUs.
```

`host` é o driver gráfico do seu próprio computador, e `swiftshader_indirect` é o SwiftShader, um
renderizador que roda no processador. Nenhum dos dois é o chip do celular. Uma falha que vem
de uma família de GPUs de celular, uma tela preta ou uma animação piscando, não vai aparecer aqui.

## O Android do fabricante

O emulador roda o Android do Google. A maioria dos celulares no Brasil roda uma versão do fabricante,
com launcher próprio, ajustes próprios e, acima de tudo, **regras próprias sobre o que um app pode
fazer em segundo plano**. Vários fabricantes param o trabalho em segundo plano com muito mais
agressividade que o Android do Google, para poupar bateria. Pense numa tarefa agendada de um app, como
um lembrete no dia de um espetáculo, do tipo que a chave do Tickets oferece. Ela pode disparar sempre
no emulador e nunca numa marca específica de celular. Quem desenvolve documenta essas diferenças marca
por marca, e só o celular daquela marca as mostra.

## Sensores, localização e a câmera

Todo sensor é uma propriedade que você liga e alimenta. O GPS informa exatamente a posição digitada
em *Extended controls*, sem nada da deriva de um celular dentro de casa. O acelerômetro gira quando
você gira o celular virtual, nunca porque alguém está andando. A câmera é o caso mais claro:

```
ana@laptop:~$ emulator -help-camera-back

  Use -camera-back <mode> to control emulation of a camera facing back.
  Valid values for <mode> are:

     emulated     -> camera will be emulated using software ('fake') camera emulation
     webcam<N>    -> camera will be emulated using a webcamera connected to the host
     virtualscene -> If the feature is enabled, camera will render a virtual scene
     videoplayback -> If the feature is enabled, camera will support playing back a video
     none         -> camera emulation will be disabled
```

`emulated` é uma imagem desenhada em software, `webcam0` é a câmera do seu próprio computador, e
`virtualscene` é uma sala desenhada pela qual você pode andar. **Nenhuma delas é a lente do
celular.** Um app que lê o QR code de um ingresso pode ser testado no fluxo aqui, e na leitura só
num celular.

## Os serviços do Google

Um app que usa o Google Play services, para mapas, login com Google ou mensagens push pelo Firebase,
precisa deles no aparelho. Todo celular certificado vendido com a loja do Google os tem. Um emulador
só os tem se a imagem de sistema disser *Google APIs* ou *Google Play*, e é por isso que a lição 14
escolheu uma imagem *Google APIs*. Numa imagem simples esses recursos falham, e a falha é da imagem.

## A rede e os dedos

A rede do emulador é a do seu computador: um cabo ou um bom Wi-Fi, estável. Ela não tem
elevador, túnel nem passagem do Wi-Fi para a rede móvel no meio de uma requisição. Ela pode ser deixada lenta de
propósito, e a lição 22 faz isso. E um clique de mouse cai no pixel exato que você mirou, o que um
polegar num ônibus nunca faz. Um botão pequeno demais para acertar com segurança passa em todo teste
no emulador.
