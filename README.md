# LensDistortion
Example for applying a lens distortion shader in Godot for Mobile VR

You can copy the files in Cameras into your own project to use the setup. This handles rendering two cameras to the correct viewports and handles preparing a distortion map to apply the lens effect.

The objects displayed in this demo scene are too close and you're eyes will probably hurt if you put this on.

I'm still working on a settings window that allows you to enter the variables that control how things are rendered. I'll see if I can put a list together of common phones and headset. The information is readily available but a bit of a pain. The current settings in the project are for an iPhone 7, if you've got a cardboard type viewer the lens constants are probably too high. 

Note that for this to work you need the frustum mode enhancement to Godot:
- Godot 2.x: https://github.com/godotengine/godot/pull/7778
- Godot 3.x: https://github.com/godotengine/godot/pull/7121

I'm also planning on doing a video soon on this to explain some more details.
