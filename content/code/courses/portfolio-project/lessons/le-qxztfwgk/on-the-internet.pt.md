---
title: Na internet: um domínio e um plano gratuito
version: 1
---

Passar do laboratório para a internet muda três coisas, e nenhuma delas é a aplicação.

**Um domínio.** Um nome que você registra, que custa uma taxa anual pequena em qualquer registrador, e um
registro DNS que o aponta para o seu servidor: um registro `A` para o endereço IPv4 do servidor, ou um
`CNAME` para um nome que a hospedagem lhe dá. Subdomínios de um domínio que você já tem são grátis, e um
portfólio precisa de um só.

**Um certificado de verdade.** Com um nome público, o Caddy obtém o certificado de uma autoridade pública
sozinho, então o Caddyfile perde a linha `tls internal`:

```
loans.example.org {
	reverse_proxy 127.0.0.1:8000
}
```

Este arquivo **não foi rodado neste curso**; o laboratório não tem nome público. É a diferença inteira, e o
Caddy precisa das portas 80 e 443 alcançáveis pela internet para provar que controla o nome.

**Um lugar para rodar.** Existem planos gratuitos para máquinas virtuais pequenas, para containers e para
sites estáticos, e eles mudam: os provedores criam, encolhem e retiram esses planos, e é por isso que esta
aula não cita nenhum nem os seus limites. Antes de escolher, confira cinco coisas nas páginas atuais do
próprio provedor:

- **se ele dorme** quando ocioso, deixando a primeira visita lenta;
- **se expira** depois de um período de teste;
- **se pede cartão**, e o que acontece quando um limite é ultrapassado;
- **onde ficam os dados**, se o plano gratuito não tem disco persistente;
- **como você sai**, já que um portfólio dura mais que a maioria dos planos gratuitos.

E guarde o laboratório. **Um deploy gravado é evidência que não expira**: se o plano gratuito sumir na
semana antes de uma entrevista, a transcrição desta aula, rodada no seu próprio projeto, ainda mostra a
quem avalia tudo o que o endereço mostraria.
