# Third-party notices

This repository and its release archives contain only the installer script and the Vivid preset.
The components below are **not redistributed**. The installer downloads them from their official sources at
install time, pinned to the exact versions listed here and verified with SHA-256. Each one remains under its
author's license.

| Component | Author | Source | License |
|---|---|---|---|
| ReShade 6.8.0 (`ReShade64.dll`, extracted from `ReShade_Setup_6.8.0.exe`) | Patrick Mours (crosire) | https://reshade.me | BSD 3-Clause (below) |
| `ReShade.fxh` | crosire and contributors | https://github.com/crosire/reshade-shaders (`fd0022170615ce0d8162d219bff07232fa6dd84f`) | CC0-1.0 (SPDX header in file) |
| `CAS.fx` (SweetFX) | Advanced Micro Devices; port by CeeJay.dk | https://github.com/CeeJayDK/SweetFX (`93ddf39b357f5da534ed6d34ba4ec8cc7dcfa361`) | MIT (notice in file) |
| `qUINT_lightroom.fx`, `qUINT_common.fxh` | Pascal Gilcher (Marty McFly) | https://github.com/martymcmodding/qUINT (`98fed77b26669202027f575a6d8f590426c21ebd`) | Copyright the author; see file header and repository |
| `Clarity.fx` | Ioxa; maintained by BlueSkyDefender | https://github.com/BlueSkyDefender/AstrayFX (`59bae8b33e34f37a8e521e666864085ccbf08535`) | Copyright the authors; see file header and repository |
| `ReShadeUI.fxh` | crosire and contributors | https://github.com/crosire/reshade-shaders (`fd0022170615ce0d8162d219bff07232fa6dd84f`) | See repository |
| `Deband.fx` | Niklas Haas; ReShade port in crosire/reshade-shaders | https://github.com/crosire/reshade-shaders (`fd0022170615ce0d8162d219bff07232fa6dd84f`) | MIT (notice in file) |
| `HQAALite.fx` | lordbean; includes NVIDIA FXAA, AMD and SMAA code | https://github.com/lordbean-git/HQAA (`d12e74843399f5b85b4c28f8cd858022dfbcd165`) | Third-party parts under MIT-style notices in the file; see repository for the rest |
| `AreaTex.png`, `SearchTex.png` | Jorge Jimenez et al. (SMAA) | https://github.com/lordbean-git/HQAA (`d12e74843399f5b85b4c28f8cd858022dfbcd165`) | SMAA license (MIT) |

The presets (`VividDeep.ini`, `Vivid.ini`) only contain parameter values for these effects and are part of this project (MIT).

## ReShade license

```
Copyright 2014 Patrick Mours. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that
the following conditions are met:

  * Redistributions of source code must retain the above copyright notice, this list of conditions and the
    following disclaimer.
  * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the
    following disclaimer in the documentation and/or other materials provided with the distribution.
  * Neither the name of the copyright holder nor the names of its contributors may be used to endorse or
    promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
DAMAGE.
```

## Trademarks

Destiny Rising is a trademark of its respective owners. MuMuPlayer is a product of NetEase. This project is not
affiliated with or endorsed by NetEase, Bungie, MuMuPlayer or the ReShade project. The screenshots in `docs/`
are captured from the game for illustration only.
