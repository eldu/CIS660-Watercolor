# CIS660-WatercolorMaya
## How to load plugin
### Vertex and Fragment Shaders
1. Set up Maya
* Go to Maya's preferences
* Click on Display
* Adjust the Viewport 2.0 rendering engine to "OpenGL-Core Profile"
2. Load the glslShader Plug-In
* Windows -> Settings/Preferences -> Plug-In Manager
* Click the checkmark next to glslShader.mll to load it. Optionally you can checkmark for it to be auto loaded when you open Maya the next time.
3. Assign a material to your object; you can load in your scene. 
* Right-click the object and hold -> Assign new material
* Add a GLSL Shader as the material tupe
4. Use the Attribute Editor to connect to .ogsfx file
* In the Shader File input, add the .ogsfx file.

### Post-processing Effects
1. Build Visual Studio Project Solution
2. Open the scene from this project folder by clicking on the file directly. This defines the "runtime" folder for Maya to pull shaders from. 
3. Load the viewRenderOverridePostColor Plug-In
* Windows -> Settings/Preferences -> Plug-In Manager
* Browse -> Find the "viewRenderOverridePostColor.mll" in ".\viewRenderOverridePostColor\x64\Debug" or Release
4. In the viewport's menu "Renderer" -> Enable Color Post. This option will only be seen after you load in the plug-in.

## References
Montesdeoca, S., Seah, H., Rall, H. and Benvenuti, D. 2017. Art-directed watercolor stylization of 3D animations in real-time. *Computers & Graphics* 65, 60-72.
