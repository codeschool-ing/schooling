---
title: Geolocalização e câmera
version: 1
---

## Onde estou?

O `whereAmI()` faz uma chamada, e **a pergunta de permissão acontece dentro dela** na primeira vez. Aqui
ela aparece duas vezes: uma sem ninguém para responder, e uma com a permissão concedida e uma posição
dada ao navegador, um ponto da Avenida Paulista, em São Paulo:

```
ana@dev:~/planner$ node look.mjs 'http://localhost:5173/?today=2026-10-21' --click 'Where am I?' --wait 300 | tail -n 1
  - status: "where failed: User denied Geolocation"
ana@dev:~/planner$ node look.mjs 'http://localhost:5173/?today=2026-10-21' --grant geolocation --geo -23.561,-46.656 --click 'Where am I?' --wait 300 | tail -n 1
  - status: studying at -23.561, -46.656
```

**Uma recusa chega ao seu código como um erro**, e a linha de status a transformou numa frase. É o caso
para o qual projetar: o planner funciona sem localização, então um não custa um botão e mais nada. Um
app que não funciona de jeito nenhum sem ela tem que dizer isso antes de perguntar.

Dois detalhes da documentação do plugin importam num celular. O Android 12 e os seguintes deixam a
pessoa conceder só uma localização **aproximada**, que chega como `coarseLocation` concedida e
`location` negada; um app que só precisa da cidade deve pedir só isso. E uma posição **com o app em
segundo plano** é uma permissão à parte nos dois sistemas, concedida com muito mais relutância e
examinada de perto pelos revisores das duas lojas.

## Uma foto das minhas anotações

Num celular, o `Camera.takePhoto` abre a câmera do sistema, e a foto volta para o app. Na web ele abre
um seletor de arquivo, porque `webUseInput: true` pede isso; sem essa opção, o plugin procuraria um
componente de câmera do pacote separado `@ionic/pwa-elements`. O `--upload` responde ao seletor com um
PNG branco pequeno que esta execução tinha pronto:

```
ana@dev:~/planner$ node look.mjs 'http://localhost:5173/?today=2026-10-21' --click Guitar --upload ~/notes.png --click 'Photo of my notes' --wait 500 | tail -n 2
  - button "Photo of my notes"
  - status: a photo, image/png, 151 bytes
```

**O `webPath` é um endereço que a página consegue carregar**, então o planner o buscou e informou o que
recebeu: um PNG, com o tamanho em bytes. Num celular, o `webPath` aponta para um arquivo que o app pode
ler, e o `uri` para o mesmo arquivo do lado nativo; a documentação do plugin explica quando passar um
ou outro ao Filesystem.

A câmera também é onde as duas plataformas mais discordam sobre permissão. No iOS, usar a câmera e ler a
fototeca são perguntas separadas, com frases separadas no `Info.plist`, que a próxima seção acrescenta.
No Android, tirar uma foto entrega o trabalho ao app de câmera por uma intent, o que não exige permissão
de câmera nenhuma do planner; as entradas de manifesto que a documentação do plugin lista são para
salvar na galeria em versões antigas do Android.
