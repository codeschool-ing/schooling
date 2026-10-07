---
title: Entradas
version: 1
---

As entradas óbvias são formulários e endpoints de API. **As que causam incidentes costumam ser as que
ninguém listou como entrada**, porque não pareciam uma quando foram construídas. Um mapa das
entradas da Vereda passou por cinco tipos, e só o primeiro estava na lista de alguém antes.

| tipo | no portal | quem consegue mandar |
|---|---|---|
| **pedidos de pessoas** | login, agendamento, cancelamento, a página de perfil | qualquer um para o login; pacientes depois dele |
| **arquivos** | o upload do PDF do exame | pacientes depois do login |
| **chamadas de outros sistemas** | o webhook de pagamento | qualquer um que conheça o endereço, hoje |
| **ferramentas da equipe** | a agenda, as anotações e o visualizador de exames do console | a equipe, e hoje qualquer um que chegue à página de login |
| **configuração e dados que você carrega** | variáveis de ambiente, a lista de clínicas importada de uma planilha todo mês | o bruno, e quem edita essa planilha |

### Perguntas para cada entrada

Quatro perguntas bastam para ordenar as entradas antes de qualquer análise detalhada:

1. **Quem chega até ela sem credencial?** Qualquer um na internet, qualquer paciente logado, só a
   equipe, um fornecedor específico.
2. **O que ela muda?** Nada (uma leitura), os dados de quem manda, os dados de outras pessoas,
   dinheiro.
3. **O que a interpreta?** Um campo de formulário lido como texto é simples. Um PDF interpretado por
   uma biblioteca é uma grande quantidade de código de outra pessoa rodando sobre bytes escolhidos
   pelo atacante, que é a T14.
4. **De que tamanho e com que frequência?** Um upload sem limite de tamanho é a T10; um formulário de
   agendamento que manda um SMS a cada envio é a T11.

O webhook responde às quatro perguntas tão mal quanto qualquer entrada da Vereda: qualquer um chega
até ele, ele mexe com dinheiro, o corpo dele é tratado como confiável, e nada limita quantas vezes é
chamado. Estar no topo da lista não é surpresa, mas o mapa o torna visível para quem não estava na
sala na aula 3.

### A planilha

A última linha é a de que as pessoas riem e não deveriam. Todo mês alguém exporta a lista de
clínicas e fisioterapeutas de uma planilha e a carrega no banco. A planilha é compartilhada com um
contador de fora. Uma célula com algo que o carregador não esperava é uma entrada vinda de alguém de
fora da Vereda, chegando com as permissões do dono do banco. Ela não está no DFD porque é um passo
manual, e um passo manual é um fluxo como outro qualquer.
