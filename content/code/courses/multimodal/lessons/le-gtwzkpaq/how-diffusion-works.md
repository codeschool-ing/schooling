---
title: How a diffusion model makes a picture
version: 1
---

**A diffusion model does not paint. It removes noise.** That is the idea every image generator of the last few years is built on, and it explains most of how they behave: why a prompt is a suggestion, why two runs differ, and why some things come out wrong every time.

Training starts from real pictures and destroys them. Take a picture, add a little random noise, then a little more, a thousand times, until nothing of the picture is left. The amount added at each step follows a fixed **schedule**. Here is that process run on the lab's cover of *Dom Casmurro*, with the linear schedule of the original diffusion papers, and Tesseract trying to read the title at each stage:

```python
"""What a diffusion model learns to undo: the cover, drowned in noise step by step."""
import subprocess

import numpy as np
from PIL import Image

T = 1000
betas = np.linspace(1e-4, 0.02, T)          # the linear schedule of the first diffusion papers
kept = np.cumprod(1 - betas)                 # how much of the picture survives after t steps

cover = np.asarray(Image.open("media/cover-b39.png").convert("L"), dtype=np.float32) / 127.5 - 1
noise = np.random.default_rng(39).standard_normal(cover.shape)
for t in (0, 50, 100, 200, 400, 999):
    a = kept[t]
    x = np.sqrt(a) * cover + np.sqrt(1 - a) * noise
    Image.fromarray(((x.clip(-1, 1) + 1) * 127.5).astype(np.uint8)).save(f"/tmp/noisy-{t}.png")
    words = subprocess.run(["tesseract", f"/tmp/noisy-{t}.png", "-", "--psm", "6"],
                           capture_output=True, text=True).stdout.split()
    title = "DOM CASMURRO" in " ".join(words)
    print(f"step {t:4}  picture {np.sqrt(a):5.1%}  noise {np.sqrt(1 - a):5.1%}  "
          f"Tesseract reads the title: {'yes' if title else 'no'}")
```

```
ana@lab:~/mm$ python noise.py
step    0  picture 100.0%  noise  1.0%  Tesseract reads the title: yes
step   50  picture 98.5%  noise 17.3%  Tesseract reads the title: yes
step  100  picture 94.6%  noise 32.4%  Tesseract reads the title: yes
step  200  picture 81.0%  noise 58.6%  Tesseract reads the title: no
step  400  picture 44.0%  noise 89.8%  Tesseract reads the title: no
step  999  picture  0.6%  noise 100.0%  Tesseract reads the title: no
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Two curves over 1000 diffusion steps. The share of the picture left starts at 100% and falls, slowly at first: 98.5% at step 50, 94.6% at 100, 81.0% at 200, 44.0% at 400 and 0.6% at the end. The share of noise rises the opposite way. A dashed line between step 100 and step 200 marks where Tesseract stopped being able to read the title on the noisy cover.\"><line x1=\"70\" y1=\"210\" x2=\"680\" y2=\"210\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"70\" y1=\"210\" x2=\"70\" y2=\"30\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"62\" y=\"210.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0%</text><text x=\"62\" y=\"120.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">50%</text><text x=\"62\" y=\"30.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100%</text><text x=\"70.0\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><text x=\"222.5\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">250</text><text x=\"375.0\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">500</text><text x=\"527.5\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">750</text><text x=\"680.0\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1000</text><text x=\"375.0\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">step</text><path d=\"M70.0 30.0 L76.1 30.2 L82.2 30.6 L88.3 31.1 L94.4 31.8 L100.5 32.7 L106.6 33.8 L112.7 35.0 L118.8 36.4 L125.0 38.0 L131.1 39.7 L137.2 41.6 L143.3 43.6 L149.4 45.7 L155.5 48.0 L161.6 50.4 L167.7 53.0 L173.8 55.6 L179.9 58.4 L186.0 61.2 L192.1 64.2 L198.2 67.2 L204.3 70.3 L210.4 73.5 L216.5 76.7 L222.7 80.0 L228.8 83.4 L234.9 86.7 L241.0 90.1 L247.1 93.6 L253.2 97.0 L259.3 100.5 L265.4 103.9 L271.5 107.4 L277.6 110.8 L283.7 114.2 L289.8 117.6 L295.9 121.0 L302.0 124.3 L308.1 127.6 L314.2 130.8 L320.4 134.0 L326.5 137.1 L332.6 140.2 L338.7 143.2 L344.8 146.1 L350.9 149.0 L357.0 151.8 L363.1 154.6 L369.2 157.2 L375.3 159.8 L381.4 162.3 L387.5 164.7 L393.6 167.1 L399.7 169.3 L405.8 171.5 L411.9 173.6 L418.0 175.6 L424.2 177.6 L430.3 179.4 L436.4 181.2 L442.5 182.9 L448.6 184.6 L454.7 186.1 L460.8 187.6 L466.9 189.0 L473.0 190.4 L479.1 191.6 L485.2 192.8 L491.3 194.0 L497.4 195.1 L503.5 196.1 L509.6 197.1 L515.7 198.0 L521.9 198.9 L528.0 199.7 L534.1 200.4 L540.2 201.1 L546.3 201.8 L552.4 202.4 L558.5 203.0 L564.6 203.6 L570.7 204.1 L576.8 204.5 L582.9 205.0 L589.0 205.4 L595.1 205.8 L601.2 206.1 L607.3 206.5 L613.4 206.8 L619.5 207.0 L625.7 207.3 L631.8 207.5 L637.9 207.8 L644.0 208.0 L650.1 208.1 L656.2 208.3 L662.3 208.5 L668.4 208.6 L674.5 208.7\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></path><path d=\"M70.0 208.2 L76.1 201.6 L82.2 195.8 L88.3 190.0 L94.4 184.4 L100.5 178.8 L106.6 173.3 L112.7 167.8 L118.8 162.3 L125.0 157.0 L131.1 151.7 L137.2 146.5 L143.3 141.4 L149.4 136.4 L155.5 131.5 L161.6 126.7 L167.7 122.0 L173.8 117.5 L179.9 113.0 L186.0 108.7 L192.1 104.5 L198.2 100.4 L204.3 96.5 L210.4 92.7 L216.5 89.0 L222.7 85.5 L228.8 82.1 L234.9 78.8 L241.0 75.7 L247.1 72.7 L253.2 69.9 L259.3 67.2 L265.4 64.6 L271.5 62.1 L277.6 59.8 L283.7 57.6 L289.8 55.5 L295.9 53.6 L302.0 51.7 L308.1 50.0 L314.2 48.4 L320.4 46.8 L326.5 45.4 L332.6 44.1 L338.7 42.9 L344.8 41.7 L350.9 40.6 L357.0 39.7 L363.1 38.8 L369.2 37.9 L375.3 37.1 L381.4 36.4 L387.5 35.8 L393.6 35.2 L399.7 34.7 L405.8 34.2 L411.9 33.7 L418.0 33.3 L424.2 32.9 L430.3 32.6 L436.4 32.3 L442.5 32.0 L448.6 31.8 L454.7 31.6 L460.8 31.4 L466.9 31.2 L473.0 31.1 L479.1 30.9 L485.2 30.8 L491.3 30.7 L497.4 30.6 L503.5 30.5 L509.6 30.5 L515.7 30.4 L521.9 30.3 L528.0 30.3 L534.1 30.3 L540.2 30.2 L546.3 30.2 L552.4 30.2 L558.5 30.1 L564.6 30.1 L570.7 30.1 L576.8 30.1 L582.9 30.1 L589.0 30.1 L595.1 30.0 L601.2 30.0 L607.3 30.0 L613.4 30.0 L619.5 30.0 L625.7 30.0 L631.8 30.0 L637.9 30.0 L644.0 30.0 L650.1 30.0 L656.2 30.0 L662.3 30.0 L668.4 30.0 L674.5 30.0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2\"></path><line x1=\"161.5\" y1=\"30\" x2=\"161.5\" y2=\"210\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></line><text x=\"167.5\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">title no longer readable</text><text x=\"470\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">noise</text><text x=\"470\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">picture left</text></svg>", "caption": "Generating runs this backwards: from pure noise at the right to a picture at the left, one small denoising step at a time."}
```

The model is trained on the reverse: shown a noisy picture and told how noisy it is, it learns to predict the noise, so that subtracting its prediction gives a slightly cleaner picture. Repeated enough times, that turns pure noise into a picture. Nothing in the process copies a stored image; the model has learned what pictures *tend to look like* at every level of noise.

**The words come in as a nudge at every step.** A text encoder turns the prompt into vectors, and each denoising step is computed twice: once with the prompt and once without. The difference is scaled up by a setting called **guidance** and added on. Higher guidance follows the prompt more literally and gives less varied, often harsher pictures; lower guidance gives freer pictures that drift from the words. The prompt steers the denoising; it does not dictate the result.

## Three consequences you will meet

**The same prompt gives a different picture each time**, because each run starts from different noise. Local models expose that starting noise as a **seed**: same seed, same settings, same picture. OpenAI's Images API exposes no seed, so there the only way to see the spread of a prompt is to ask for several pictures (`n`) and look at all of them. Section 04 does exactly that.

**What was rare in training comes out badly.** The model learned from what pictures usually look like. Readable text on a sign, the right number of fingers, five apples rather than "some apples": each requires precision that a model averaging over millions of pictures does not have. Newer models are much better at text, and the limits section returns to it.

**The picture is fixed at a size.** A model generates at the resolutions it was trained for. Asking for another size means a different shape of noise to start from, which can change the composition, and an API offers a short list of sizes for that reason (lesson 9).

*The noise in `noise.py` is real arithmetic, and the generating is not run anywhere in this course: Ollama's image models run only on macOS so far, and the course's machine is Linux. Generating runs the curve from right to left, from pure noise back to a picture.*
