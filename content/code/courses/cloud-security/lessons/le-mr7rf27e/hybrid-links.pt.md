---
title: Links híbridos, e o "de dentro" que cresceu
version: 1
---

**Um link híbrido liga uma rede na nuvem à rede da própria empresa, para que as máquinas de cada lado
alcancem as do outro por endereço privado. A consequência de segurança é que a ideia de "de dentro"
dos dois lados passa a incluir o outro lado, inteiro, a menos que alguém a estreite de propósito.**
Nada nesta seção foi executado: o moto guarda uma conexão VPN como um registro e não carrega
tráfego, então o que segue vem da documentação dos provedores.

## Três tipos de link

| link | AWS | Azure | Google Cloud |
|---|---|---|---|
| um túnel cifrado pela internet | Site-to-Site VPN | VPN Gateway | Cloud VPN |
| um circuito privado pela instalação de um provedor | Direct Connect | ExpressRoute | Cloud Interconnect |
| o diretório da empresa, estendido para a nuvem | IAM Identity Center com um provedor de identidade externo | Microsoft Entra Connect, sincronizando o Active Directory com o Entra ID | Google Cloud Directory Sync, ou federação com o Entra ID ou outro provedor |

Os dois primeiros juntam redes; o terceiro junta identidades, e também é uma emenda.

## O que dá errado num link de rede

**Uma regra que confiava "no escritório" agora confia no escritório inteiro.** Antes do link, um
security group que permitia `10.0.0.0/8` admitia as máquinas da própria nuvem. Depois dele, a mesma
regra admite todo notebook, impressora e servidor de teste esquecido da rede da empresa, porque eles
dividem a faixa. Uma máquina comprometida no escritório fica a um salto do banco de dados. Nomeie as
faixas estreitas de que o lado da nuvem realmente precisa ouvir, e nada mais largo.

**Rotas chegam sem ninguém mudar a nuvem.** Um link que troca rotas dinamicamente, por BGP, pode
acrescentar sozinho as rotas que aprende às tabelas de rotas da nuvem: a AWS chama isso de
propagação de rotas, e é uma configuração de cada tabela de rotas. Uma rede que a equipe do data
center criar no ano que vem aparece então dentro da VPC sem nenhuma mudança do lado da AWS. A aula 8
lê tabelas de rotas; uma rota propagada é o tipo de entrada que essa revisão deve procurar.

**Um circuito privado é privado, o que não é o mesmo que cifrado.** A documentação da AWS diz que o
Direct Connect não cifra o tráfego em trânsito por padrão. O circuito evita a internet pública, e os
dados nele são legíveis por qualquer coisa no caminho, a menos que você acrescente criptografia: a
criptografia na camada de enlace que algumas conexões dedicadas suportam, ou um túnel VPN rodando
sobre o circuito. A aula 11 trata de criptografia em trânsito.

**O link é uma fronteira, então trate-o como uma.** Um firewall no link, com regras nos dois
sentidos, transforma "tudo do outro lado" de volta numa lista que alguém escreveu.

## O que dá errado num link de identidade

Quando o diretório da empresa alimenta o da nuvem, **as contas da nuvem são tão seguras quanto o
diretório**. Quem consegue mudar um usuário sincronizado ou pôr alguém num grupo sincronizado
on-premises consegue dar acesso na nuvem, sem tocar na nuvem. A orientação da Microsoft para o Entra
ID é manter as contas que têm os papéis administrativos dele como contas só da nuvem, e não
sincronizadas, para que tomar o diretório on-premises não entregue junto a administração da nuvem.

O contrário também vale: **remover uma pessoa tem que acontecer no lugar que é a origem**. Um
desligado desativado no console da nuvem, mas ainda ativo no diretório on-premises, volta na próxima
sincronização. A aula 6 acompanha uma pessoa que saiu e cujo acesso ninguém revogou.

## Uma revisão para qualquer emenda

Quatro perguntas, uma para cada coisa que atravessa, cobrem as emendas desta aula e a maioria das
outras:

1. **Identidade:** algum segredo de um lado mora no outro? Troque por federação.
2. **Rota:** que faixas cada lado aceita do outro, e quem decidiu?
3. **Registro:** uma ação que atravessou pode ser seguida dos logs de um lado para os do outro?
4. **Política:** para cada controle decidido uma vez, ele é aplicado nos dois lados, e como você sabe?
