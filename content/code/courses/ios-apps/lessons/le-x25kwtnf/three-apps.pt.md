---
title: O mesmo planner, de três jeitos
version: 1
---

**Este é um de três cursos na mesma bifurcação da trilha `mobile`, e os três constroem o mesmo
planner de estudos**: as mesmas quatro telas, os mesmos cursos e sessões, o mesmo total da semana,
offline primeiro e sincronizado com um servidor. O `android-apps` o constrói com Kotlin e Jetpack
Compose e o `react-native` com JavaScript e React Native. Cada um é declarado com 90 horas em 22
aulas, como este. Esta seção os compara a partir das fichas de desenho e das listas de tópicos, como
estavam em 30 de outubro de 2026. Nenhum dos outros dois foi executado para este curso.

## Peça por peça

| a peça do planner | `ios-apps` | `android-apps` | `react-native` |
|---|---|---|---|
| desenhar uma tela | views SwiftUI, aulas 2 a 5 | composables e layout, aulas 3 e 6 | componentes básicos e Flexbox, aulas 4 e 5 |
| estado que redesenha | `@State`, `@Observable`, aulas 6 e 7 | `remember`, um ViewModel, aulas 4 e 10 | hooks e um store, aula 9 |
| a lista de sessões | `List` e identidade, aula 8 | `LazyColumn` e chaves, aula 8 | `FlatList` e chaves, aula 7 |
| ir de tela em tela | `NavigationStack`, aula 9 | Navigation Compose, aula 9 | React Navigation, aula 8 |
| o servidor | `URLSession`, aula 12 | Retrofit e OkHttp, aulas 13 e 14 | busca com TanStack Query, aula 10 |
| o armazenamento no telefone | SwiftData, aula 13 | Room, aula 15 | SQLite e outros, aula 14 |
| trabalho depois que o app fecha | tarefas em segundo plano, aula 16 | WorkManager, aula 18 | localização em segundo plano, aula 15 |
| lembretes | notificações, aula 17 | notificações, aula 19 | notificações push, aula 16 |
| pedir acesso | textos de privacidade, aula 18 | permissões em tempo de execução, aula 20 | permissões, aula 13 |
| testes | Swift Testing e testes de interface, aula 20 | testes unitários, de interface Compose e de captura, aula 21 | depuração e desempenho, aulas 18 e 19 |
| assinatura e a loja | aulas 21 e 22 | aula 22 | EAS Build e atualizações, aulas 20 e 21 |

**Os conceitos se alinham; o vocabulário não.** Uma chave num `LazyColumn` e um `id` numa `List` do
SwiftUI respondem a mesma pergunta, qual linha é qual, e o estado de um ViewModel e um modelo
`@Observable` respondem a mesma também. Quem construiu um dos três consegue ler o código dos outros
dois perguntando em que linha desta tabela está olhando.

## Onde os três diferem

- **O que dá para praticar sem hardware especial.** A ficha do `android-apps` chama o runtime de
  "heavy, and buildable", já que o emulador roda no Linux. A ficha do `react-native` cita "Node, Metro
  and a simulator or device", e a aula 20 dele compila um app iOS sem um Mac na sala. A ficha deste
  curso diz "no path from a browser at any price", e a aula 1 disse qual metade você conseguia
  praticar. Essa diferença é real e não está nas horas.
- **Uma plataforma ou duas.** O `android-apps` e o `ios-apps` chegam cada um a uma plataforma com as
  suas ferramentas; o `react-native` chega às duas a partir de um código só, e a última aula dele pesa
  as outras rotas multiplataforma.
- **A loja no fim.** As duas lojas revisam o que é publicado, e a aula 22 de `android-apps` e a aula 6
  de `mobile-delivery` cobrem o lado do Google Play. O da Apple é o que esta aula leu: pessoas na
  Apple, contra um documento público, antes de toda versão, seção 06.

**O que vem junto qualquer que tenha sido a escolha** é a forma do planner: as regras em código que não
sabe de telas, o repositório entre a rede e o armazenamento, identidade que é um `id` e nunca uma
posição, uma permissão pedida no momento do uso. Os cursos depois desta bifurcação, a começar por
`mobile-offline`, supõem essa forma e nenhum dos três kits.
