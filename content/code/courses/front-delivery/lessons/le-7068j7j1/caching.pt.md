---
title: Cache, e o que ele pode e não pode guardar
version: 1
---

**Uma máquina de CI começa vazia toda vez, então toda execução baixa toda dependência de novo, a menos que
algo guarde os downloads entre execuções.** O `cache: npm` no workflow é esse algo: ele salva o cache de
downloads do npm no fim de uma execução e o restaura no começo da seguinte, com um hash do
`package-lock.json` como chave. Mesmo lockfile, mesmo cache.

A diferença é fácil de medir no seu computador, porque o npm guarda o mesmo tipo de cache na sua pasta
pessoal. Instale com um cache vazio, que é a primeira execução de uma máquina de CI, e depois com um
cache já quente:

```
ana@dev:~/planner$ rm -rf node_modules /tmp/empty-cache && time npm ci --cache /tmp/empty-cache > /dev/null

real	0m2.767s
user	0m2.623s
sys	0m1.421s
ana@dev:~/planner$ rm -rf node_modules && time npm ci --cache /tmp/empty-cache > /dev/null

real	0m1.812s
user	0m1.644s
sys	0m1.016s
```

A primeira execução buscou cada pacote no registry; a segunda os achou no cache e só os desempacotou.
Aqui a diferença é de mais ou menos um segundo, porque esta máquina fica perto do registry e o planner tem
algumas dezenas de pacotes. Numa rede mais lenta, ou num projeto com centenas de pacotes, a mesma
diferença vira minutos por execução, multiplicados por cada push.

## O que vai para o cache, e o que não vai

**O cache guarda downloads, nunca o `node_modules`.** O `npm ci` continua apagando o `node_modules` e
montando-o de novo a partir do lockfile em toda execução; o cache só lhe poupa a rede. Isso é de
propósito. Um `node_modules` em cache é uma pasta de uma execução anterior, no estado em que ficou, que é
exatamente o que uma cópia limpa existe para descartar.

Três regras vêm de a chave ser o lockfile:

- **um lockfile alterado é um cache novo.** Atualizar uma dependência custa uma execução lenta, e depois
  o cache novo está quente.
- **o cache não consegue mudar o que é instalado.** Se ele tiver um pacote que o lockfile não cita, o
  `npm ci` o ignora, e os hashes de integridade do lockfile recusam um download adulterado.
- **nada secreto vai para um cache.** Caches são compartilhados entre os branches de um repositório de
  jeitos que a plataforma documenta e pouca gente lê; trate um cache como público dentro do repositório.

A saída do próprio build, `dist/`, também não vai para o cache. Ela é o que está sendo conferido, então é
feita do zero em toda execução.
