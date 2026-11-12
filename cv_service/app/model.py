"""The network and its preprocessing. Shared by training/ and the service so both see identical inputs."""

from __future__ import annotations

import torch
from torch import nn
from torchvision import models
from torchvision.transforms import v2

ARCH = "mobilenet_v3_large"
INPUT_SIZE = 224
RESIZE = 256
# ImageNet statistics, as the pretrained torchvision weights expect.
MEAN = (0.485, 0.456, 0.406)
STD = (0.229, 0.224, 0.225)


def build_model(num_classes: int, *, pretrained: bool) -> nn.Module:
    """MobileNetV3-Large; `pretrained` loads torchvision's ImageNet-1k V2 weights (training only)."""
    weights = models.MobileNet_V3_Large_Weights.IMAGENET1K_V2 if pretrained else None
    model = models.mobilenet_v3_large(weights=weights)
    head = model.classifier[3]
    assert isinstance(head, nn.Linear)
    model.classifier[3] = nn.Linear(head.in_features, num_classes)
    return model


def eval_transform() -> v2.Compose:
    return v2.Compose(
        [
            v2.ToImage(),
            v2.Resize(RESIZE, antialias=True),
            v2.CenterCrop(INPUT_SIZE),
            v2.ToDtype(torch.float32, scale=True),
            v2.Normalize(MEAN, STD),
        ]
    )


def train_transform() -> v2.Compose:
    return v2.Compose(
        [
            v2.ToImage(),
            v2.RandomResizedCrop(INPUT_SIZE, scale=(0.5, 1.0), antialias=True),
            v2.RandomHorizontalFlip(),
            v2.ColorJitter(brightness=0.3, contrast=0.3, saturation=0.2, hue=0.02),
            v2.ToDtype(torch.float32, scale=True),
            v2.Normalize(MEAN, STD),
        ]
    )
