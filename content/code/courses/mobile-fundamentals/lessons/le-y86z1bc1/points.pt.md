---
title: Os pontos do iOS, os fatores de escala e o PixelRatio do React Native
version: 1
---

**O iOS mede em pontos, e um ponto vira um, dois ou três pixels conforme o fator de escala da
tela.** As Human Interface Guidelines da Apple, na parte de imagens, o definem do mesmo jeito que o
Android define um dp: um ponto é uma unidade abstrata que mantém o conteúdo visual do mesmo tamanho
seja qual for a tela, e o *fator de escala* diz quantos pixels um ponto cobre. Um fator de escala
1, escrito @1x, é um pixel por ponto; @2x são dois por dois pixels por ponto, e @3x, três por três.

A diferença em relação ao Android é o número de degraus. **As diretrizes listam @2x e @3x para
iPhone e @2x para iPad**, porque a Apple fabrica todas as telas onde eles rodam e escolheu as
densidades de acordo. O Android tem cinco buckets em uso porque centenas de fabricantes escolheram
as suas. A ideia é a mesma; o iOS tem menos casos.

## React Native: a unidade da plataforma, e o PixelRatio

**Um tamanho no React Native é um número puro, e ele quer dizer a unidade da própria plataforma**:
um dp no Android e um ponto no iOS. `width: 48` é uma caixa de 48 dp numa plataforma e de 48 pt na
outra, e as duas têm mais ou menos o mesmo tamanho sob o dedo. A documentação do React Native para
o `PixelRatio` dá os pixels por trás do número quando um app precisa deles: `PixelRatio.get()`
devolve a densidade, e os exemplos dela põem um celular Android xhdpi e um iPhone 11 em 2, e um
celular xxhdpi em 3. `PixelRatio.getPixelSizeForLayoutSize(48)` converte um tamanho de layout nos
pixels que ele cobre, que é o que um app pergunta quando baixa uma imagem do tamanho certo.

## O mesmo quadrado em três grafias

Os trechos abaixo desenham um quadrado de 48 unidades com um ícone de 24 unidades dentro, e um
título cujo tamanho acompanha a configuração de texto do usuário. Eles foram adaptados da
documentação de cada plataforma, e **não foram compilados nem rodados para este curso**.

```kotlin
// Compose: sizes in dp, text in sp
Box(Modifier.size(48.dp)) {
    Icon(Icons.Filled.Add, contentDescription = "Add session", modifier = Modifier.size(24.dp))
}
Text("Mobile Fundamentals", fontSize = 16.sp)
```

```swift
// SwiftUI: sizes in points, text in a style that follows Dynamic Type
Image(systemName: "plus")
    .frame(width: 24, height: 24)
    .frame(width: 48, height: 48)
Text("Mobile Fundamentals")
    .font(.body)
```

```tsx
// React Native: plain numbers are dp on Android and points on iOS
<Pressable style={{ width: 48, height: 48, alignItems: "center", justifyContent: "center" }}>
  <Image source={require("./ic_session.png")} style={{ width: 24, height: 24 }} />
</Pressable>
<Text style={{ fontSize: 16 }}>Mobile Fundamentals</Text>
```

**Nenhum dos três menciona um pixel**, e esse é o sentido de todos eles. O texto é onde eles mais
diferem. O Compose escreve o tamanho do texto em `sp`. O jeito usual do SwiftUI é um estilo de
texto, `.body`, que o sistema dimensiona pela configuração de Dynamic Type do usuário em vez de um
número. O `Text` do React Native acompanha a configuração do usuário no `fontSize`, porque o
`allowFontScaling` dele é `true` por padrão, e `PixelRatio.getFontScale()` informa o fator que,
segundo a documentação, vem do tamanho de texto nos ajustes de cada plataforma. Até onde o texto
pode crescer, e o que um layout precisa fazer quando ele cresce, é a aula 19.

## Onde os pixels voltam

Duas coisas fazem quem desenvolve voltar a pensar em pixels, nas duas plataformas. A primeira é
uma **imagem raster**, um PNG ou uma foto, que é feita de pixels e fica borrada quando esticada,
então precisa ser fornecida na escala que a tela usa. A segunda é uma **linha fina**: uma borda de
um pixel, e não de um ponto, é meio ponto em @2x e um terço em @3x, e a página do `PixelRatio` do
React Native explica que ele arredonda o layout para pixels inteiros para que essa linha não suma
nem dobre. A próxima seção calcula a primeira dessas para o planner.
