---
title: O pipeline é um alvo, porque guarda as chaves
version: 1
---

Quinze aulas trataram o pipeline como quem confere: ele varre o código, as dependências, os segredos
e a imagem, e a aula 14 o tornou a única parte que assina. **Cada um desses trabalhos faz o pipeline
valer um ataque.** Um job de CI guarda o que o laptop de quem desenvolve não deveria guardar: um token
que escreve no repositório, credenciais do registry, a chave que assina releases e, muitas vezes, um
caminho até produção. Quem consegue fazer o job rodar uma linha escolhida por si leva tudo isso,
durante o tempo do job, sem tocar numa única máquina de produção.

### O que um job guarda, e quem consegue dirigi-lo

A imagem comum é que um pipeline roda "o nosso código". Ele roda o que o evento que o iniciou mandar
rodar, e na maioria das plataformas vários eventos podem ser iniciados por gente de fora do time:

| o que o job guarda | de onde vem | quem pode influenciar o que roda |
|---|---|---|
| um token do repositório | a plataforma de CI, para cada job | quem escreveu o arquivo de workflow, e de quem é o código que o job baixa |
| credenciais do registry | o cofre de segredos da plataforma | os mesmos, mais toda action que o job usa |
| uma chave de assinatura | os arquivos do próprio servidor de CI, como na aula 14 | todo script que o build roda, já que o `ci/sign.sh` vem do commit |
| alcance de rede | o lugar do runner na rede | qualquer coisa que o job execute |

**A coluna da direita é a superfície de ataque**, e ela é mais longa do que parece: um pull request de
um estranho, o título que alguém digitou nesse pull request, o autor de uma action que o workflow
nomeia por tag, e a pessoa que controla a máquina em que o runner está.

@@FIGURE surface@@

### Incidentes que passaram pelo pipeline

A aula 12 colocou incidentes reais na cadeia de suprimentos. Dois deles passaram exatamente por esta
porta, e vale relê-los do ponto de vista do pipeline.

- **Codecov, 2021.** O uploader em Bash que milhares de pipelines baixavam e rodavam a cada job foi
  alterado na origem para mandar as variáveis de ambiente do job para outro lugar. Todo pipeline que o
  rodou entregou as credenciais que os jobs guardavam. Nada mudou nesses repositórios.
- **tj-actions/changed-files, 2025.** Uma GitHub Action muito usada teve as tags de versão movidas
  para um commit que imprimia os segredos do runner no log do job. Todo workflow que nomeava a action
  por tag rodou o commit novo na execução seguinte; os que a nomeavam por commit, não.

Nenhum dos dois incidentes precisou de uma falha no código das vítimas. **Os dois dependeram do que um
job confiava sem conferir**: um script buscado na hora da execução, e uma tag que outra pessoa podia
mover.

### O que esta aula faz a respeito

Quatro controles, cada um de poucas linhas, e cada um mostrado no linkbox:

1. **Privilégio mínimo para o token do job**: declarar as permissões de que o job precisa, e nada
   mais.
2. **Entrada não confiável continua sendo dado**: o que o autor de um pull request escreveu chega a um
   shell por uma variável de ambiente, nunca colado no script.
3. **Código de terceiros por commit**: toda action fixada num hash completo de commit, com a versão num
   comentário para quem lê.
4. **O runner faz parte da confiança**: uma máquina nova por job sempre que possível, e um relato claro
   do que a própria máquina deixa um job fazer.

Os três primeiros são propriedades de um arquivo de workflow, e por isso a próxima seção escreve o
pipeline do linkbox para o GitHub Actions e deixa um scanner lê-lo. O quarto é sobre máquinas, e a
própria CI deste curso é o exemplo. **Os runners hospedados do GitHub não são usados em lugar nenhum
desta aula**: a máquina de gravação não consegue rodá-los, então todo workflow aqui é lido e auditado,
nunca executado, e o que o GitHub faz com um vem da documentação do GitHub.
