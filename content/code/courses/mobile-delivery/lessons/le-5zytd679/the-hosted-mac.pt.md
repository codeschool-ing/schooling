---
title: O Mac hospedado, e quanto ele custa
version: 1
---

**Um build iOS precisa do macOS, e o macOS só roda em hardware da Apple, então todo pipeline que
gera para iOS aluga um Mac ou tem um.** Esse fato sozinho molda o CI mobile mais do que qualquer
outro: minutos de Linux são baratos e fartos, minutos de Mac não são nem uma coisa nem outra, e um
pipeline desenhado para a web desperdiça os caros. *O pipeline desta lição roda no GitHub Actions e
não pôde ser rodado para o curso; os passos Linux dele são os comandos rodados aqui, e os passos Mac
foram lidos na documentação do GitHub e da Apple.*

## As opções

| de onde vem o Mac | o que é | o preço, como publicado |
|---|---|---|
| runners macOS do **GitHub Actions** | um Mac virtual novo por job, com Xcode instalado | minutos grátis para repositórios públicos; para os privados, um minuto de macOS é cobrado como um múltiplo de um minuto de Linux, dez vezes na tabela de 2025 do GitHub |
| **Xcode Cloud** | o CI da própria Apple, configurado no Xcode e no App Store Connect | 25 horas de computação por mês incluídas na assinatura de desenvolvedor, página da Apple em outubro de 2026 |
| **EAS Build** | os builders hospedados do Expo, para projetos Expo e React Native | um plano gratuito com fila, planos pagos com prioridade; ele guarda as credenciais, lição 2 |
| **o seu próprio Mac** como runner próprio | um Mac mini embaixo de uma mesa, registrado no serviço de CI | o hardware, a energia, e alguém que atualize o Xcode nele |

*A página de cobrança do GitHub não abriu na máquina de gravação; o multiplicador é o número que o
GitHub publicou em 2025.*

## Gastar minutos de Mac só onde precisa

- **Rode tudo o que não é build iOS no Linux.** Testes unitários da lógica comum, a checagem de
  ficha da lição 4, a de privacidade da lição 5, lint, o build Android: nenhum precisa de Mac.
- **Gere o iOS só quando importa**: no branch de release, numa tag, ou num pull request que mexe em
  código iOS, e não a cada commit em cada branch.
- **Faça cache do que um Mac baixaria de novo.** A próxima seção.
- **Ponha um limite de tempo no job.** Um simulador travado num Mac hospedado cobra até o job ser
  morto, e o limite padrão no GitHub Actions é de seis horas.

## As três plataformas

Um app em **Kotlin** não precisa de Mac nenhum, e o pipeline inteiro dele roda no Linux. Um app em
**Swift** precisa de um em todo build. Um app **React Native** precisa de um só para a metade iOS;
os testes JavaScript, o build Android e toda checagem antes deles rodam no Linux, e o build iOS roda
num Mac ou no EAS. Esse é o desvio que o desenho deste curso nomeia para a lição 10: **a equipe sem
Mac aluga um por minuto, pelo serviço de outra pessoa.**
