---
title: Quando o roteador diz não
version: 1
---

`send_config_set` envia linhas de configuração, e a aula 1 o usou. O que ele faz com uma linha que
o roteador recusa importa mais do que qualquer outra coisa nele. Um erro de digitação, `descripton`:

```schooling-example
{
  "language": "python",
  "file": "nm_config.py",
  "parts": [
    {
      "code": "from netmiko import ConnectHandler\n\nLINES = [\"interface eth2\", \"descripton branch 1 LAN\"]\n\nedge1 = ConnectHandler(device_type=\"cisco_ios\", host=\"edge1\", username=\"netops\",\n                       use_keys=True, key_file=\"/home/ana/.ssh/id_ed25519\")"
    },
    {
      "code": "print(edge1.send_config_set(LINES))\nprint(\"-- the same lines, with error_pattern\")",
      "note": "**Um erro de digitação, enviado sem verificação.** O roteador recusa a linha e diz isso, e `send_config_set` devolve a conversa como texto sem levantar nada."
    },
    {
      "code": "try:\n    edge1.send_config_set(LINES, error_pattern=r\"% \")\nexcept Exception as e:\n    print(type(e).__name__, \"-\", str(e).splitlines()[0])\nedge1.disconnect()",
      "note": "**`error_pattern` transforma a recusa numa exceção.** O FRR começa toda recusa com `%`, então uma linha começando com `%` em qualquer ponto da resposta para o script."
    }
  ]
}
```

```
ana@ctl:~$ python nm_config.py
 configure terminal
edge1(config)#  interface eth2
edge1(config-if)# descripton branch 1 LAN
% Unknown command: descripton branch 1 LAN
edge1(config-if)#  end
edge1# 
-- the same lines, with error_pattern
ConfigInvalidException - Invalid input detected at command: descripton branch 1 LAN, matched error: % 
```

A primeira metade é a conversa inteira, devolvida como texto. **O FRR recusou a linha**, `% Unknown
command`, e `send_config_set` retornou normalmente, sem exceção: o script teria seguido para o
próximo roteador achando que a descrição estava configurada. Esse é o padrão porque o Netmiko não
tem como saber como é a recusa de cada plataforma.

A segunda metade passa `error_pattern`, uma expressão regular que marca uma recusa. O FRR começa
toda recusa com `%` e um espaço, então o padrão é `% `, e as mesmas linhas agora levantam
`ConfigInvalidException`, nomeando o comando e o trecho que casou. **Todo script que configura por
um CLI precisa de uma verificação assim**, escrita para a sua plataforma; sem ela, as três falhas da
aula 1 voltam como uma falha silenciosa.

Mais dois hábitos da aula 1 valem aqui. Salve explicitamente, com `save_config()`, porque uma
configuração em execução some no próximo reboot. E **leia de volta o que você mudou**, porque uma
linha aceita ainda pode ser a linha errada.
