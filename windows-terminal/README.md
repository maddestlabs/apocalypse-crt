# Apocalypse CRT for Windows Terminal
This is the Windows Terminal version of the shader.

# Installation
- Download apocalypse-crt.hlsl and place it somewhere accessible.
- Open Windows Terminal and press <kbd>CTRL</kbd> + <kbd>,</kbd> to open Settings.
- At bottom left of Settings page, click the config icon to open settings.json.
- Edit settings.json, adding the shader path under Profiles -> defaults.
```"experimental.pixelShaderPath": "C:\\your-path\\apocalypse-crt.hlsl"```
- Optionally, add a shader image for the background.
```"experimental.pixelShaderImagePath": "C:\\your-path\\img\\apocalypse-crt.png"```
- Save your changes and the terminal should automatically update.
