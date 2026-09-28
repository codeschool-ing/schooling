---
title: A retrospectiva do loanbook
version: 1
---

Aqui está ela, como entraria no repositório ao lado do README. É uma página, e toda afirmação nela pode ser
rastreada até algo deste curso.

```localised
# loanbook: uma retrospectiva

Cinco semanas, de 1º de junho a 6 de julho de 2026, quatro marcos, todos alcançados nas datas.

## O que foi bem
- A recusa entrou no segundo marco, logo depois do esqueleto. Acontecesse o que acontecesse
  depois, a única coisa que o projeto precisava provar estava feita em 15 de junho.
- O teste dela foi conferido tirando o índice e vendo o teste falhar.
- O deploy sobreviveu a ser derrubado: o systemd o reiniciou e os dados estavam no volume.

## O que não foi
- O marco das regras levou cinco dias úteis contra uma estimativa de três e meio. A
  estimativa cobria as duas regras e não o tratamento de erros e o estado vazio de que elas precisavam.
- Um erro inesperado ainda fecha a conexão em vez de responder 500.
- Não há estado de carregamento; num celular lento a tabela fica vazia por um instante.
- O nome de quem pega emprestado era desenhado como HTML até o commit de acessibilidade. Uma
  autorrevisão encontrou isso tarde, em código escrito duas semanas antes.

## O que eu faria diferente
- Estimar cada marco, incluindo os itens de deveria, e não só os de deve.
- Montar cada linha com textContent desde o primeiro commit que mostra entrada do usuário.
- Acrescentar o 500 e o estado de carregamento antes de chamar de v1.0.0.

## O que aprendi
- Uma restrição no banco é um lugar melhor para uma regra do que uma verificação no código,
  quando duas requisições podem chegar juntas.
- Uma ferramenta como o axe aprova coisas que um passeio pelo teclado não aprova.
```

Repare no tom. **Fatos, depois conclusões**: *cinco dias contra três e meio* antes de *estimar cada marco*.
**Sem culpa e sem desculpas**, inclusive consigo mesmo: *a autorrevisão encontrou tarde* diz o que aconteceu
e o que muda, que é tudo de que quem lê precisa. E **a seção do que não foi é a mais longa**, o que é honesto,
e é também o que torna crível a seção do que foi bem.
