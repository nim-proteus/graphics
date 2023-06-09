# graphics

A Nim-Proteus library.

## Graphics

The Graphics class provides functionality for working with a low level
rendering API such as OpenGL.

    - Window management
    - Resource management
      - Loading of resources such as Models
    - Instance management
    - Rendering

The sample below demonstrates loading and rendering a model.

```nim
import graphics
import graphics/renderer

var g = newGraphics(newOglRenderer())
g.openWindow(640, 480, "Sample")
g.getRenderer().setCameraEye(vec3f(0, 0, 100))

var path = "tests/res/models/duck.dae"
discard g.loadModel(path)
var mi = g.getModelInstance(path)

var tasks = newSeq[RenderTask]()
for mesh in mi.meshes:
    # Where do we store the translate and rotation and scale?
    tasks.add(RenderTask(mode: RenderMode.Projection, modelId: mi.id, meshId: mesh.meshId, matrix: translate(mat4f(), mesh.translation) * glm.mat4(mesh.rotation) * glm.scale(mat4f(), vec3f(0.1f, 0.1f, 0.1f))))

while g.isRunning():
    g.render(tasks)
```
