---
title: The machine you will type on
version: 1
---

Nothing in this course runs on a machine we host. **You build a Linux machine with Python and
PyTorch on it, and from this section on every command is typed there.** Every transcript in the
course was recorded on one: Ubuntu 24.04, four processors, no graphics card, a user called `ana`
and a machine called `vm`. Your prompt will carry your own names.

**No graphics card is a choice, not an apology.** Deep learning is known for eating GPU hours, and
lessons 10 and 19 are about exactly that cost. But every network in this course is small enough to
train on a laptop's processor in seconds or minutes, because the ideas do not get clearer at a
larger size: a learning rate that is too high diverges on 1,797 images exactly as it does on a
million. Where a lesson says something only a graphics card can show, it says so and says it was
not run.

## What runs on it

| | what it is | why this one |
| --- | --- | --- |
| **Python 3.12** | the language of every program, in a virtual environment of its own | Ubuntu 24.04 ships it |
| **NumPy** | arrays and the arithmetic on them | lessons 1 to 8 build a network with nothing else, so nothing is hidden |
| **scikit-learn** | the library `machine-learning` used | it ships the handwritten digits this course trains on, inside the package, with no download |
| **PyTorch** | the framework from lesson 9 on: tensors, automatic gradients, layers | the one most research and most jobs use; the ideas carry to the others |
| **torchvision** | PyTorch's image library | the classic architectures of lesson 12 and the augmentations of lesson 13 |
| **tokenizers** | Hugging Face's tokenizer library | lesson 16 trains a tokenizer of its own with it |

## Three ways to have the machine

| | what it is | what it costs your computer |
| --- | --- | --- |
| **a virtual machine** (recommended) | Ubuntu Server 24.04 LTS in a VM made with Multipass, and everything installed inside it | 4 processors, 8 GB of memory and 30 GB of disk while it runs; on your own system, only the hypervisor |
| installed | the same commands on a computer that already runs Ubuntu 24.04; or Python 3.12 from python.org on Windows or macOS, with the same `pip` line | about 6 GB of disk for the libraries, and nothing else |
| online | a virtual machine rented from a cloud provider, a GitHub Codespace, or a notebook service with a graphics card | nothing on your computer; an hourly price, or an allowance the company offering it decides |

**The virtual machine is the same shape as the machine the transcripts came from**, so when your
numbers differ from the lesson's, the difference is in the arithmetic of your processor and not in
the setup. It is also disposable: an environment broken by an experiment costs nothing the
commands below cannot put back.

**Installed is the path for a computer with an NVIDIA graphics card**, because a VM does not see
the card. On Linux, the `torch` that `pip` installs carries its own CUDA libraries and needs only
NVIDIA's driver; `torch.cuda.is_available()` then answers `True`. On macOS with Apple silicon,
the same package uses the chip's own graphics through a backend called `mps`. On Windows, the
package `pip` installs by default uses the processor only, and PyTorch's site gives the command for
a CUDA build. None of this was run for this course, because its machine has no card.

**Online is named so that you know it exists, not recommended.** A notebook service that lends a
graphics card for free is a decision a company makes and can change, and its notebooks lose their
files when the session ends. No lesson here depends on one, and none needs a card.

## The virtual machine

Install Multipass from Canonical's site. It drives a hypervisor the system already has: Hyper-V on
Windows, or VirtualBox on editions without Hyper-V; QEMU over Apple's own hypervisor on macOS; and
QEMU with KVM on Linux. Then, in your computer's own terminal:

```sh
multipass launch 24.04 --name vm --cpus 4 --memory 8G --disk 30G
multipass shell vm
```

**These two commands were not run for this course**, because the machine it was recorded on is
itself a virtual machine and cannot start another. The first creates the VM and the second opens a
shell inside it. Everything after this point happens in that shell. Any other hypervisor works in
place of Multipass, VirtualBox, UTM on an Apple-silicon Mac, Hyper-V or GNOME Boxes, with an Ubuntu
Server 24.04 LTS installer and the same sizes. It costs half an hour of installer screens instead
of one command.

## The working directory

Everything the course writes lives in `~/dl`, with a Python of its own:

```sh
sudo apt-get update
sudo apt-get install -y python3-venv
mkdir ~/dl && cd ~/dl
python3 -m venv .venv
```

Ubuntu leaves out the part of Python that builds virtual environments, which is what the second
line puts back. Save the next block as `~/dl/requirements.txt`. It names every library a lesson
imports, at the version the transcripts were recorded with:

```
# requirements.txt: the libraries this course imports, at the versions it was recorded with
numpy==2.5.3
scikit-learn==1.9.1
torch==2.14.1
torchvision==0.29.1
tokenizers==0.23.3
```

Then activate the environment, install, and make every new terminal activate it too:

```sh
. .venv/bin/activate
pip install -r requirements.txt
echo 'export VIRTUAL_ENV_DISABLE_PROMPT=1' >> ~/.bashrc
echo '. ~/dl/.venv/bin/activate' >> ~/.bashrc
```

The installation downloads several gigabytes and takes several minutes. The first `echo` keeps the
prompt short: an active environment normally puts `(.venv)` in front of it, and the transcripts in
this course do not show it. `which python` is the honest way to ask which Python you are in, and
the checks below use it.

## Checking it works

Four checks: the Python, which Python it is, PyTorch and whether it sees a graphics card, and what
the environment cost in disk.

```
ana@vm:~/dl$ python --version
Python 3.12.3
ana@vm:~/dl$ which python
/home/ana/dl/.venv/bin/python
ana@vm:~/dl$ python -c "import torch; print(torch.__version__, torch.cuda.is_available())"
2.14.1+cu130 False
ana@vm:~/dl$ du -sh .venv
5.7G	.venv
```

`2.14.1+cu130` is PyTorch built against CUDA 13.0, the build `pip` installs on Linux. `False` says
it found no card to use it on, which is right for this machine and for your VM. Most of the 5.7 GB
is code for NVIDIA cards, carried whether there is a card or not.

**That size is the price of the default, and there is a smaller build.** PyTorch publishes a build
for processors only, without NVIDIA's libraries, from its own package index:
`pip install torch==2.14.1 torchvision==0.29.1 --index-url https://download.pytorch.org/whl/cpu`,
before the `requirements.txt` line. It was not run for this course, because the machine the
transcripts came from could not reach that index; every number here comes from the default build.
On a VM with no card, the two compute the same results.
