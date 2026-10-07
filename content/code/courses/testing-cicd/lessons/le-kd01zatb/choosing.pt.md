---
title: Escolher uma estratégia
version: 2
---

Cinco jeitos de pôr um release diante dos clientes, e o que cada um compra:

| | lacuna no serviço | duas versões ao mesmo tempo | caminho de volta | até onde um bug chega | custo extra |
| --- | --- | --- | --- | --- | --- |
| recreate | sim | nunca | reimplantar o antigo | todos | nenhum |
| rolling | não | durante a troca | outra troca | cresce com a troca | talvez uma instância a mais |
| blue-green | não | só na troca | virar a chave | todos, até a volta | uma segunda produção |
| canário | não | durante todo o canário | zerar a parte | a parte do canário | métricas por versão |
| feature flag | não | o código tem as duas | desligar a flag | a parte da flag | código e testes para os dois caminhos |

Elas se combinam. Um arranjo comum é blue-green ou rolling para o release, para os deploys serem
rápidos e fáceis de desfazer, e flags para as funcionalidades dentro dele, para cada uma chegar aos
clientes no seu próprio ritmo. Um canário entra por cima quando o tráfego é grande o bastante para
julgar, no sentido da seção 10.

## Perguntas que decidem

- **Duas versões podem rodar juntas?** Se não, neste release, o recreate é honesto e os outros não.
  Melhor ainda, dividir a mudança para que possam, que é o assunto da aula 11.
- **Com que rapidez um release ruim precisa ser desfeito?** Segundos apontam para blue-green ou uma
  flag; minutos permitem uma troca ao contrário.
- **Há tráfego para medir?** Um serviço com cem requisições por dia não consegue rodar um canário que
  signifique alguma coisa; ainda pode usar blue-green e flags.
- **Quem decide quando o cliente vê uma funcionalidade?** Se não é quem faz o deploy, uma flag.

Nenhuma destas estratégias substitui os testes das seis primeiras aulas. Elas limitam até onde um bug
vai depois de passar por eles, e quanto tempo fica. O release acima tinha um bug que nenhum teste
pegou; o blue-green o tirou do ar em três milissegundos, o canário o limitou a duas requisições, e a
flag teria retirado a funcionalidade sem mexer no release.
