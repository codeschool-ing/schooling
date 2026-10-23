---
title: Quando a instalação falha
version: 1
---

**A maioria das falhas de instalação nesta aula vem de cinco causas, e cada uma tem um sintoma que
dá para reconhecer.** Confira nesta ordem antes de procurar na web.

| sintoma | causa provável | o que fazer |
| --- | --- | --- |
| `node: command not found`, ou `java: command not found` | o runtime não está instalado, ou não está no seu `PATH` | reabra o terminal depois de instalar; no Windows, saia da sessão e entre de novo |
| `npm install` para enquanto *baixa o Chrome* ou o *chrome-headless-shell* | o download do navegador está bloqueado por um proxy ou firewall, ou o disco está cheio | libere os 700 MB de que ele precisa; atrás do proxy de uma empresa, defina `HTTPS_PROXY` antes de instalar e pergunte à equipe de TI em qual certificado confiar |
| o `mmdc` diz que *não encontrou o chrome-headless-shell* | a instalação rodou com o download do navegador desligado, ou com outro usuário | rode `npx puppeteer browsers install chrome-headless-shell` na mesma pasta, com o mesmo usuário |
| o `mmdc` diz que *rodar como root sem --no-sandbox não é suportado* | você está rodando como administrador, muitas vezes dentro de um contêiner | rode como usuário comum; foi o que as transcrições daqui fizeram |
| `docker: permission denied` no socket | o seu usuário não tem permissão para falar com o Docker | adicione o seu usuário ao grupo `docker` (Linux) e entre de novo, ou inicie o Docker Desktop |

## Duas que não são óbvias

**O Structurizr grava arquivos como o usuário de dentro do contêiner.** Se você roda o contêiner
sem dizer qual usuário ele deve ser, os arquivos que ele exporta pertencem a outro usuário, ou a
exportação não consegue criar a pasta. A seção do Structurizr passa o seu próprio usuário e grupo
para o `docker run` por esse motivo, e cria a pasta de saída antes.

**Um diagrama antigo pode falhar com uma versão nova.** Se um arquivo que renderizava no mês passado
falha hoje, veja se alguma versão mudou antes de olhar o arquivo. É por isso que cada comando desta
aula nomeia uma versão exata, e é por isso que um pipeline também deve nomear.

## Se ainda não funcionar

Rode de novo as verificações de versão da seção anterior e compare com a tabela de lá. Se uma
ferramenta não instala de jeito nenhum no seu computador, use o caminho da máquina virtual só para
ela: os arquivos da sua pasta `diagrams` podem ser copiados para a VM e de volta. Os editores online
servem para praticar a sintaxe, com a ressalva que a seção anterior fez.
