---
title: Duas lojas, duas rampas
version: 1
---

**Uma liberação em etapas dá uma versão nova a uma fração das pessoas que a receberiam, e aumenta
a fração conforme a confiança cresce.** As duas lojas oferecem uma, e diferem em quem controla os
passos. *A metade da Apple foi lida na ajuda do App Store Connect sobre phased release, outubro de
2026; a do Google, na Central de Ajuda do Play Console como publicada em 2025. Nenhum console foi
aberto.*

## Google Play: um staged rollout

Quando um release vai para produção, você escolhe uma **porcentagem** dos usuários que o recebem, e
a aumenta quando quiser: 1%, depois 5%, depois 20%, depois 100%, nos dias que você escolher. Você
pode **interromper** a liberação, o que a impede de chegar a mais alguém, e **retomá-la** depois na
mesma porcentagem ou numa maior. Os usuários são sorteados pelo Google, e quem foi sorteado continua
sorteado conforme a porcentagem cresce.

## A App Store: um phased release

O **phased release para atualizações automáticas** da Apple segue um calendário fixo de sete dias:

| dia | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
|---|---|---|---|---|---|---|---|
| fração dos usuários com atualização automática | 1% | 2% | 5% | 10% | 20% | 50% | 100% |

Você não escolhe os passos, mas pode **pausar** por até 30 dias no total, e **liberar para todo
mundo** a qualquer momento. Dois detalhes mudam do que ele protege você:

- **Ele vale só para atualizações automáticas.** A ajuda da Apple diz com todas as letras: *apps e
  atualizações em phased release podem ser baixados manualmente da App Store por qualquer pessoa a
  qualquer momento.* Quem abre a loja e toca em Atualizar recebe a versão nova no primeiro dia.
- **Instalações novas recebem a versão nova.** O escalonamento é sobre atualizações para quem já
  tem o app; um primeiro download é sempre da versão atual.

## A outra plataforma

Um app React Native tem as duas rampas, uma por loja, e elas andam em relógios diferentes: a do
Google anda quando você a move, a da Apple anda todo dia a não ser que seja pausada. Uma equipe que
quer as duas metades do mesmo release chegando à mesma fração de pessoas no mesmo dia precisa
conduzir a do Google à mão no ritmo da Apple.
