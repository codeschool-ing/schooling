---
title: App Transport Security, e o http desta aula
version: 1
---

**Toda URL desta aula começa com `http://`, e num iPhone isso é recusado a menos que o app diga o
contrário.** A Apple chama a regra de App Transport Security, ATS: as conexões de um app pelo
`URLSession` têm de usar HTTPS, com um certificado em que o sistema confia e uma versão moderna de TLS.
Um pedido `http` simples a um servidor na internet falha antes de sair do telefone. Nada nesta seção
foi executado, porque a regra mora no iOS e não no Foundation de código aberto, e é também por isso
que todo pedido desta aula funcionou no Linux sem pedir licença. Ela foi escrita a partir da
documentação da Apple para `NSAppTransportSecurity` e `NSAllowsLocalNetworking`, lida em 30 de
outubro de 2026.

## Por que a regra existe

Um pedido sem criptografia pode ser lido e alterado por qualquer um entre o telefone e o servidor: o
Wi-Fi do café, um roteador comprometido, uma rede que injeta publicidade. As sessões de um planner de
estudos não são segredo, mas a mesma conexão leva as credenciais da conta em qualquer app de verdade,
e uma resposta que pode ser alterada no caminho é uma resposta em que o app não pode acreditar. **O
ATS faz da escolha segura o padrão, para que ser inseguro custe uma linha que alguém precisa escrever
e outra pessoa consegue revisar.**

## A exceção de que este curso precisa, e nada mais

O servidor do planner escuta em `127.0.0.1` e fala HTTP simples, o que está bem na sua própria
máquina e é exatamente o que o ATS recusa. A documentação da Apple diz algo preciso sobre isso: do iOS
10 ao iOS 16, conexões a endereços IP, nomes `.local` e nomes sem domínio eram permitidas por padrão,
e **o iOS 17 deixou de permitir endereços IP por padrão.** A chave que volta a permitir essas conexões
locais, e nada mais, é a `NSAllowsLocalNetworking`. No `Info.plist` do target do app, durante o
desenvolvimento:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!-- Info.plist (the development keys only) -->
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsLocalNetworking</key>
        <true/>
    </dict>
</dict>
</plist>
```

O simulador compartilha a rede do Mac, então `127.0.0.1` dentro do simulador é o próprio Mac e chega
ao servidor rodando num terminal ali. Um iPhone de verdade é outra máquina: o `127.0.0.1` dele é o
telefone, e ele chegaria ao servidor pelo endereço do Mac na rede local.

## A exceção que este curso não usa

A `NSAllowsArbitraryLoads` desliga o ATS para toda conexão, e é a linha que uma busca pela mensagem
de erro mais sugere. **É a correção errada, e a revisão da App Store pergunta por ela**: a
documentação da Apple diz que um app que a liga tem de justificá-la quando é enviado. O servidor de
verdade do planner seria alcançado por HTTPS, e a exceção de desenvolvimento acima ficaria num
`Info.plist` usado só pela configuração `Debug`, que a configuração de build `INFOPLIST_FILE` do target
consegue nomear por configuração.

| chave | o que ela permite | quando é a certa |
|---|---|---|
| nenhuma | só HTTPS, com as verificações do ATS | um app em produção falando com o próprio servidor |
| `NSAllowsLocalNetworking` | conexões simples a nomes locais e endereços IP | desenvolvimento contra um servidor na sua máquina |
| `NSExceptionDomains` | uma exigência menor só para domínios nomeados | o servidor de um terceiro que você não pode mudar, com um motivo |
| `NSAllowsArbitraryLoads` | tudo | quase nunca, e tem de ser justificada à revisão |
