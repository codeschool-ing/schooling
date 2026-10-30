---
title: O que estica, o que fica, e o que vira
version: 1
---

**Dentro de uma classe de tamanho, um layout se dobra em vez de trocar: algumas coisas ocupam o
espaço que houver, e outras mantêm o tamanho aconteça o que acontecer.** O erro comum vai numa de
duas direções. Ou tudo recebe um tamanho fixo, projetado num celular, e o layout deixa uma faixa
vazia na lateral de uma janela mais larga ou corta a última coluna numa mais estreita. Ou tudo
estica, e uma linha de texto atravessa a largura inteira de um tablet em paisagem, o que ninguém
consegue ler.

## Três tipos de tamanho

| tipo | o que faz | no planner |
|---|---|---|
| preencher | ocupa o espaço que o pai dá | a lista de sessões, a largura do título do curso |
| fixo, em dp ou pontos | mantém o tamanho em toda janela | os alvos de toque de 48 dp, os ícones de 24 dp, o espaço entre linhas |
| preencher, até um limite | estica até um máximo, depois para e centraliza | o formulário de nova sessão, os parágrafos da descrição de um curso |

**O terceiro tipo é o que o iniciante esquece.** Um campo de texto com 300 dp de largura num celular
vai bem; o mesmo campo com 1200 dp, num tablet em paisagem, pede ao olho para atravessar a tela
inteira para ler uma linha. Limitar a largura o mantém legível e deixa o resto da janela para outra
coisa, que na próxima seção é um segundo painel.

Os trechos abaixo dão ao formulário de nova sessão os três tipos: o formulário ocupa a janela até
600 unidades e fica centralizado a partir daí, e o botão dentro dele mantém os seus 48. Eles foram
adaptados da documentação de cada plataforma, e **não foram compilados nem rodados para este
curso**.

```kotlin
// Compose: fill the width, but never more than 600 dp; the button keeps its size
Column(Modifier.fillMaxWidth().widthIn(max = 600.dp).padding(16.dp)) {
    OutlinedTextField(value = title, onValueChange = { title = it }, modifier = Modifier.fillMaxWidth())
    Button(onClick = save, modifier = Modifier.heightIn(min = 48.dp)) { Text("Add session") }
}
```

```swift
// SwiftUI: as wide as the window allows, up to 600 points, centred
VStack(alignment: .leading) {
    TextField("Title", text: $title)
    Button("Add session", action: save).frame(minHeight: 48)
}
.padding(16)
.frame(maxWidth: 600)
.frame(maxWidth: .infinity)
```

```tsx
// React Native: flexbox, with a maximum width and the content centred
<View style={{ width: "100%", maxWidth: 600, alignSelf: "center", padding: 16 }}>
  <TextInput value={title} onChangeText={setTitle} />
  <Pressable onPress={save} style={{ minHeight: 48 }}>
    <Text>Add session</Text>
  </Pressable>
</View>
```

**Nenhum dos três cita um aparelho ou uma orientação.** Eles descrevem como o formulário se comporta
em qualquer largura, e é por isso que o mesmo código está certo em retrato, em paisagem e em metade
de uma tela dividida.

## Virando o celular

A orientação é a mudança que todo usuário faz, e ela é só uma mudança de janela: largura e altura
trocam. Vale conferir três coisas quando ela acontece, e nenhuma delas pede um layout separado para
paisagem:

- o conteúdo continua cabendo no lado curto. Um celular em paisagem é compact de altura, pela
  tabela do Android, então uma tela que empilha um cabeçalho, um formulário e um botão pode ficar
  sem espaço, e precisa rolar;
- nada importante fica onde a mão segura o celular, ou embaixo do entalhe, que em paisagem fica na
  lateral. A aula 9 trata dessas regiões;
- o estado sobrevive. Digitar metade do título de uma sessão e virar o celular não pode perder a
  metade, e no Android a tela é reconstruída para a rotação, como a aula 4 descreveu.

**Um app pode se recusar a virar**, e alguns devem: um visor de câmera, um jogo projetado para um
formato. Para uma lista de sessões de estudo, é um jeito de evitar três conferências ao custo de
todo usuário que lê em paisagem, e, como as seções anteriores mostraram, uma orientação travada
ainda encontra telas divididas e janelas redimensionáveis.
