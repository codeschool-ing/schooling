---
title: When the lab does not come up
version: 1
---

`lab.sh` stops at the first command that fails (`set -euo pipefail`), so the last lines it printed name the step. These are the failures the script checks for, and the ones it cannot check for, in the order the build meets them.

**`python3 is required`, `npm is required`, `ip is required`, `openssl is required`.** The `need` step looks for the four programs before touching anything. On Ubuntu 24.04, `apt-get install python3 python3-venv nodejs npm iproute2 openssl` covers them; Node.js has to be version 22, which Ubuntu's own package is not, so install it from NodeSource or with `nvm`.

**`embeddings-vectors' lab is required beside this course`.** The lab reads `minilm.py`, `help.jsonl` and `books.jsonl` from `../embeddings-vectors/lab`. If the course directory was copied on its own, copy that one next to it; nothing of that lab has to be built or running.

**pip fails partway through the libraries.** Usually a network that cannot reach PyPI, or a Python other than 3.11 whose wheels for `onnxruntime` do not exist yet. The pins in `PYLIBS` are the versions every transcript was made with; changing one changes what the lessons print.

**`sha256sum: WARNING: 1 computed checksum did NOT match`.** The embedding model downloaded from Chroma's bucket is not the file the course was recorded with. Do not edit the checksum to make it pass: delete the half-downloaded copy and run `up` again, and if it still differs, the bucket now serves a different file and the lesson's search scores will not match.

**`tiktoken` raises `ValueError` about a hash during `build_tokenizer`.** The encoding was rebuilt from js-tiktoken and tiktoken refused it, which means the npm package changed. The script pins `js-tiktoken@1.0.21` for this reason.

**`labllm did not start; see /run/labllm.out`.** Read that file. `Address already in use` means something holds port 8600, often a labllm from an earlier build that was never stopped: `ss -ltnp | grep 8600` names the process, and `sudo bash lab.sh down` stops the lab's own.

**A program prints `[scripted-1 has no reply written for this conversation]`.** The lab works; the course has no rule for what was asked. labllm answers only the conversations the lessons script, so a question of your own reaches this reply. That is the honest limit of a stand-in, and `/var/log/labllm/requests.jsonl` shows exactly what it received.
