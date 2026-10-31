---
title: Contexto, para toda tela ler o mesmo plano
version: 1
---

**Um contexto entrega um valor a todo componente abaixo do provider dele, sem passá-lo pelas props de cada
nível.** A segunda metade do `src/planState.tsx` é um: o `PlanProvider` guarda o plano com `useReducer` e põe
`{ plan, dispatch }` no `PlanContext`, e o `usePlan()` o lê de qualquer lugar abaixo.

Três detalhes dessa metade são de propósito:

- **O contexto começa como `null`**, e o `usePlan` lança uma frase quando encontra `null`. Um componente usado
  fora do provider, num teste que o esqueceu por exemplo, falha com *usePlan must be used inside a
  PlanProvider* em vez de ler um plano que não está ali.
- **O `dispatch` viaja com o plano.** Uma tela que marca uma sessão como feita chama
  `dispatch({ type: "done", id })`; ela nunca vê o `markDone`, e não consegue mudar o plano de nenhum outro
  jeito.
- **O provider recebe o plano inicial como prop**, `initial`, em vez de importar o arquivo de dados. O app passa
  os dados; um teste passa o plano de que precisar; a aula 14 passa o plano que carregou do armazenamento.

## Onde o provider vai

Alto o bastante para toda tela ficar dentro dele, o que aqui quer dizer em volta dos navegadores. Troque o
`App.tsx`:

```tsx
// App.tsx: the planner's root: safe areas, the shared plan, then navigation.
import { NavigationContainer } from "@react-navigation/native";
import { StatusBar } from "expo-status-bar";
import { initialWindowMetrics, SafeAreaProvider } from "react-native-safe-area-context";
import data from "./src/courses.json";
import { linking, RootNavigator } from "./src/navigation";
import { PlanProvider } from "./src/planState";
import type { Plan } from "./src/planner";

const initial: Plan = data;

export default function App() {
  return (
    <SafeAreaProvider initialMetrics={initialWindowMetrics}>
      <PlanProvider initial={initial}>
        <NavigationContainer linking={linking}>
          <RootNavigator />
        </NavigationContainer>
      </PlanProvider>
      <StatusBar style="auto" />
    </SafeAreaProvider>
  );
}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" data-fig=\"l09-context\" aria-label=\"O provider do plano na raiz do app, em volta dos navegadores. Ele guarda o plano e o dispatch. As telas Courses, This week e Course o leem com usePlan. As telas This week e Course enviam uma ação done pelo dispatch; o reducer devolve um plano novo; todo leitor renderiza de novo.\"><defs><marker id=\"l09-context-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l09-context-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"200\" y=\"20\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"330.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">PlanProvider: plan + dispatch</text><rect x=\"520\" y=\"20\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"600.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">planReducer</text><path d=\"M460 40 L520 40\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l09-context-ah-amber)\" marker-start=\"url(#l09-context-ah-amber)\"></path><rect x=\"60\" y=\"160\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"140.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Courses</text><path d=\"M330 60 L140 160\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l09-context-ah-paper-dim)\"></path><rect x=\"280\" y=\"160\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">This week</text><path d=\"M330 60 L360 160\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l09-context-ah-paper-dim)\"></path><rect x=\"500\" y=\"160\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"580.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Course</text><path d=\"M330 60 L580 160\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l09-context-ah-paper-dim)\"></path><text x=\"170\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">usePlan()</text><text x=\"560\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">{ type: \"done\", id }</text><path d=\"M580 160 L600 64\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l09-context-ah-amber)\"></path></svg>", "caption": "Um plano na raiz: as telas o leem, e só o mudam enviando uma ação.", "same": ["Courses", "This week", "Course"]}
```

## O que o contexto custa

**Quando o valor num provider muda, todo componente que o lê renderiza de novo**, qualquer que seja a parte do
valor que ele usa. Para o planner, isso são três telas, e redesenhá-las num toque não custa nada que alguém
consiga medir. A seção sobre stores conta isso, e mostra o tipo de app em que começa a importar.
