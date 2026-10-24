---
title: Quando o servidor e o navegador discordam
version: 1
---

**A hidratação parte do princípio de que o navegador, rodando os mesmos componentes com os mesmos
dados, desenha exatamente o que o servidor desenhou.** O Vue percorre lado a lado os elementos do
servidor e os que ele teria feito, e se liga a eles; ele não desenha a página de novo. Quando os dois
diferem, isso é uma *divergência de hidratação* (hydration mismatch), e o planner tem uma esperando
na página da semana:

```typescript
const today = isoDate(new Date())
```

Essa linha roda duas vezes, uma no servidor e uma no navegador, e cada um lê o próprio relógio no
próprio fuso. A maioria dos hosts roda seus servidores em UTC, e o leitor do planner está em São
Paulo, três horas atrás. Em 21 horas do dia as duas datas concordam. **Às onze e meia da noite em São
Paulo, já são duas e meia da manhã seguinte em UTC.** As transcrições abaixo foram gravadas nesse
momento, com o servidor no fuso UTC, como um host o deixaria; no seu computador o servidor e o
navegador dividem o mesmo fuso, e você precisaria de um servidor em outro lugar para ver isso.
Primeiro o servidor de desenvolvimento:

```
ana@dev:~/vue/planner-nuxt$ look http://localhost:3000/ --text 'main section:nth-child(3) ul'
[vite] connecting...
[vite] connected.
<Suspense> is an experimental feature and its API will likely change.
[warn] [Vue warn]: Hydration node mismatch:
- rendered on server: JSHandle@node  
- expected on client: strong 
  at <SessionRow key="s4" session= {id: s4, course: statistics, date: 2026-10-21, minutes: 60, done: false} title="Statistics"  ... > 
  at <PlannerPanel title="Week of 19 October 2026" > 
  at <Index onVnodeUnmounted=fn<onVnodeUnmounted> onVnodeMounted=fn<onVnodeSettled> onVnodeUpdated=fn<onVnodeSettled>  ... > 
  at <RouteProvider key="/" vnode= {__v_isVNode: true, __v_skip: true, type: Object, props: Object, key: null} route= {fullPath: /, hash: , query: Object, name: index, path: /}  ... > 
  at <RouterView name=undefined route=undefined > 
  at <NuxtPage> 
  at <Default ref=Ref< undefined > > 
  at <AsyncComponentWrapper ref=Ref< undefined > > 
  at <LayoutLoader key="default" layoutProps= {ref: RefImpl} name="default" > 
  at <NuxtLayoutProvider layoutProps= {ref: RefImpl} key="default" name="default"  ... > 
  at <NuxtLayout> 
  at <App key=4 > 
  at <NuxtRoot>
[error] Hydration completed but contains mismatches.
[warn] [Vue warn]: Hydration class mismatch on JSHandle@node 
  - rendered on server: class=""
  - expected on client: class="today"
  Note: this mismatch is check-only. The DOM will not be rectified in production due to performance overhead.
  You should fix the source of the mismatch. 
  at <SessionRow key="s4" session= {id: s4, course: statistics, date: 2026-10-21, minutes: 60, done: false} title="Statistics"  ... > 
  at <PlannerPanel title="Week of 19 October 2026" > 
  at <Index onVnodeUnmounted=fn<onVnodeUnmounted> onVnodeMounted=fn<onVnodeSettled> onVnodeUpdated=fn<onVnodeSettled>  ... > 
  at <RouteProvider key="/" vnode= {__v_isVNode: true, __v_skip: true, type: Object, props: Object, key: null} route= {fullPath: /, hash: , query: Object, name: index, path: /}  ... > 
  at <RouterView name=undefined route=undefined > 
  at <NuxtPage> 
  at <Default ref=Ref< undefined > > 
  at <AsyncComponentWrapper ref=Ref< undefined > > 
  at <LayoutLoader key="default" layoutProps= {ref: RefImpl} name="default" > 
  at <NuxtLayoutProvider layoutProps= {ref: RefImpl} key="default" name="default"  ... > 
  at <NuxtLayout> 
  at <App key=4 > 
  at <NuxtRoot>
[warn] [Vue warn]: Hydration node mismatch:
- rendered on server: JSHandle@node  
- expected on client: Symbol(v-cmt) 
  at <SessionRow key="s5" session= {id: s5, course: guitar, date: 2026-10-22, minutes: 20, done: false} title="Guitar"  ... > 
  at <PlannerPanel title="Week of 19 October 2026" > 
  at <Index onVnodeUnmounted=fn<onVnodeUnmounted> onVnodeMounted=fn<onVnodeSettled> onVnodeUpdated=fn<onVnodeSettled>  ... > 
  at <RouteProvider key="/" vnode= {__v_isVNode: true, __v_skip: true, type: Object, props: Object, key: null} route= {fullPath: /, hash: , query: Object, name: index, path: /}  ... > 
  at <RouterView name=undefined route=undefined > 
  at <NuxtPage> 
  at <Default ref=Ref< undefined > > 
  at <AsyncComponentWrapper ref=Ref< undefined > > 
  at <LayoutLoader key="default" layoutProps= {ref: RefImpl} name="default" > 
  at <NuxtLayoutProvider layoutProps= {ref: RefImpl} key="default" name="default"  ... > 
  at <NuxtLayout> 
  at <App key=4 > 
  at <NuxtRoot>
[warn] [Vue warn]: Hydration class mismatch on JSHandle@node 
  - rendered on server: class="today"
  - expected on client: class=""
  Note: this mismatch is check-only. The DOM will not be rectified in production due to performance overhead.
  You should fix the source of the mismatch. 
  at <SessionRow key="s5" session= {id: s5, course: guitar, date: 2026-10-22, minutes: 20, done: false} title="Guitar"  ... > 
  at <PlannerPanel title="Week of 19 October 2026" > 
  at <Index onVnodeUnmounted=fn<onVnodeUnmounted> onVnodeMounted=fn<onVnodeSettled> onVnodeUpdated=fn<onVnodeSettled>  ... > 
  at <RouteProvider key="/" vnode= {__v_isVNode: true, __v_skip: true, type: Object, props: Object, key: null} route= {fullPath: /, hash: , query: Object, name: index, path: /}  ... > 
  at <RouterView name=undefined route=undefined > 
  at <NuxtPage> 
  at <Default ref=Ref< undefined > > 
  at <AsyncComponentWrapper ref=Ref< undefined > > 
  at <LayoutLoader key="default" layoutProps= {ref: RefImpl} name="default" > 
  at <NuxtLayoutProvider layoutProps= {ref: RefImpl} key="default" name="default"  ... > 
  at <NuxtLayout> 
  at <App key=4 > 
  at <NuxtRoot>
== the text of main section:nth-child(3) ul
 19 October 2026, Statistics, 45 minutes
 19 October 2026, Spanish, 30 minutes
 21 October 2026, Statistics, 60 minutes (today)
 22 October 2026, Guitar, 20 minutes
 23 October 2026, Spanish, 40 minutes
```

**Quatro avisos e um erro, e os avisos dizem tudo.** O servidor desenhou o dia 22 como hoje, com um
`class="today"` na linha de violão e nenhum `(today)` no dia 21; o navegador, em São Paulo, esperava o
contrário. Em desenvolvimento o Vue conserta o que consegue, então a lista no fim parece certa. A nota
no meio é a parte em que acreditar: *the DOM will not be rectified in production*, o DOM não será
corrigido em produção. O servidor do build, em UTC, no mesmo momento:

```
ana@dev:~/vue/planner-nuxt$ look http://localhost:3000/ --text 'li.today'
[error] Hydration completed but contains mismatches.
== the text of li.today
 22 October 2026, Guitar, 20 minutes
ana@dev:~/vue/planner-nuxt$ look http://localhost:3000/ --text 'li:has(strong)'
[error] Hydration completed but contains mismatches.
== the text of li:has(strong)
 21 October 2026, Statistics, 60 minutes (today)
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 255\" role=\"img\" aria-label=\"A mesma linha, today igual a isoDate de new Date, lida em dois relógios no mesmo instante. O servidor, em UTC, lê 02:30 de 22 de outubro, então today é 2026-10-22 e ele desenha o destaque no dia 22. O navegador, em São Paulo, três horas atrás, lê 23:30 de 21 de outubro, então today é 2026-10-21 e ele espera (today) no dia 21. Embaixo, a página em produção: o Vue cria o elemento que falta, então o dia 21, Statistics, 60 minutes, diz (today); e deixa o atributo como está, então o dia 22, Guitar, 20 minutes, fica com o destaque do servidor. Dois hojes.\"><rect x=\"20\" y=\"20\" width=\"320\" height=\"100\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">o servidor, em UTC</text><text x=\"180\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">02:30 de 22 de outubro</text><text x=\"180\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">today = '2026-10-22'</text><text x=\"180\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">destaca o dia 22</text><rect x=\"380\" y=\"20\" width=\"320\" height=\"100\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">o navegador, em São Paulo</text><text x=\"540\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">23:30 de 21 de outubro</text><text x=\"540\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">today = '2026-10-21'</text><text x=\"540\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">espera (today) no dia 21</text><text x=\"360\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a página em produção, no mesmo instante</text><rect x=\"20\" y=\"162\" width=\"370\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"205\" y=\"177\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">21 October 2026, Statistics, 60 minutes (today)</text><text x=\"402\" y=\"177\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">(today) criado pelo navegador</text><rect x=\"20\" y=\"204\" width=\"370\" height=\"30\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"205\" y=\"219\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">22 October 2026, Guitar, 20 minutes</text><text x=\"402\" y=\"219\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">destaque deixado pelo servidor</text></svg>", "caption": "Cada lado lê o próprio relógio; em produção a página fica com um pedaço de cada resposta."}
```

**Uma linha aparece destacada como hoje, e outra diz `(today)`.** Em produção o Vue só informa que uma
divergência aconteceu, com uma linha e nenhum detalhe, e conserta só o que precisa: um elemento que
falta é criado, então o `(today)` do navegador apareceu no dia 21, e um atributo fica como está, então
o destaque do servidor ficou no dia 22. Nada mais está errado na página, e ninguém relataria isso como
um erro; um estudante só veria dois hojes, três horas toda noite, e deixaria de confiar no planner.

## De onde vêm as divergências

A regra é simples de dizer: **qualquer coisa que um componente lê e que não é igual no servidor e no
navegador** é uma divergência esperando o dia em que ela difere. As de sempre:

- o relógio e o fuso horário, como aqui, e tudo o que se formata a partir deles;
- `Math.random()` e ids feitos por um contador, em que o `useId()`, o da aula 14, dá o mesmo id nos
  dois lados;
- `window`, `localStorage`, a largura da janela, que nem existem no servidor;
- o idioma do leitor e as configurações dele, a não ser que o servidor as receba na requisição.

A correção é sempre do mesmo tipo: decidir esse valor num lugar só. Ou o servidor decide e o navegador
recebe, que é o que o `useFetch` faz com os dados, ou o navegador decide depois da hidratação, e o
servidor desenha a página sem ele. Para o dia do leitor só a segunda serve, porque só o navegador sabe
onde o leitor está. A seção sobre renderização só no cliente faz isso, depois de mais duas formas de
fazer páginas, e cada uma delas acaba tendo a mesma linha no caminho.
