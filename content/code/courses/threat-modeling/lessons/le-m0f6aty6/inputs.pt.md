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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l06-two-inputs\" aria-label=\"Duas entradas pelas quatro perguntas. O webhook de pagamento: qualquer um o alcança, ele muda dinheiro, o corpo dele é confiável, e nada limita quantas vezes é chamado. O upload de exame: pacientes o alcançam depois do login, ele muda os exames do paciente e o armazenamento, uma biblioteca de PDF o interpreta, que é a T14, e não tem limite de tamanho, que é a T10.\"><text x=\"355.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">webhook de pagamento</text><text x=\"585.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">upload de exame</text><rect x=\"20.0\" y=\"35.0\" width=\"220.0\" height=\"42.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"32.0\" y=\"56.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">alcance sem credencial?</text><rect x=\"250.0\" y=\"35.0\" width=\"210.0\" height=\"42.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"355.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">qualquer um</text><rect x=\"470.0\" y=\"35.0\" width=\"230.0\" height=\"42.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\"></rect><text x=\"585.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pacientes após o login</text><rect x=\"20.0\" y=\"87.0\" width=\"220.0\" height=\"42.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"32.0\" y=\"108.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o que muda?</text><rect x=\"250.0\" y=\"87.0\" width=\"210.0\" height=\"42.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"355.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">dinheiro: um agendamento pago</text><rect x=\"470.0\" y=\"87.0\" width=\"230.0\" height=\"42.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\"></rect><text x=\"585.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">os exames do paciente, armazenamento</text><rect x=\"20.0\" y=\"139.0\" width=\"220.0\" height=\"42.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"32.0\" y=\"160.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o que interpreta?</text><rect x=\"250.0\" y=\"139.0\" width=\"210.0\" height=\"42.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"355.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">um corpo em que se confia</text><rect x=\"470.0\" y=\"139.0\" width=\"230.0\" height=\"42.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"585.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">uma biblioteca de PDF (T14)</text><rect x=\"20.0\" y=\"191.0\" width=\"220.0\" height=\"42.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"32.0\" y=\"212.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">tamanho, frequência?</text><rect x=\"250.0\" y=\"191.0\" width=\"210.0\" height=\"42.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"355.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">nada limita as chamadas</text><rect x=\"470.0\" y=\"191.0\" width=\"230.0\" height=\"42.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"585.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sem limite de tamanho (T10)</text><text x=\"360.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">âmbar: a resposta que põe uma entrada perto do topo da lista</text></svg>", "caption": "O webhook responde mal às quatro perguntas, e é por isso que fica no topo da lista antes de qualquer análise detalhada."}
```

### A planilha

A última linha é a de que as pessoas riem e não deveriam. Todo mês alguém exporta a lista de
clínicas e fisioterapeutas de uma planilha e a carrega no banco. A planilha é compartilhada com um
contador de fora. Uma célula com algo que o carregador não esperava é uma entrada vinda de alguém de
fora da Vereda, chegando com as permissões do dono do banco. Ela não está no DFD porque é um passo
manual, e um passo manual é um fluxo como outro qualquer.
