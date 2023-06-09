import glm
import std/tables

type 
    ResourceId* = uint
    TextureId* = ResourceId
    ModelId* = ResourceId
    MeshId* = ResourceId
    ModelInstanceId* = ResourceId
    ShaderId* = ResourceId
    ShaderProgramId* = ResourceId

    Vertex* = Vec3f
    TexCoord* = Vec3f   
    Normal* = Vec3f
    Rotation* = Quatf
    Color* = tuple[r, g, b, a: float32]

    RenderMode* = enum
        Orth, Projection

    Graphics* = ref object of RootObj
        modelNameMap: TableRef[string, ModelId]
        renderer: Renderer

    Renderer* = ref object of RootObj
        cameraEye: Vec3f
        cameraLookAt: Vec3f

    RenderTask* = ref object of RootObj
        mode*: RenderMode
        modelId*: ModelInstanceId
        meshId*: MeshId
        matrix*: Mat4f

    Shader* = ref object of RootObj
        id*: ShaderId
        shaderText*: string
        shaderType*: ShaderType

    Texture* = ref object of RootObj
        id*: TextureId

    ShaderProgram* = ref object of RootObj
        id*: ShaderProgramId

    ShaderType* = enum
        VertexShader, GeometryShader, FragmentShader

    ModelInstance* = ref object of RootObj
        id*: ModelInstanceId
        modelId*: ModelId
        meshes*: seq[MeshInstance]

    MeshInstance* = ref object of RootObj
        meshId*: MeshId
        translation*: Vertex
        rotation*: Rotation


method loadShader*(this: Renderer, shaderType: ShaderType, shaderText: string): Shader {.base.} = discard
method loadTexture*(this: Renderer, path: string): Texture {.base.} = discard
method loadModel*(this: Renderer, path: string): ModelId {.base.} = discard
method render*(this: Renderer, tasks: seq[RenderTask]) {.base.} = discard
method getModelInstance*(this: Renderer, path: string): ModelInstance {.base.} = discard
method openWindow*(this: Renderer, width: int32, height: int32, title: string) {.base.} = discard
method isWindowOpen*(this: Renderer): bool {.base.} = discard
method endFrame*(this: Renderer) {.base.} = discard


proc render*(this: Graphics, tasks: seq[RenderTask]) =
    this.renderer.render(tasks)
    this.renderer.endFrame()


proc loadModel*(this: Graphics, filePath: string): ModelId = 
    if this.modelNameMap.hasKey(filePath):
        return this.modelNameMap[filePath]

    this.modelNameMap[filePath] = this.renderer.loadModel(filePath)
    result = this.modelNameMap[filePath]


proc getModelInstance*(this: Graphics, filePath: string): ModelInstance =
    this.renderer.getModelInstance(filePath)


proc setRenderer*(this: Graphics, renderer: Renderer) =
    this.renderer = renderer

proc getRenderer*(this: Graphics): Renderer =
    this.renderer


proc openWindow*(this: Graphics, width: int32, height: int32, title: string) =
    this.renderer.openWindow(width, height, title)


proc isRunning*(this: Graphics): bool =
    this.renderer.isWindowOpen()


proc newGraphics*(renderer: Renderer): Graphics =
    result = new(Graphics)
    result.modelNameMap = newTable[string, ModelId]()
    result.renderer = renderer

proc getCameraEye*(this: Renderer): Vec3f = this.cameraEye

proc setCameraEye*(this: Renderer, cameraEye: Vec3f) = this.cameraEye = cameraEye

proc getCameraLookAt*(this: Renderer): Vec3f = this.cameraLookAt

proc setCameraLookAt*(this: Renderer, cameraLookAt: Vec3f) = this.cameraLookAt = cameraLookAt