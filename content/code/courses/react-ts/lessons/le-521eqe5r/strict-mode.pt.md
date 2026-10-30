---
title: O strict mode renderiza duas vezes de propósito
version: 1
---

**Cada linha saiu duas vezes porque o `<StrictMode>` chama cada componente duas vezes em
desenvolvimento.** É escolha do modelo, e uma boa escolha, e esta seção o tira por um momento para
mostrar o que ele faz. O `sed` troca o `<StrictMode>` por um fragmento e remove o import dele:

```
ana@dev:~/planner$ sed -i 's/<StrictMode>/<>/; s/<\/StrictMode>/<\/>/; /^import { StrictMode }/d' src/main.tsx
ana@dev:~/planner$ cat src/main.tsx
import { createRoot } from 'react-dom/client'
import './index.css'
import App from './App.tsx'

createRoot(document.getElementById('root')!).render(
  <>
    <App />
  </>,
)
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --quiet
render App
render WeekNav
render WeekSummary
render CourseList
render CourseCard
render Card
render CourseCard
render Card
render CourseCard
render Card
```

Uma chamada por componente. Nada na página mudou: a tela é a mesma com strict mode e sem, e é esse o
ponto. **O strict mode chama o seu componente uma segunda vez e joga o resultado fora, para achar
componentes que não são puros.** Um componente puro, chamado duas vezes com as mesmas props, devolve
a mesma árvore duas vezes e ninguém percebe. O componente da aula 2 que punha o nome do curso em
maiúsculas o faria duas vezes: inofensivo ali, e nada inofensivo num componente que acrescenta uma
linha a uma lista ou incrementa um contador a cada vez que roda.

Ele faz mais duas coisas de que a aula 5 depende. Roda cada efeito, depois o limpa, depois o roda de
novo, para achar efeitos que não limpam o que fizeram. E avisa sobre um punhado de interfaces que o
React descontinuou.

Três fatos impedem que isso seja alarmante:

- **Só em desenvolvimento.** O `npm run build` produz uma versão em que o strict mode não faz nada, e
  o navegador de um visitante renderiza cada componente uma vez.
- **Só dentro da tag.** Ele vale para os componentes sob o `<StrictMode>`, que neste app são todos, e
  você poderia envolver só uma parte de um app.
- **Os registros são chamadas reais.** O React 19 imprime o `console.log` da segunda chamada também,
  como você viu; as ferramentas de desenvolvedor de alguns navegadores o deixam acinzentado. O React
  17 o escondia, o que deixava a segunda chamada invisível e a contagem dobrada que ela pega mais
  difícil de entender.

Deixe ligado. O resto desta aula o mantém desligado por um motivo só: uma transcrição com cada linha
uma vez é metade do tamanho para ler. A última seção o põe de volta.
