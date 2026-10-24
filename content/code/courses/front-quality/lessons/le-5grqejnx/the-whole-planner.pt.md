---
title: O que o planner guarda agora
version: 1
---

**O planner começou este curso como um app que ninguém tinha testado, escrito com uma semana errada, um
placeholder no lugar de um rótulo, nenhuma defesa contra um script numa nota, e um foco que ninguém
conseguia ver.** Cada uma dessas coisas é agora um teste que falha se ela voltar: trinta e seis testes de
unidade e de componente, vinte e oito de ponta a ponta, e vinte e quatro commits de histórico dizendo
quando cada um chegou.

```
ana@dev:~/planner$ npx tsc --noEmit && npx vitest run 2>&1 | grep -E "Test Files|Tests "
 Test Files  6 passed (6)
      Tests  36 passed (36)
ana@dev:~/planner$ npx playwright test 2>&1 | tail -1
  28 passed (9.5s)
```

```
ana@dev:~/planner$ git add -A
ana@dev:~/planner$ git commit -q -m "A page that reflows at 320 pixels, and a size floor for every button"
ana@dev:~/planner$ git log --oneline | wc -l
24
```

| parte do curso | o que deixou no planner |
|---|---|
| testes, aulas 1 a 4 | testes de unidade das funções puras, testes de componente com o Testing Library, testes de ponta a ponta com o Playwright, e o bug de fuso horário que eles acharam |
| segurança, aulas 5 a 9 | uma sessão num cookie `HttpOnly`, uma política de CORS, uma CSP com o seu relatório, uma nota mostrada como texto, uma checagem de Origin, e uma página que nenhum outro site consegue enquadrar |
| acessibilidade, aulas 10 a 13 | o axe na WCAG 2.2 AA nos dois temas, um caminho de teclado com um foco visível que fica onde faz sentido, nomes, landmarks e uma linha de status para um leitor de tela, contraste calculado, alvos que dá para acertar, movimento que dá para recusar, e uma página que reflui |

## O que nada disso substitui

Cada terço deste curso terminou na mesma frase com outras palavras: **um teste verifica o que alguém pensou
em perguntar.** Os testes de unidade não sabem o que o usuário quis dizer; os testes de segurança não
conhecem o ataque que ninguém imaginou; o axe e todo teste das aulas 11 a 13 não ouvem a página. A
caminhada pelo teclado, a escuta com um leitor de tela e o zoom de 400% continuam sendo trabalho de alguém,
uma vez a cada mudança numa tela, e os testes são o que deixa essa hora curta o bastante para ser feita.
