---
title: O que precisa de permissão, e quando ela é concedida
version: 1
---

**Uma permissão é o sistema se pondo entre um app e algo que pertence à pessoa: a localização, a
câmera, os contatos, as fotos, ou a atenção dela por meio de uma notificação.** A imagem comum é uma
lista de caixas que a pessoa marca ao instalar, depois do que o app pode fazer qualquer coisa. Essa
imagem está uma década desatualizada nas duas plataformas. A maioria das permissões que importam é
pedida com o app rodando, uma de cada vez, e a pessoa pode dizer não a cada uma, ou mudar de ideia
depois.

## Android: dois tipos, separados pelo risco

**O Android separa as permissões pelo quanto podem prejudicar a pessoa, e só o tipo arriscado é
pedido.** A documentação do Android sobre permissões nomeia os dois que importam para a maioria dos
apps:

| | na instalação | em tempo de execução |
|---|---|---|
| o que protege | acessos que quase não afetam a privacidade, como a rede | dados privados e hardware sensível: localização, câmera, microfone, contatos |
| quem concede | o sistema, quando o app é instalado | a pessoa, num diálogo, com o app rodando |
| o que a pessoa vê | um aviso na página do app na loja | um diálogo do sistema nomeando o app e o acesso |
| o outro nome no Android | *normal* (e *signature*, para apps assinados juntos) | *dangerous*, perigosa |

Um app declara os dois tipos no manifest com `<uses-permission>`. Declarar uma permissão de tempo de
execução não a concede; só torna possível pedi-la. A documentação do Android manda conferir uma
permissão de tempo de execução antes de todo uso, porque a pessoa pode revogá-la nos Ajustes a
qualquer momento, e às vezes o próprio sistema a revoga.

**As notificações entraram no tipo de tempo de execução no Android 13.** A documentação do Android
sobre a permissão de notificação diz que, num aparelho com Android 13 ou mais novo, as notificações de
um app recém-instalado ficam desligadas por padrão, e ele precisa pedir `POST_NOTIFICATIONS` antes de
enviar qualquer uma. Para o planner, que lembra a aluna de uma sessão, é dessa permissão que esta aula
trata.

## iOS: um tipo só, e uma frase sua

**No iOS nada sensível é concedido na instalação; o primeiro uso pergunta.** Quando um app tenta pela
primeira vez chegar à câmera, à localização ou à fototeca, o sistema mostra um diálogo, e o app fornece
uma linha dele: a *purpose string*, uma frase dizendo por quê. Ela fica no `Info.plist` do app, sob uma
chave por recurso, como `NSCameraUsageDescription`.

**Essa frase não é opcional, e a falta dela não é educada.** A documentação da Apple sobre pedir acesso
a recursos protegidos diz que, sem uma purpose string válida, as tentativas de usar o recurso falham "e
podem fazer o app travar", e a documentação sobre captura de mídia é mais direta: sem a chave, "o
sistema encerra o seu app". A App Review rejeita um app cujo código chega a um recurso protegido sem
uma. A frase precisa ser precisa e específica, diz a Apple, e aparece no idioma da pessoa, então é
traduzida como qualquer outro texto.

As notificações perguntam do mesmo jeito, por uma chamada própria em vez de uma chave: a documentação
da Apple sobre `requestAuthorization` diz que a primeira chamada pergunta à pessoa, o sistema guarda a
resposta, e "chamadas seguintes a este método não perguntam de novo".

## Do que o planner precisa

**O planner precisa de uma permissão de tempo de execução, e vale notar como isso é pouco.** Ele
guarda o plano no aparelho, o que não exige permissão nenhuma (a aula 16 diz onde). Ele chega à rede,
o que no Android é uma permissão de instalação e no iOS não exige nada. Ele envia um lembrete antes de
uma sessão, o que exige a permissão de notificação nas duas. Ele não precisa de localização, contatos,
câmera nem fototeca, e por isso nunca as pede.

Essa última frase é uma decisão, não um fato sobre o planner, e a aula 13 a toma de propósito: toda
permissão que um app tem é um dado que ele poderia coletar, e uma loja pede que você declare o que
coleta. Uma permissão que você nunca pede é uma pergunta que você nunca precisa responder, num diálogo
ou num formulário.
