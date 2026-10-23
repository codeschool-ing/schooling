---
title: O que muda entre ambientes
version: 1
---

O boxoffice roda em mais de um lugar. Na sua máquina, ele escuta em `localhost` e fala com um banco sem
senha. Na aula 16, ele roda num container, onde `localhost` é o próprio container e nada de fora
conseguiria alcançá-lo. Em produção, ele tem um site de verdade na frente, um banco que outra pessoa
administra e tokens que ninguém da equipe deveria conseguir ler numa tela. **O código é o mesmo em todos
eles; alguns valores não são**, e esses valores são a configuração dele.

Um bom teste para saber se algo é configuração: muda entre ambientes enquanto o código continua o mesmo?
Aqui está tudo o que o boxoffice lê de fora ou tem escrito no próprio código, como a aula 13 o deixou:

| configuração | onde está agora | varia? |
|---|---|---|
| endereço HTTP | `localhost:8080`, no `main.go` | sim: um container precisa escutar em todas as interfaces |
| endereço gRPC | `localhost:9090`, no `main.go` | sim, pelo mesmo motivo |
| banco de dados | `DATABASE_URL` | sim, e vira segredo quando leva senha |
| tokens da equipe | `BOXOFFICE_MANAGER_TOKEN`, `BOXOFFICE_DOOR_TOKEN` | sim, e são segredos |
| pool de conexões | `10`, no `main.go` | sim: depende do limite do banco e de quantas cópias rodam |
| timeout de escrita | `10 * time.Second`, no `main.go` | às vezes |
| o site autorizado a chamar | `https://tickets.example.com`, no `routes.go` e de novo no `ws.go` | sim: um site de homologação é outro site |
| timeout de cabeçalho | `2 * time.Second`, no `main.go` | **não** |

A última linha é a útil. O `ReadHeaderTimeout` é a defesa contra o Slowloris da aula 1; não existe
ambiente em que ele devesse ser trinta segundos, então torná-lo configurável só acrescenta um jeito de
errar. **Configuração é o que difere legitimamente, não tudo o que é número.** As rotas, a ordem dos
middlewares e as regras de validação também são código, pelo mesmo motivo.

O site aparece duas vezes, uma para o CORS e outra para os WebSockets, e essa é a outra coisa que a
configuração conserta: uma configuração, lida uma vez, entregue a tudo o que precisa dela.

## De onde vêm os valores

Esta aula dá a cada configuração três fontes, cada uma sobrescrevendo a anterior:

1. **Um padrão no código**, escolhido para que a máquina de quem desenvolve funcione sem nada definido.
2. **Uma variável de ambiente**, que é como uma plataforma de containers, uma unit do systemd ou um job de
   CI entrega configurações a um programa. É aqui que vivem os valores de produção.
3. **Uma flag na linha de comando**, para uma pessoa num terminal mudar uma coisa numa execução.

A ideia de guardar a configuração no ambiente vem do twelve-factor app, um conjunto de práticas escrito
na Heroku em 2011, e ela sobreviveu à plataforma para a qual foi escrita: o ambiente é a única interface
que todo jeito de rodar um programa suporta.

## Um build, muitos lugares

O que a lista deixa de fora é uma configuração chamada "ambiente", com valores como `development` e
`production`, e código que se ramifica nela. **Cada ramo desses é código que só roda em produção**, ou
seja, é exercitado pela primeira vez por usuários reais. Os ambientes devem diferir em valores, um
endereço, um tamanho, um site, e nunca em quais linhas rodam. A aula 16 gera um binário e uma imagem, e
todo ambiente roda esse mesmo arquivo com valores diferentes em volta.
