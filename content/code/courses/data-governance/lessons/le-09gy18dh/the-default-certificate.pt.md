---
title: O certificado que ninguém confere
version: 1
---

A aula 1 terminou com uma linha no log do servidor: a sessão da Carla estava `SSL enabled`,
protocolo TLS 1.3, e ninguém tinha configurado nada. Foi daqui que isso veio:

```
ana@lab:~/gov$ sudo -u postgres psql -c "SHOW ssl" -c "SHOW ssl_cert_file"
 ssl 
-----
 on
(1 row)

            ssl_cert_file             
--------------------------------------
 /etc/ssl/certs/ssl-cert-snakeoil.pem
(1 row)

ana@lab:~/gov$ sudo openssl x509 -in /etc/ssl/certs/ssl-cert-snakeoil.pem -noout -subject -issuer
subject=CN = localhost
issuer=CN = localhost
```

O Ubuntu liga o `ssl` em todo cluster que cria e o aponta para um certificado chamado
**snakeoil**, gerado quando o pacote foi instalado. O subject dele é `localhost`, e o emissor
também é `localhost`: **ele é autoassinado**, garantido por ninguém além de si mesmo. O nome é
honesto quanto a isso: *snake oil*, óleo de cobra, é o remédio milagroso que não cura nada.

E mesmo assim a conexão *está* cifrada:

```
ana@lab:~/gov$ psql service=bruno -c "SELECT ssl, version, cipher FROM pg_stat_ssl WHERE pid = pg_backend_pid()"
 ssl | version |         cipher         
-----+---------+------------------------
 t   | TLSv1.3 | TLS_AES_256_GCM_SHA384
(1 row)
```

`pg_stat_ssl` é a visão que o servidor tem da criptografia de cada sessão, e esta diz TLS 1.3 com
AES-256 em modo GCM — uma cifra forte, negociada corretamente. Quem escuta a rede entre o Bruno e
o servidor vê texto cifrado.

## O que o certificado deveria acrescentar

**A criptografia mantém o ouvinte do lado de fora. Não diz com quem você está falando.** O
certificado é o que responde a isso: uma assinatura de alguém em quem o cliente confia, dizendo que
a chave do outro lado pertence a `db.ipe.example`. Sem conferência, o cliente cifraria do mesmo
jeito para uma máquina que se pusesse no meio do caminho e apresentasse uma chave própria — e a
troca de senha, as consultas e as linhas iriam todas cifradas, para a parte errada.

O SCRAM, da aula 1, torna isso mais difícil do que parece, porque a senha nunca atravessa o fio.
Mas as consultas e os resultados atravessam, e um pipeline que puxa todos os clientes toda noite
vale a interceptação só pelos resultados. Então uma conexão que carrega dado pessoal deve conferir
o certificado, o que quer dizer que alguém precisa emitir um que valha a conferência.

## Uma conferência vale o que vale aquilo contra o que se confere

O certificado snakeoil não tem como ser conferido de forma útil, porque não há contra o que
conferi-lo: toda máquina Ubuntu tem o seu, todos chamados `localhost`, cada um assinado por si
mesmo. A seção 5 o troca por um emitido pela autoridade certificadora do laboratório, para o nome
que os clientes realmente usam. Antes, o lado do cliente: o que o psql faz hoje, e por que ele
nunca reclamou.
