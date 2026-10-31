---
title: Tirando uma, e as três respostas
version: 1
---

**O `take` é o modelo de permissão da primeira seção, escrito por extenso.** Ele pede, e lê a resposta
antes de qualquer outra coisa:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l13-ask\" aria-label=\"Um fluxograma. A pessoa aperta Take a photo, e o app pede a câmera. Se ela é concedida, a câmera do sistema abre. Se é recusada e canAskAgain é true, o app explica o que se perde e oferece escolher uma foto; pode pedir de novo na próxima vez. Se é recusada e canAskAgain é false, o app explica e oferece um botão que abre os Ajustes.\"><defs><marker id=\"l13-ask-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"130\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"85.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Take a photo</text><rect x=\"200\" y=\"30\" width=\"230\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"315.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">requestCameraPermissionsAsync()</text><path d=\"M150 48 L200 48\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-ask-ah-paper-dim)\"></path><rect x=\"500\" y=\"30\" width=\"200\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"600.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a câmera do sistema abre</text><path d=\"M430 48 L500 48\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-ask-ah-paper-dim)\"></path><text x=\"465\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--phosphor)\">concedida</text><rect x=\"240\" y=\"120\" width=\"150\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"315.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">canAskAgain</text><path d=\"M315 66 L315 120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-ask-ah-paper-dim)\"></path><text x=\"335\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--amber)\">recusada</text><rect x=\"60\" y=\"200\" width=\"210\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"165.0\" y=\"215.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">explicar o que se perde,</text><text x=\"165.0\" y=\"228.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">oferecer a galeria</text><rect x=\"400\" y=\"200\" width=\"210\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"505.0\" y=\"215.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">explicar, e oferecer</text><text x=\"505.0\" y=\"228.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Open Settings</text><path d=\"M270 156 L165 200\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-ask-ah-paper-dim)\"></path><path d=\"M360 156 L505 200\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-ask-ah-paper-dim)\"></path><text x=\"196\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">true</text><text x=\"452\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">false</text></svg>", "caption": "Um pedido, três desfechos. Só a pessoa desfaz uma recusa definitiva, então o último passo do app é mostrar onde.", "same": ["Take a photo", "Open Settings"]}
```

- **Permitido**, a câmera do sistema abre. A pessoa tira a foto na tela de câmera do próprio sistema e
  volta com ela, e o `launchCameraAsync` responde exatamente como o seletor da galeria.
- **Recusado desta vez**, o planner diz o que falta e aponta o botão ao lado: uma foto da galeria serve
  do mesmo jeito. Ele não pede de novo na hora. O próximo toque pede, e no Android isso mostra o diálogo
  mais uma vez.
- **Recusado de vez**, pedir não adianta, então o planner diz onde fica a configuração e oferece um botão
  que a abre. O `Linking.openSettings()` abre a página do próprio app nos Ajustes, onde fica a chave da
  câmera.

**Nenhuma das frases culpa a pessoa.** Ela recusou por um motivo, talvez um bom, e o planner funciona sem
a câmera. O que a tela deve a ela é a consequência e o caminho alternativo.

## Uma câmera dentro do app

O `launchCameraAsync` usa emprestada a tela de câmera do próprio sistema, o que é certo para a foto de uma
página: é a câmera que a pessoa já conhece, com foco, flash e zoom. Um app que precisa da câmera dentro da
própria tela, para ler um código ou desenhar sobre a imagem, usa o `expo-camera`. O `CameraView` dele é um
componente que mostra a imagem ao vivo, e pede a mesma permissão, com as mesmas três respostas. *O planner
não precisa dele, e este curso não o instalou.*
