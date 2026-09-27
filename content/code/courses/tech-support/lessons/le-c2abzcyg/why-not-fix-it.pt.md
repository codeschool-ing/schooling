---
title: Por que não consertar você mesmo
version: 1
---

O conserto parece um comando: deixar o arquivo legível para `sales`. A técnica tem `sudo` no `srv1` e
poderia rodá-lo num segundo. Há três motivos para não fazer:

- **O arquivo não é seu.** É da equipe que cuida do sistema de vendas. Alguém o deixou `600`, e você não
  sabe se foi um erro ou uma decisão de segurança, como uma senha colocada nele hoje de manhã.
- **Você não seria o último a mexer nele.** O próximo deploy deles pode voltar a configuração, e o sistema
  cai de novo sem ninguém saber por que funcionou por um dia.
- **A sua mudança entraria no incidente deles**, sem eles saberem. Quando investigarem, vão achar uma
  permissão que não definiram, e perder tempo com ela.

**Acesso não é autoridade.** Ter `sudo` numa máquina quer dizer que você consegue mudá-la, não que o dono
concordou com o que você muda. A aula 14 volta a isso. Aqui, o movimento certo é o da figura dos níveis:
escalonamento funcional, para os donos, com tudo o que você achou.
