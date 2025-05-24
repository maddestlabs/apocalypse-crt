# Apocalypse CRT
Who knew classic CRT monitors would resurge as the prominent display for the apocalypse. This shader attempts to simulate those archaic but sturdy displays.

Example of shader in Windows Terminal playing MLMatrix:
[![Apocalypse CRT in Windows Terminal](https://img.youtube.com/vi/ajy2HMS3IYE/hqdefault.jpg 'Apocalypse CRT')](https://youtu.be/ajy2HMS3IYE)

## What it is?
It's a CRT shader. There are a lot of CRT shaders. This one most accurately simulates CRT displays from the future. It's also available across a bunch of tools like [Windows Terminal](https://github.com/microsoft/terminal
), Shadertoy and FL Studio's [ZGameEditor](https://www.image-line.com/fl-studio-learning/fl-studio-online-manual/html/plugins/ZGameEditor%20Visualizer.htm
).

The Shadertoy version lives [here](https://www.shadertoy.com/view/3cc3zN).

## Wait! The Shadertoy link isn't public? What's right with you?
Right. The Shadertoy code is listed as private mainly because it's designed for easy portability to tools like ZGameEditor and Windows Terminal, so variables such as ZGEborderSize would seem strange and even inefficient to typical Shadertoy users. So it's been listed as private to avoid any confusion there.

## Issues
- Mouse coordinates are slightly skewed in Windows Terminal based on frame/border size and curvature settings in the shader.

Please feel free to suggest fixes via pull requests.

## Credits
- Thanks to Shadertoy and shader coders for providing years of code for AI to learn from.
- Thanks to AI developers for using the amazing contributions of outstanding coders to provide powerful tools based on their extraordinary accomplishments, without which very much less would be possible.
- Thanks to Windows Terminal team for the bloom effect from retro.hlsl. It's been included with slight modifications for easy configuration.
- Thanks to [Lenzatic](https://pixabay.com/users/lenzatic-15400574/) for the ultimate [background](https://pixabay.com/photos/abandoned-explore-vacant-dark-4894406/) for a CRT shader from the apocalypse.
