---
title: Escolhendo um método
version: 1
---

Cinco métodos em três aulas bastam para qualquer equipe discutir qual usar. A discussão é quase
sempre desnecessária, porque **eles respondem a perguntas diferentes**, e a maioria dos modelos
reais usa dois ou três deles para partes diferentes do trabalho.

| método | responde | use quando | o principal limite |
|---|---|---|---|
| **STRIDE** | o que pode dar errado em cada parte? | sempre, como primeira passada sobre um DFD | sem ordenação; cego a cadeias |
| **PASTA** | o que mais importa para o negócio, e por quê? | quem decide não é técnico, ou o risco é sobretudo de negócio | caro; precisa do negócio na sala |
| **LINDDUN** | que dano o sistema causa à privacidade das pessoas, mesmo funcionando como projetado? | o sistema guarda dado pessoal, e sobretudo dado sensível | não cobre ataques ao sistema |
| **árvores de ataque** | qual o caminho mais barato até este objetivo, e que controle o corta? | escolher entre controles para um objetivo que importa | um objetivo por árvore; só conhece os caminhos desenhados |
| **DREAD** | quão ruim é esta ameaça, de zero a dez? | ler um modelo antigo que o usou | as notas não concordam entre avaliadores |

### O que a Vereda faz

Para uma mudança no portal, a rotina da Vereda tem três passos, e cada um vem de um método
diferente:

1. **STRIDE** nos fluxos que a mudança toca, por interação onde uma fronteira é cruzada.
2. **LINDDUN** em qualquer fluxo que leve dado pessoal para fora da Vereda, ou em qualquer
   repositório novo que o guarde.
3. **Uma árvore de ataque** só quando um objetivo do estágio 1 ganha um caminho novo, para conferir
   se os controles que já existem ainda o cortam.

A moldura do PASTA, como a aula 4 descreveu, decide a ordem em que os achados são tratados. O DREAD
não é usado. Quando é preciso ordenar, as aulas 9 a 11 dão uma ordenação com números que dá para
conferir.

### Combinar é normal

Nenhum método diz ser completo, e os que são honestos sobre isso o dizem na própria documentação. O
STRIDE achou a T08 perguntando sobre divulgação, e o LINDDUN achou mais três coisas sobre o mesmo
fluxo. A árvore de ataque descobriu que um controle era desperdício para um objetivo. O ponto cego de
cada método é o assunto de outro, e um modelo que usou um só herda o ponto cego desse método
inteiro.
