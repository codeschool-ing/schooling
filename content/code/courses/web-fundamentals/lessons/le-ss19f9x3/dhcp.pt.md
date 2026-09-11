---
title: De onde vem o endereço
version: 1
---

Ninguém digitou o seu endereço. Você entrou numa rede e um instante depois tinha um, junto com uma
máscara, um gateway e um lugar para mandar consultas de nome — quatro configurações, nenhuma delas
escolhida por você.

O maquinário que distribui isso é o **DHCP**, e ele vale uma seção porque a maior parte do que dá
errado numa conexão nova dá errado aqui.

## Quatro perguntas no escuro

O incômodo é que uma máquina sem endereço precisa pedir um, e pedir normalmente exige um endereço. O
DHCP contorna isso gritando, em quatro passos.

| passo | quem | o que diz |
|---|---|---|
| descoberta | a máquina nova | tem alguém aqui que distribui endereços? |
| oferta | o servidor | tem — que tal `192.168.1.24`? |
| pedido | a máquina nova | eu fico com esse |
| confirmação | o servidor | é seu, pelas próximas doze horas |

Os dois primeiros vão para o endereço de broadcast, porque nenhum dos lados tem ainda algo mais
específico para usar. A troca inteira leva alguns milissegundos e é a razão de um aparelho "entrar"
numa rede em vez de simplesmente estar nela.

## Um aluguel, não um presente

Esse último passo é o que as pessoas não percebem. Um endereço é **alugado por um tempo fixo**, não
concedido.

Na metade do aluguel, a máquina pede renovação, e quase sempre recebe o mesmo endereço de volta. Se
ela ficar desligada tempo suficiente o aluguel expira, o endereço volta para o bolo, e outra coisa
pode ficar com ele.

O que explica uma classe inteira de confusão:

- uma impressora que funcionava ontem e não é achada hoje — ela voltou com outro endereço, e o que
  apontava para o antigo ainda aponta;
- uma regra escrita contra o endereço de um aparelho que silenciosamente deixa de valer;
- uma máquina que ficou uma semana desligada voltando como vizinha de outra pessoa.

A resposta, onde importa, é uma **reserva**: o servidor é instruído a sempre dar a este MAC aquele
IP. Que é a razão prática de o número da seção anterior aparecer na tela de configuração de um
roteador.

## Chegam quatro coisas, não uma

É fácil pensar no DHCP como "pegar um endereço". Normalmente são quatro configurações, e as outras
três é onde moram as falhas interessantes.

**O endereço e a máscara** você já conhece. **O gateway** é a última linha da tabela de rotas da
aula dois — para onde mandar tudo que não for local. **O servidor DNS** é para onde vão as consultas
de nome, que é a aula oito.

Então uma máquina pode ter um endereço perfeitamente válido e ainda assim não conseguir fazer nada,
porque o gateway que lhe deram está errado. E pode alcançar qualquer coisa por endereço enquanto
todo nome falha, porque o servidor DNS que lhe deram não responde. São falhas diferentes com causas
diferentes, e as duas parecem *a internet não está funcionando*.

## O endereço que significa que falhou

Um valor vale reconhecer de bate-pronto. Se uma máquina pede e nada responde, a maioria dos sistemas
operacionais se dá um endereço em `169.254.x.x`.

Essa faixa é *link-local* — ela permite que duas máquinas num fio falem entre si sem servidor
nenhum, o que é ocasionalmente útil. Mas se você a vê numa rede que deveria ter um roteador, ela
significa exatamente uma coisa: **nada respondeu ao pedido de DHCP.** O cabo, a associação com o
Wi-Fi, ou o próprio servidor.

É um dos sintomas isolados mais úteis que existem em rede, porque aponta para um passo específico em
vez de para uma falha vaga.

## E ele confia em quem responder primeiro

A mesma propriedade do ARP, pelo mesmo motivo. Uma máquina aceita a primeira oferta que recebe, e
nada verifica que a máquina ofertante tenha autoridade alguma.

Então um segundo servidor DHCP numa rede — montado por engano, o que acontece quando alguém pluga um
roteador doméstico numa tomada de escritório — começa a distribuir endereços e um gateway apontando
para si mesmo. Metade das máquinas pega as configurações certas e metade pega as erradas, dependendo
de quem respondeu primeiro.

Vale saber porque o sintoma é bizarro: alguns aparelhos funcionam perfeitamente e outros não, sem
padrão por tipo ou lugar, e cada máquina individual parece corretamente configurada.

## Onde isto te deixa

Um endereço é alugado em vez de possuído, entregue numa troca de quatro passos que começa com um
broadcast, e chega com uma máscara, um gateway e um servidor DNS. Aluguéis expiram, que é por que
endereços se mexem; reservas são como você os prende. `169.254` quer dizer que nada respondeu, e a
primeira resposta é a acreditada.

A sua máquina agora tem um endereço, sabe o que é local, e consegue achar a placa de um vizinho. A
última pergunta desta aula é o que acontece com esse endereço privado na saída do prédio — e essa é
o vídeo.
