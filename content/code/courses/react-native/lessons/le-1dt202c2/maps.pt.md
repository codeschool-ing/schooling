---
title: Mapas
version: 1
---

**Um mapa é uma view nativa**, desenhada pelo Google Maps no Android e pelo Apple Maps no iOS, e no React
Native ela vem do `react-native-maps`. O `MapView` é o mapa; `Marker`, `Polyline`, `Polygon` e `Circle`
vão dentro dele. Um mapa dos lugares do diário ficaria assim:

```tsx
// src/PlacesMap.tsx: the journal's places as pins on a map, beside the text that says the same thing.
import MapView, { Marker } from "react-native-maps";

type Place = { lat: number; lng: number; sessions: number };

export function PlacesMap({ places }: { places: Place[] }) {
  if (places.length === 0) return null;
  const [first] = places;
  return (
    <MapView
      style={{ height: 240 }}
      initialRegion={{ latitude: first.lat, longitude: first.lng, latitudeDelta: 0.1, longitudeDelta: 0.1 }}
      accessibilityElementsHidden // the list above says it in words; a map read aloud says nothing useful
      importantForAccessibility="no-hide-descendants"
    >
      {places.map((p) => (
        <Marker key={`${p.lat},${p.lng}`} coordinate={{ latitude: p.lat, longitude: p.lng }} title={`${p.sessions} sessions`} />
      ))}
    </MapView>
  );
}
```

O `initialRegion` é onde o mapa abre: um centro e quantos graus de latitude e longitude cabem na tela.
Cada `Marker` é um alfinete, e o `title` é o que um toque nele mostra.

**Três coisas que um mapa custa, antes de desenhar qualquer coisa:**

- **No Android ele precisa de uma chave de API do Google Maps**, de um projeto do Google Cloud com o Maps
  SDK for Android ligado, escrita no `app.json` em `android.config.googleMaps.apiKey`. A chave vai dentro
  do app, onde qualquer um consegue lê-la, então ela é restrita no console do Google ao nome do pacote e ao
  certificado de assinatura do app. No iOS, o Apple Maps não precisa de chave.
- **Ele não roda na web.** O `react-native-maps` não tem versão web, então um build web precisa de outro
  componente ou de um arquivo por plataforma, como na aula 13.
- **Um leitor de tela não consegue ler um mapa.** O componente acima se esconde da acessibilidade, porque a
  linha acima dele, *Studied at …*, já diz o mesmo em palavras. Um mapa é a imagem de uma informação, e a
  informação precisa estar em outro lugar também.

*Este arquivo foi conferido pelo compilador de TypeScript contra o `react-native-maps` 1.29.11, a versão
que o SDK 58 espera, e não foi executado: o planner não o instala, porque um mapa com chave precisa de um
projeto do Google Cloud que este curso não tem, e os dois ou três lugares do planner se leem bem como uma
linha de texto.*
