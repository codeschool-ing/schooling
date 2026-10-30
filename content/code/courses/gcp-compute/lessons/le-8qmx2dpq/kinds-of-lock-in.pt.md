---
title: Os tipos de aprisionamento
version: 1
---

"Aprisionamento", o lock-in, costuma ser dito como uma palavra para um medo: que o provedor tenha
você nas mãos e aumente o preço. **São pelo menos cinco coisas diferentes, e cada uma custa um tanto
diferente para desfazer**, então uma equipe que as trata como uma só ou recusa tudo que é útil ou
não percebe nada até o dia em que quer sair.

## Cinco tipos

**A gravidade dos dados.** Dados são a coisa mais pesada que um sistema tem. Um terabyte no Cloud
Storage custa dinheiro para sair, leva tempo para copiar e precisa continuar consistente enquanto se
move, e todo serviço que o lê tende a se instalar perto dele. A seção 04 dá preço ao primeiro desses
pontos.

**Interfaces proprietárias.** Pub/Sub, Firestore, Spanner e Cloud Tasks têm cada um uma API que não
existe em outro lugar. Código que os chama diretamente precisa ser reescrito para sair, e a
reescrita é proporcional a quantos lugares os chamam, não ao tamanho do sistema.

**Configuração da plataforma.** As revisões e a divisão de tráfego de um serviço do Cloud Run
(lição 9), a política de atualização de um grupo gerenciado de instâncias (lição 4), os filtros de
um gatilho do Eventarc (lição 18): nada disso está no seu código, tudo isso molda como o código se
comporta, e tudo está escrito nos termos do Google. É barato reescrever e fácil esquecer.

**Identidade e permissões.** Contas de serviço, papéis do IAM, Workload Identity (lição 15). Todo
outro provedor tem as mesmas ideias com outros nomes e outras regras, e as permissões são a parte
da migração que falha em silêncio: um serviço que sobe e depois não consegue ler nada.

**Compromissos.** Um desconto por compromisso de uso compra até 55% a menos na maioria dos tipos de
máquina, e em troca você paga por um ou três anos, usando a capacidade ou não. É aprisionamento por
contrato, o único tipo com uma data escrita, e o único de que o departamento financeiro vai lembrar
você.

E mais um, que não é técnico: **o que a equipe sabe.** Pessoas que aprenderam os hábitos do Cloud
Run e o console do Google são um custo real de mudar, e esse custo se paga num ano mais lento, não
numa fatura.

## Nem tudo é ruim

Todo tipo de aprisionamento é também um tipo de valor. O Pub/Sub prende porque faz bem algo que a
equipe então não precisa construir; um compromisso de três anos prende porque é barato. **A pergunta
nunca é se aceitar aprisionamento, e sim qual aprisionamento compra o suficiente para valer o que
custaria sair.** O resto desta lição dá números a essa frase.

| tipo | o que compra | o que custa desfazer |
|---|---|---|
| gravidade dos dados | armazenamento que outro opera | saída de dados, tempo de cópia, uma virada |
| interfaces proprietárias | um serviço que você não construiu | reescrever cada ponto de chamada |
| configuração da plataforma | comportamento sem código | reescrever a configuração, com cuidado |
| identidade | um modelo único de quem pode fazer o quê | redesenhar as permissões |
| compromissos | um preço menor | os meses que faltam do prazo |
| conhecimento | uma equipe que anda rápido aqui | um ano mais lento em outro lugar |
