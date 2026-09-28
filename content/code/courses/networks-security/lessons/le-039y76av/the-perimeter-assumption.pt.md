---
title: A premissa que o Zero Trust remove
version: 1
---

Toda regra deste curso até aqui se apoiou em uma premissa: **de onde um pacote vem diz alguma coisa
sobre confiar nele ou não**. A LAN da equipe pode usar a aplicação porque é a LAN da equipe; o proxy
pode alcançá-la porque é o endereço do proxy. A aula 4 desenhou zonas com essa base, e a aula 19 as
estreitou até endereços únicos.

Essa premissa falha de três jeitos que o curso já encontrou. Uma máquina de dentro é comprometida
(aula 9), e tudo o que a zona dela alcança passa a ser do atacante. Um endereço é emprestado ou
forjado (aula 8). E a rede deixa de ter um dentro: laptops em casa, serviços no data center de outra
pessoa, uma filial ligada por um túnel. No laboratório, a LAN da equipe alcança a página de
administração da aplicação porque a configuração de base diz que a LAN pode:

```
ana@laptop:~$ probe app:8080 app:8443
app:8080               open
app:8443               blocked
ana@laptop:~$ curl -s http://192.168.20.10:8080/admin/
admin console
```

A porta 8080 está aberta para o `laptop`, e o console de administração responde. Nada perguntou
**quem** estava perguntando; a resposta dependeu de **onde** a requisição veio.

**Zero Trust** é o projeto que deixa de tratar a localização como credencial. A forma curta é *nunca
confie, sempre verifique* (*never trust, always verify*): toda requisição é autenticada e autorizada
pelos próprios méritos, venha de qual rede vier, com o menor acesso que a atenda, e com a premissa de
que parte da rede já é hostil. O padrão americano que o descreve, o NIST SP 800-207, diz em substância
que nenhuma confiança implícita é concedida a um usuário ou a um dispositivo por causa de onde ele está
na rede.

Não é um produto nem um substituto para firewalls. É uma mudança **naquilo em que a decisão se
apoia**: do endereço, que a rede conhece, para a identidade, que precisa ser provada.
