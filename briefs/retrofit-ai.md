Addendum to `briefs/retrofit.md` for the courses that need a language model. Read the main brief first; everything in it applies.

## Check the network before anything else

The recommended path is a local model run with **Ollama** (C-40). Before you read or change anything, check that this session can reach it:

```sh
curl -sSI https://ollama.com/ | head -1
curl -sSI https://registry.ollama.ai/v2/ | head -1
```

If either is refused by the proxy (a 403 on CONNECT; see `/root/.ccr/README.md` and `$HTTPS_PROXY/__agentproxy/status`), STOP. Tell the owner, in Portuguese, which host was refused, and change nothing. Without Ollama, the captures of a model's answers cannot be real, and inventing them is the one thing this repository forbids.

After installing Ollama, the first `ollama pull` may be redirected to a storage host. If that host is refused, report its exact name the same way.

## The model

- **The recommended model is `llama3.2:3b`**, the same in every AI course, so a student who set it up once has it for all of them.
- The setup lesson says what it needs: read the download size and the memory use from your own capture, never from memory. It also names a smaller model for a weaker computer, and the student's own paid API key as the other path. Never depend on one company's free tier.
- If `llama3.2:3b` cannot do what a lesson needs, choose another model only for that lesson, say why in the prose, and tell the owner in the PR.
- A capture of a model's answer names the model, its tag and the date it was taken, in the capture script's header.
- **Sampling is not deterministic:** set the temperature and seed where the lesson's point allows, and say in the prose that the student's answer will differ in wording.

## The stand-ins

Several courses answer with a stand-in written by the course (`toylm`, `labgen`, `labllm.py`, `scripted`) instead of a model. Where the lesson is about a model's behaviour, replace the stand-in with the local model and recapture. Where the stand-in exists to make a mechanism visible (a tokenizer, a sampler, a fake tool server), keep it, show it whole in a lesson, and call it what it is.

## Every course stands on its own

`prompt-engineering` is the first AI course in the `ai`, `prompt` and `security` tracks. But `ai-dev` reaches many tracks with no AI course before it, and every course sits in more than one track. So each course carries the short version of the Ollama setup, or names the course and lesson that teaches it, if that course is in its `requires`.
