---
title: A parte que exige um Mac, dita agora
version: 1
---

**Duas aulas deste curso exigem um Mac, e é melhor saber disso agora do que na aula 14.** As
ferramentas da Apple para construir um app iOS, o Xcode e seus compiladores, rodam no macOS e em
nenhum outro lugar, e o mesmo vale para a assinatura que põe um app num iPhone. Todo o resto do curso
roda em Linux, Windows ou Mac.

| aula | o que ela exige além do seu computador |
|---|---|
| 3, a metade iOS | um Mac com Xcode, para abrir e rodar o projeto iOS que o Capacitor gerou |
| 14, a metade Apple | um Mac com Xcode, e uma assinatura paga do Apple Developer Program |
| 3, 4 e 5, a metade Android | o Android Studio, o SDK dele e um emulador, ou um celular Android com cabo |
| 7 a 9 | opcionalmente um celular Android ou iOS com o app Expo Go; o navegador serve para o resto |
| 13 e 14, as lojas | uma conta no Google Play e, para iOS, a assinatura acima |
| todo o resto | Node.js 22, git e um navegador, que você já tem |

**Sem um Mac você ainda consegue fazer todas as aulas.** As metades iOS das aulas 3 e 14 você lê como
material, não como prática: o que o projeto Xcode contém, quais arquivos você edita, o que é uma
identidade de assinatura e por que a loja pede uma. As metades Android cobrem as mesmas ideias com
ferramentas que você consegue rodar. O serviço de build na nuvem do Expo, que a aula 9 descreve,
constrói apps iOS em máquinas Apple que ele aluga, e é um dos jeitos de publicar na App Store sem ter
um Mac. Ele exige uma conta no Expo, e o plano gratuito tem um limite mensal que o Expo define.

**As contas das lojas custam dinheiro e são opcionais.** A aula 14 mostra o que cada loja pede e para
onde vai o dinheiro, e o projeto da aula 16 pode ser lançado como um instalador desktop e um pacote
Android que você mesmo distribui, sem loja nenhuma.

## O que este curso não conseguiu rodar

O curso foi gravado num computador Linux, e alguns passos não puderam ser rodados lá. **Cada um está
marcado onde aparece**, com a documentação de onde vem, para você saber qual saída está lendo como
evidência e qual como descrição:

- **nada do Xcode**, pelo motivo acima;
- **nenhum build Android, emulador ou APK**: a máquina de gravação não alcançava o servidor de
  downloads do Google, então o Android Studio e o SDK do Android nunca foram instalados nela. A aula 3
  mostra os passos a partir da documentação do Google, e todo arquivo Android que o curso cita é um que
  o Capacitor gerou;
- **nenhum envio a loja e nenhum build na nuvem do Expo**, que exigem contas e uma pessoa aceitando os
  termos delas.

Todos os outros comandos de uma transcrição foram rodados, e a saída deles está colada como voltou.
