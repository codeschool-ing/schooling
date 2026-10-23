---
title: O portal, e como toda aula funciona
version: 1
---

Conselho sobre código seguro sem código nenhum escorrega. Por isso toda aula deste curso trabalha
sobre pedaços de um sistema só. A **Vereda Fisioterapia** é uma pequena rede de quatro clínicas de
fisioterapia em São Paulo, inventada para este catálogo. O **portal do paciente** permite que cerca
de nove mil pacientes marquem e cancelem sessões, paguem por elas e enviem os PDFs dos exames que o
médico pediu. Um **console da equipe** separado permite que as recepcionistas cuidem da agenda e que
os fisioterapeutas escrevam as notas clínicas.

Quem escreveu a maior parte do portal foi **ana**, a única desenvolvedora em tempo integral da
Vereda. Ela é cuidadosa e ocupada, que é a condição normal de quem desenvolve, e o portal tem as
falhas que uma pessoa cuidadosa e ocupada escreve. Cada aula pega uma delas, numa pequena aplicação
Flask própria que guarda só o bastante do portal para mostrá-la: o botão de cancelar aqui, a busca na
aula 5, o envio de exames na aula 14.

Os dados também são inventados. Os pacientes só têm primeiro nome (`lucia`, `rafael`, `marta`), os
endereços terminam em `.example` e toda data é de novembro de 2026. Dado de saúde é a categoria mais
sensível de dado pessoal na lei brasileira de proteção de dados, a LGPD, e o portal guarda muito
dele. É por isso que as falhas dele importam, e por isso nada real é usado para mostrá-las.

### Como toda aula funciona

Toda aula segue o mesmo ciclo, e você vai fazê-lo no fim desta.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l01-method\" aria-label=\"O ciclo que toda aula deste curso segue, desenhado como quatro passos em círculo. Um: escrever o teste que enuncia o requisito. Dois: rodar e ver falhar, o que prova que a falha existe. Três: corrigir o código. Quatro: rodar e ver passar, e então fazer o commit dos dois. O teste fica na pasta, então a falha não volta sem que ninguém perceba.\"><defs><marker id=\"l01-method-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"260\" y=\"20\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"38.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">escrever o teste que</text><text x=\"360.0\" y=\"51.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">enuncia o requisito</text><rect x=\"500\" y=\"110\" width=\"190\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"595.0\" y=\"128.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">ver falhar:</text><text x=\"595.0\" y=\"141.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a falha é real</text><rect x=\"260\" y=\"200\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"225.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">corrigir o código</text><rect x=\"30\" y=\"110\" width=\"190\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"125.0\" y=\"128.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">ver passar,</text><text x=\"125.0\" y=\"141.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">commit dos dois</text><path d=\"M460 45 L595 45 L595 110\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-method-ah-paper-dim)\"></path><path d=\"M595 160 L595 225 L460 225\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-method-ah-paper-dim)\"></path><path d=\"M260 225 L125 225 L125 160\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-method-ah-paper-dim)\"></path><path d=\"M125 110 L125 45 L260 45\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l01-method-ah-paper-dim)\"></path><text x=\"360\" y=\"280\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">o teste fica, então a falha não volta sem ninguém perceber</text></svg>", "caption": "Quatro passos, em toda aula. Uma correção sem um teste falhando antes dela é uma correção que ninguém consegue mostrar que funcionou."}
```

1. **Um teste diz o que o código deve fazer**, inclusive o que ele deve recusar. Um requisito que
   ninguém escreveu vira uma função de teste com um nome que se lê como frase.
2. **Você roda o teste contra o código com falha e vê falhar.** A falha é a evidência. Uma
   requisição cuja resposta mostra o defeito, na sua própria aplicação, vale mais do que qualquer
   descrição da falha.
3. **Você muda o código**, com a chamada segura que a aula explica.
4. **Você roda os testes de novo e vê passar**, e então faz commit do código e do teste juntos. O
   teste fica, então se a linha insegura voltar algum dia, alguém descobre no mesmo dia.

O desenvolvimento guiado por testes chama os dois primeiros passos de *vermelho* e *verde*, e este
curso pega essa ordem de propósito: uma correção sem um teste falhando antes dela é uma correção que
ninguém consegue mostrar que funcionou. A aula 19 transforma os testes do curso inteiro numa suíte
que roda a cada mudança.

### As regras do laboratório

Este é um curso sobre defender código, e ele se impõe três regras.

- **As falhas vivem só na sua aplicação, no seu computador.** Todo programa aqui ouve em
  `127.0.0.1`, que só a sua própria máquina alcança. Nunca inicie um deles em `0.0.0.0`, e nunca
  publique um: um programa com falha proposital numa rede é um alvo.
- **Uma falha é mostrada por um teste ou por uma requisição, e corrigida em seguida.** O curso nunca
  coleciona truques para passar por uma defesa, porque quem defende não precisa deles. Quem defende
  precisa reconhecer a falha no código, num log ou numa configuração, corrigi-la e provar a correção.
- **Nada aqui é apontado para um sistema que não é seu.** Entrar no sistema de outra pessoa sem
  permissão é crime no Brasil (Lei 12.737, de 2012) e na maioria dos outros países, seja qual for a
  intenção.
