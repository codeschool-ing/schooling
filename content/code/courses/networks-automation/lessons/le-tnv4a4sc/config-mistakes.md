---
title: When the router says no
version: 1
---

`send_config_set` sends configuration lines, and lesson 1 used it. What it does with a line the
router refuses matters more than anything else about it. A typo, `descripton`:

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
      "note": "**A typo, sent without a check.** The router refuses the line and says so, and `send_config_set` returns the conversation as text without raising anything."
    },
    {
      "code": "try:\n    edge1.send_config_set(LINES, error_pattern=r\"% \")\nexcept Exception as e:\n    print(type(e).__name__, \"-\", str(e).splitlines()[0])\nedge1.disconnect()",
      "note": "**`error_pattern` makes the refusal an exception.** FRR starts every refusal with `%`, so a line beginning with `%` anywhere in the answer stops the script."
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

The first half is the whole conversation, returned as text. **FRR refused the line**, `% Unknown
command`, and `send_config_set` returned normally, with no exception: the script would have
carried on to the next router believing the description was set. That is the default because
Netmiko cannot know what every platform's refusal looks like.

The second half passes `error_pattern`, a regular expression that marks a refusal. FRR begins every
refusal with `%` and a space, so the pattern is `% `, and the same lines now raise
`ConfigInvalidException`, naming the command and the match. **Every script that configures through a
CLI needs a check like this**, written for its platform; without it, the three failures of lesson 1
come back as one silent one.

Two more habits from lesson 1 apply here. Save explicitly, with `save_config()`, because a running
configuration disappears at the next reboot. And **read back what you changed**, because a line
that was accepted can still be the wrong line.
