---
title: O Metro, o bundler, e o servidor de desenvolvimento
version: 1
---

**O Metro transforma um projeto de centenas de arquivos no único arquivo que o Hermes roda.** Ele é o
bundler do React Native, e tanto o `npx expo start` quanto o `npx expo export` o comandam. Conhecer as
três etapas dele explica quase tudo o que você vai vê-lo fazer, inclusive os erros.

| etapa | o que o Metro faz | o que pode dar errado ali |
|---|---|---|
| resolução | a partir do `index.ts`, segue cada `import` até um arquivo, no seu projeto ou no `node_modules` | *Unable to resolve module*: um erro de digitação, ou um pacote não instalado |
| transformação | passa cada arquivo pelo Babel, que tira o TypeScript e transforma o JSX em chamadas de função | um erro de sintaxe, informado com o arquivo e a linha |
| serialização | põe os arquivos transformados num bundle só, cada um embrulhado como um módulo com um número | raramente algo; é daqui que vem o tamanho |

**O bundle é diferente para cada plataforma.** Um arquivo chamado `button.android.tsx` é escolhido no
lugar de `button.tsx` quando o Metro empacota para Android, e a aula 6 é sobre isso. Por isso o Metro
sempre recebe o pedido de um bundle *para* uma plataforma, e o servidor de desenvolvimento responde
para qualquer uma que pedir.

## O servidor de desenvolvimento

O `npx expo start` sobe o Metro como servidor, por padrão na porta 8081, e o deixa rodando. Um celular
no Expo Go, um development build ou um navegador se conecta a ele e pede o bundle; quando você salva
um arquivo, o Metro refaz só o que mudou e o app é avisado para recarregar aquela parte. Suba-o num
terminal e deixe-o lá; os comandos abaixo são digitados num segundo terminal.

```
ana@dev:~/planner$ curl -s localhost:8081/status; echo
packager-status:running
ana@dev:~/planner$ curl -s 'localhost:8081/index.bundle?platform=android&dev=true' -o dev.js
ana@dev:~/planner$ ls -l dev.js
-rw-r--r-- 1 ana ana 4280118 Oct 30 15:25 dev.js
ana@dev:~/planner$ grep -c "Study planner" dev.js
1
ana@dev:~/planner$ grep -o "This week" dev.js | head -1
This week
```

É exatamente o que um development build num celular faz quando começa: pede a esse servidor o
`index.bundle` da sua plataforma, em modo de desenvolvimento, e roda o que volta. O primeiro pedido
demorou um pouco porque o Metro transformou cada arquivo; o próximo é mais rápido, porque os arquivos
transformados ficam em cache no `.expo` do projeto e na pasta temporária do sistema. O texto do
`App.tsx` está no bundle como foi escrito, porque um bundle de desenvolvimento é JavaScript, não
bytecode.

**Um bundle de desenvolvimento é grande de propósito.** Ele mantém os avisos e as checagens do React,
carrega o nome de cada função para que os erros sejam legíveis, e não é minificado nem compilado. A
aula 18 o compara com o bundle de release e encontra os bugs que moram na diferença.

## Fast Refresh

Quando um arquivo é salvo, o servidor empurra os módulos alterados para cada app conectado, e o React
renderiza de novo os componentes definidos neles **mantendo o estado**: um formulário digitado pela
metade continua pela metade. Isso é o **Fast Refresh**, e ele vem ligado. Dois casos caem num
recarregamento completo, que perde o estado: uma edição num arquivo que exporta algo além de
componentes, e um erro de sintaxe corrigido depois de ter quebrado o app.

*O Fast Refresh num celular ou num emulador não foi rodado para este curso.* No navegador ele se
comporta do mesmo jeito, pelo `npx expo start --web`, que abre o app e o recarrega a cada salvamento.

## Quando o servidor se comporta mal

Quase todo problema estranho do servidor de desenvolvimento tem a mesma cura: **pare-o e suba-o com
`--clear`**, que esvazia o cache do Metro. Um pacote instalado com o servidor rodando, um arquivo
renomeado que o Metro ainda resolve pelo nome antigo, uma variável de ambiente que não mudou: cada um
é um cache velho. O `npx expo start --clear` custa um primeiro bundle lento, e resolve.
