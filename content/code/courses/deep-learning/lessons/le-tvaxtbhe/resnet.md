---
title: ResNet-18, stage by stage
version: 1
---

A diagram of ResNet in a paper is a column of a hundred boxes, and it reads as complicated. **The
network itself is four repeats of one idea**: a stage of residual blocks at one size, then the image
halves in height and width and the number of channels doubles, and the next stage starts. torchvision
builds the 18-layer version in one call. Save as `~/dl/resnet.py`:

```schooling-example
{
  "language": "python",
  "file": "resnet.py",
  "parts": [
    {
      "code": "\"\"\"resnet: torchvision's ResNet-18, built empty, and what each stage does to an image.\"\"\"\nimport torch\nfrom torchvision.models import resnet18\n\nmodel = resnet18(weights=None)\nmodel.eval()\nprint(\"parameters:\", sum(p.numel() for p in model.parameters()))",
      "note": "The architecture with random weights. `weights=None` is the only way it is built in this course, because the machine this course was recorded on could not download the trained ones, and the shapes and the count do not depend on them."
    },
    {
      "code": "x = torch.randn(1, 3, 224, 224)\nwith torch.no_grad():\n    x = model.maxpool(model.relu(model.bn1(model.conv1(x))))\n    print(\"stem    \", tuple(x.shape))",
      "note": "One random image at ImageNet's size, three colour channels of 224 by 224. The stem is a 7x7 convolution with stride 2 and a max pooling, the four lines `forward` runs first."
    },
    {
      "code": "    for name in (\"layer1\", \"layer2\", \"layer3\", \"layer4\"):\n        stage = getattr(model, name)\n        x = stage(x)\n        n = sum(p.numel() for p in stage.parameters())\n        print(f\"{name:8s} {tuple(x.shape)}  {len(stage)} blocks, {n:,d} parameters\")\n    print(\"head    \", tuple(model.fc(model.avgpool(x).flatten(1)).shape))",
      "note": "torchvision calls the four stages `layer1` to `layer4`. Each is a `Sequential` of blocks, so it can be called on its own and measured on its own."
    },
    {
      "code": "print(model.layer2[0])",
      "note": "The first block of the second stage, where the image shrinks and the channels double."
    }
  ]
}
```

```
ana@vm:~/dl$ python resnet.py
parameters: 11689512
stem     (1, 64, 56, 56)
layer1   (1, 64, 56, 56)  2 blocks, 147,968 parameters
layer2   (1, 128, 28, 28)  2 blocks, 525,568 parameters
layer3   (1, 256, 14, 14)  2 blocks, 2,099,712 parameters
layer4   (1, 512, 7, 7)  2 blocks, 8,393,728 parameters
head     (1, 1000)
BasicBlock(
  (conv1): Conv2d(64, 128, kernel_size=(3, 3), stride=(2, 2), padding=(1, 1), bias=False)
  (bn1): BatchNorm2d(128, eps=1e-05, momentum=0.1, affine=True, bias=True, track_running_stats=True)
  (relu): ReLU(inplace=True)
  (conv2): Conv2d(128, 128, kernel_size=(3, 3), stride=(1, 1), padding=(1, 1), bias=False)
  (bn2): BatchNorm2d(128, eps=1e-05, momentum=0.1, affine=True, bias=True, track_running_stats=True)
  (downsample): Sequential(
    (0): Conv2d(64, 128, kernel_size=(1, 1), stride=(2, 2), bias=False)
    (1): BatchNorm2d(128, eps=1e-05, momentum=0.1, affine=True, bias=True, track_running_stats=True)
  )
)
```

**Follow the shape down the column.** The stem takes the 224 by 224 image to 56 by 56 at once, with
its stride and its pooling, and lays 64 channels over it. Each of the next three stages halves the
side and doubles the channels, to 128, 256 and 512, and the last maps are 7 by 7. The head averages
each map into one number and a linear layer turns the 512 numbers into 1,000 class scores, the
ImageNet classes.

**The parameters are not spread evenly.** `layer4` alone holds 8,393,728 of the 11,689,512, because
the cost of a 3x3 convolution grows with the channels in times the channels out, and those are
largest at the end. The image is smallest there, so the work per image is spread much more evenly
than the weights. This is the reverse of VGG, where the dense head was the expensive part.

The printed block answers the question the residual section left open: how can `x + f(x)` work when
`f` halves the image and doubles the channels, so the two no longer have the same shape?

- **`conv1` has `stride=(2, 2)`**, which is where the halving happens, inside the block's own path.
- **`downsample` is a 1x1 convolution with stride 2** on the skip, which brings `x` to the same 128
  channels and the same size. It is the only place the skip learns anything, and it appears only in
  the first block of a stage.
- **Each convolution is followed by `BatchNorm2d`** (lesson 8), and the convolutions have
  `bias=False`, because the normalisation subtracts the mean and a bias would be cancelled.

ResNet-18, 34, 50, 101 and 152 differ in the number of blocks per stage, and from 50 up in the block:
a 1x1 convolution narrows the channels, the 3x3 works on the narrow version, and another 1x1 widens
them back. The paper called it a bottleneck: the expensive 3x3 sees fewer channels, so the network
can have three layers in a block where ResNet-18 has two.

All of this was built with random weights. **The trained ones are a download that the recording
machine could not make**, so nothing here was tested on a real photograph; lesson 13 shows how those
weights are asked for and what they bring.
