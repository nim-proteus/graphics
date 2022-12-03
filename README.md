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

var path = "some/path/to/model.xyz"
discard g.loadModel(path)
var mi = g.getModelInstance(path)

var tasks = newSeq[RenderTask]()
for mesh in mi.meshes:
    tasks.add(RenderTask(renderMode: RenderMode.Projection, modelId: mi.id, meshId: mesh.id))

g.render(tasks)
```
