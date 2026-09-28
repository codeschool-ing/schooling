---
title: Quando uma região falha
version: 1
---

A imagem que a maioria tem de uma pane é binária: a nuvem está no ar, ou a nuvem caiu. Incidentes
reais são mais parciais que isso, e a distinção mais útil para ler um, e para se proteger de um, é
entre as duas metades de todo serviço. **O plano de controle muda as coisas; o plano de dados as
executa.**

O **plano de controle** é a parte que você chama para criar, mudar ou apagar: lançar uma instância,
redimensionar um banco, criar um usuário, editar um registro DNS, mudar as regras de um load balancer.
É uma API, com um console por cima, e é usado algumas vezes por dia.

O **plano de dados** é a parte que faz o trabalho que você já configurou: a instância rodando e
respondendo pedidos, o bucket servindo objetos, os servidores DNS respondendo consultas pelos
registros que já existem, o load balancer encaminhando tráfego. Ele é usado milhões de vezes por dia,
e os provedores o constroem para continuar funcionando quando o plano de controle não funciona.

Então uma falha pode tirar a capacidade de mudar qualquer coisa enquanto tudo o que já roda continua.
**Suas instâncias continuam atendendo; você não consegue lançar uma nova.** É uma tarde ruim para quem
tem um plano de recuperação que começa com "lançar mais instâncias", e uma tarde tranquila para quem
tem um plano que não precisava de nada novo.

## Planos de recuperação que precisam do plano de controle

Olhe as estratégias de recuperação da seção sobre uma segunda região com essa distinção em mãos.
Backup e restauração constrói um sistema inteiro na segunda região: cada passo é uma chamada ao plano
de controle, feita na segunda região, o que funciona desde que o problema esteja na primeira. Agora
olhe dentro de uma região. Um projeto que sobrevive à falha de uma zona **lançando** instâncias
substitutas na zona que sobrou precisa do plano de controle no pior momento possível, quando muitos
outros clientes estão tentando fazer a mesma coisa. Um projeto que já tem capacidade suficiente
rodando na outra zona não precisa de nada do plano de controle: as verificações de saúde do load
balancer, que são plano de dados, desviam o tráfego.

A própria orientação da AWS chama essa propriedade de **estabilidade estática**, em inglês static
stability: um sistema que continua funcionando durante uma falha sem precisar mudar nada. Ela custa
capacidade que você paga e não usa num dia normal, que é a mesma troca que a aula inteira vem fazendo.

## Serviços globais que vivem numa região

Alguns serviços são globais, no sentido de que você não escolhe uma região para eles: gestão de
identidade e acesso, DNS, a rede de distribuição de conteúdo. Os planos de dados deles são espalhados.
**Os planos de controle nem sempre são**, e a AWS documenta, na sua orientação sobre isolamento de
falhas, que os planos de controle de vários serviços globais, entre eles IAM, Route 53 e CloudFront,
rodam na `us-east-1`.

Leia o que isso significa para uma aplicação que vive inteira na `sa-east-1`. Se a `us-east-1` tiver
um problema no plano de controle, suas instâncias em São Paulo continuam rodando, os papéis que suas
instâncias já têm continuam funcionando, e o seu DNS continua respondendo. Mas criar um papel novo ou
mudar um registro DNS para apontar para o seu standby pode não funcionar até a Virgínia se recuperar.
**Um plano de failover cujo primeiro passo é "mudar o registro DNS" depende de uma região que você
nunca escolheu.**

## Saiba onde vivem as suas dependências

A aula prática é uma tabela, escrita antes do dia em que ela for necessária. Para cada dependência,
anote onde ela roda e o que você perde quando aquele lugar falha:

| dependência | onde roda | se aquele lugar falhar |
|---|---|---|
| instâncias da aplicação | `sa-east-1`, zonas a e b | a outra zona carrega a carga |
| banco de dados | `sa-east-1a`, standby na `sa-east-1b` | o standby é promovido |
| registros DNS | global; mudanças passam pela `us-east-1` | as respostas continuam, as edições talvez não |
| gateway de pagamento | o provedor e a região do próprio gateway | pergunte a eles, e anote a resposta |
| provedor de login | a região do provedor | ninguém novo entra |

Duas linhas dessa tabela não são suas. Serviços de terceiros também rodam em algum lugar, e um gateway
ou um provedor de login hospedado numa região é uma dependência dessa região, quer a sua conta tenha
tocado nela ou não. A tabela só é útil se for honesta também sobre essas linhas.

Um prédio pegando fogo é a falha para a qual todo mundo se prepara. A que surpreende é uma dependência
que ninguém conhecia e que acaba vivendo em outro lugar. O `observability` é o curso que vigia essas
dependências enquanto elas rodam; esta tabela é o que diz quais vigiar.
