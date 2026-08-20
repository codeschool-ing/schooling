---
title: Layout, pintura e composição
---

Com estilo resolvido, faltam três passos: **layout** calcula a posição e o tamanho de cada caixa, **pintura** desenha os pixels, e **composição** junta as camadas na tela.

O custo de cada um é bem diferente, e é isso que separa animação suave de animação travada. Mudar `width` ou `top` refaz o layout de tudo o que estiver em volta. Mudar `background-color` só repinta. Mudar `transform` ou `opacity` mexe só na composição, que a placa de vídeo faz sozinha.

Daí a regra prática mais rentável do front-end: **anime `transform` e `opacity`**, não `left`, `top` ou `width`.
