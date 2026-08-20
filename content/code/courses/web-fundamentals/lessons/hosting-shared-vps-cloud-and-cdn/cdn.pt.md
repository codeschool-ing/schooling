---
title: CDN: aproximar o conteúdo de quem pede
---

Uma **CDN** é uma rede de servidores espalhados pelo mundo que guardam cópias do seu conteúdo. Quem acessa de Lisboa recebe do nó de Lisboa, não do seu servidor em São Paulo.

Ela ataca exatamente o problema que largura de banda não resolve, três aulas atrás: **latência é distância**, e a única forma de reduzi-la é encurtar o caminho. Para arquivos estáticos — imagem, CSS, JavaScript, vídeo — o ganho é grande e a configuração é pequena.

A CDN não substitui a hospedagem: ela fica na frente dela. O seu servidor continua existindo e respondendo pelo que é dinâmico e pelo que a CDN ainda não tem em cache — é o que se chama de **origem**.

O efeito colateral que morde: como a CDN guarda cópias, publicar uma versão nova nem sempre aparece na hora. Ou se invalida o cache no deploy, ou se usa nome com impressão digital no arquivo — a mesma solução da aula de cache, agora em escala mundial.
