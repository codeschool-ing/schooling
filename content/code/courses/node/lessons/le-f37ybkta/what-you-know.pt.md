---
title: O que a aula 21 do javascript já cobriu
version: 1
---

**A aula 21 do javascript tratou de pacotes do lado de quem publica um; esta aula trata deles do lado
de quem roda um servidor em cima deles.** A primeira metade é pressuposta aqui, e vale reler se algo
estiver nebuloso:

| aula 21 do javascript | o que ela estabeleceu |
|---|---|
| um pacote e o `package.json` | uma pasta de código com nome e versão, instalada em `node_modules` |
| versões e faixas | `^1.2.0` aceita qualquer 1.x a partir de 1.2.0, `~1.2.0` qualquer 1.2.x, e `1.2.0` exatamente essa |
| o lockfile | o `package-lock.json` registra a versão exata de tudo o que foi instalado, e vai para o commit |
| pnpm e Yarn | dois outros gerenciadores de pacotes, com o mesmo trabalho e outra organização no disco |
| uma instalação roda código | os scripts de `install` de um pacote rodam com as suas permissões, e o `--ignore-scripts` os recusa |
| publicar | o `npm publish`, e o que `files` e `private` decidem |

Aquela aula usava um registry próprio no seu computador, para que nada instalado viesse de outro
lugar. **Esta usa o registry público, `registry.npmjs.org`**, porque é de lá que vêm as dependências
de um servidor. Então as versões e as contagens nas transcrições são o que o registry tinha no dia em
que este curso foi gravado, em outubro de 2026; na sua máquina uma contagem pode variar em um ou dois
pacotes, e os comandos não.

## O que muda quando o pacote é um servidor

Uma biblioteca é instalada nos projetos de outras pessoas, então o `package.json` dela é uma promessa
para estranhos: quais versões do Node ela suporta, quais arquivos dela eles podem importar. **Um
servidor é instalado num lugar só, por você**, e o `package.json` dele é uma descrição de como rodá-lo. Ele diz quais comandos o iniciam e o testam, de quais pacotes ele precisa em produção e de quais só
no seu notebook, e as versões exatas que foram testadas juntas. Cada seção desta aula é uma dessas
coisas.
