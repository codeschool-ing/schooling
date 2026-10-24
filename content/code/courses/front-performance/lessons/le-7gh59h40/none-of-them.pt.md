---
title: Qual deles, ou nenhum
version: 1
---

**O meta-framework a usar é quase sempre o que pertence ao framework de interface que você já usa.**
Next.js se o app é React, Nuxt se é Vue, SvelteKit se é Svelte, e a renderização no servidor do
próprio Angular se é Angular. Trocar de framework de interface para ter outro meta-framework é
reescrever cada componente, e nada nas medidas desta aula vale isso sozinho.

Então a pergunta real é outra: este app precisa de um meta-framework?

## Quando o app puro basta

O planner da aula 1 renderiza num servidor, hidrata e tem navegação no cliente, sem framework, em
umas cem linhas. Isso deixa de ser uma boa ideia num tamanho fácil de reconhecer:

- **muitas rotas com parâmetros**, cada uma precisando dos seus próprios dados antes de renderizar;
- **páginas que têm de funcionar antes de o script chegar**, formulários incluídos, o que quer dizer
  tratar o envio de um formulário no servidor além de no navegador;
- **uma mistura de modos de renderização**, algumas páginas construídas antes e algumas por
  requisição;
- **mais de uma pessoa** escrevendo, que precisam de convenções que não inventaram.

Cada item dessa lista é algo que todo meta-framework já faz, testado por muito mais usuários do que
um app jamais terá. Abaixo desse tamanho, um app puro ou um renderizado no cliente feito só com o
Vite é menor, faz o build mais rápido e não tem nada dentro que você não escreveu. Um site sem dados
nenhum, só páginas de texto, não precisa de nenhum dos dois: a aula 3 constrói um a partir de
arquivos.

## O que comparar, se a escolha estiver aberta

Quando um time começa de fato do zero e pode escolher, estas são as coisas que diferem na prática,
na ordem de quantas vezes decidem:

1. **Onde ele vai rodar.** Os quatro rodam como servidor Node e como arquivos estáticos. Algumas
   hospedagens dão suporte melhor a um deles, com regeneração, otimização de imagens ou streaming
   embutidos na plataforma. A aula 1 de `front-delivery` é sobre quatro dessas hospedagens.
2. **O que o time já sabe.** Tratado acima, e costuma ser a resposta.
3. **Como o framework decide o que é estático.** A seção "Modo de renderização, por rota" mostrou um
   que decide pelo código e três que decidem pela configuração. Times que querem ler a renderização
   de um site num lugar só preferem o segundo jeito.
4. **O peso do runtime**, medido na seção "A mesma página, de quatro jeitos". Ele importa mais em
   páginas visitadas uma vez, vindas de uma busca, num celular, que é exatamente o visitante que as
   aulas 5 e 6 medem.

## O resto deste curso

Da aula 3 em diante, o planner puro é o app que é medido e mudado, e os quatro projetos só voltam
onde uma técnica é algo que o framework faz por você: geração estática e regeneração na aula 3,
hidratação e streaming na aula 4, divisão do código na aula 8. Toda técnica das aulas 5 a 11
funciona igual com qualquer um deles, porque acontece no navegador, nos cabeçalhos HTTP ou num
arquivo que o servidor manda, que é onde os frameworks terminam.
