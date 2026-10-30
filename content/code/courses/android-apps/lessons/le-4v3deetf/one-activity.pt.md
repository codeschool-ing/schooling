---
title: Uma activity, e todas as telas dentro dela
version: 1
---

**Um app em Compose em geral tem uma activity, e cada tela é um composable dentro dela.** Não é
assim que o Android começou. Durante a primeira década, um app era um conjunto de activities, uma
por tela. Ir da lista de cursos para as sessões de um curso significava pedir ao sistema para
iniciar outra activity com uma **intent**:

```kotlin
startActivity(Intent(this, SessionsActivity::class.java).putExtra("courseId", "kotlin"))
```

Essa linha, de uma `SessionsActivity` hipotética, não faz parte do planner e não foi executada. Ela
mostra o que o formato antigo custava. Cada tela era uma entrada no manifesto, e cada uma era
destruída e reconstruída na rotação por conta própria. Os dados viajavam entre telas como extras num
`Bundle`, então tudo o que passava precisava ser de poucos tipos de valor que o sistema sabe copiar.
E cada transição era do sistema, com a animação dele e as regras dele sobre o que o Voltar faz.

Com uma activity, uma tela é uma função. Ir da lista de cursos a um curso é chamar outro
composable, os argumentos da tela são parâmetros Kotlin comuns, e o Voltar é decidido por uma **pilha
de navegação** que o seu código controla. A aula 9 constrói isso com o Navigation Compose. A
activity única continua importando, porque é ela que o sistema conhece: ela recebe os callbacks do
ciclo de vida, é destruída na rotação e reconstruída depois da morte do processo, e é o que o ícone
do launcher abre.

## As intents continuam importando

O planner vai mandar e receber intents mesmo com uma activity, porque uma intent também é como os
apps conversam entre si:

- o launcher inicia o planner com a intent `MAIN`/`LAUNCHER` da seção 07 da aula 1;
- uma notificação, na aula 19, carrega uma `PendingIntent` que abre o planner num curso;
- um link, na aula 11 de `mobile-fundamentals`, pode abrir o planner a partir de um navegador por um
  `<intent-filter>` com uma URL;
- o planner pode entregar uma sessão ao app de agenda com uma intent sem saber quem a recebe.

**Cada uma delas é uma porta de fora para dentro do app**, e é isso que o `android:exported`
controla. Uma activity com `exported="true"` pode ser iniciada por qualquer app do celular, com os
extras que ele quiser, então o que ela lê de uma intent é entrada de um estranho e é conferido como
qualquer outra entrada. O planner exporta exatamente uma activity, a que o launcher precisa.

## O que as aulas 3 a 22 vão supor

Daqui em diante, a `MainActivity` continua tão pequena quanto agora: `setContent`, um tema e um
composable que é o app. Tudo o que não é desenhar sai dela, para um `ViewModel` (aula 10), um
repositório (aula 16) e um banco de dados (aula 15). Uma activity que faz o mínimo possível é uma
que o sistema pode destruir e reconstruir quantas vezes quiser.
