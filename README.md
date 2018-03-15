# CIS660-WatercolorMaya
## How to load plugin
1. Go to Maya's preferences
* Click on Display
* Adjust the Viewport 2.0 rendering engine to "OpenGL-Core Profile"
2. Load the glslShader plugin
* Windows -> Settings/Preferences -> Plug-In Manager
* Click the checkmark next to glslShader.mll to load it. Optionally you can checkmark for it to be auto loaded when you open Maya the next time.
3. Assign a material to your object; you can load in your scene. 
* Right-click the object and hold -> Assign new material
* Add a GLSL Shader as the material tupe
4. Use the Attribute Editor to connect to .ogsfx file
* In the Shader File input, add the .ogsfx file.
