import opengl
import std/logging
import std/tables
import glm
import glfw
import model
import modelloader
import ../graphics

# import std/algorithm  # Required for sorting...

type
    OglRenderer* = ref object of Renderer
        window*: GLFWWindow
        defaultShaderProgram: ShaderProgramId
        loader: ModelLoader

        models: TableRef[ModelId, BufferedModel]
        shaderPrograms: TableRef[ShaderProgramId, OglProgram]

    OglShader* = ref object of Shader
        glShaderId*: GLuint

    OglTexture* = ref object of Texture
        glTextureId*: GLuint
     
    OglProgram* = ref object of ShaderProgram
        glProgramId*: GLuint

    BufferedModel = ref object of RootObj
        id*: ModelId
        filePath*: string
        meshes*: seq[BufferedMesh]

    BufferedMesh = ref object of RootObj
        id*: MeshId
        vaoId*: GLuint
        indices*: seq[int32]


const ShaderNameMap* = [
    ShaderType.VertexShader: "Vertex",
    ShaderType.GeometryShader: "Geometry",
    ShaderType.FragmentShader: "Fragment"
]


const TextureTypeMap = [
    ShaderType.VertexShader: GL_VERTEX_SHADER,
    ShaderType.GeometryShader: GL_GEOMETRY_SHADER,
    ShaderType.FragmentShader: GL_FRAGMENT_SHADER
]


proc loadShaderOgl(shaderType: ShaderType, shaderText: string): OglShader
proc newProgramFromSource*(vertexShader: string, fragmentShader: string): OglProgram


proc delete*(this: OglShader) = 
    glDeleteShader(this.glShaderId)
    this.glShaderId = 0


proc use*(this: OglProgram) =
    glUseProgram(this.glProgramId)


proc loadShader*(this: OglRenderer, shaderType: ShaderType, shaderText: string): Shader =
    loadShaderOgl(shaderType, shaderText)


method loadTexture*(this: OglRenderer, path: string): Texture = 
    discard


method loadModel*(this: OglRenderer, path: string): ModelId = 
    var model = this.loader.loadModel(path)
    var bufferedModel = new(BufferedModel)
    bufferedModel.meshes = newSeq[BufferedMesh]()
    for m in model.meshes:
        var buffer: GLuint
        var b = new(BufferedMesh)
        if m.vertices.len > 0:
            glGenBuffers(1, buffer.addr)
            glBindBuffer(GL_ARRAY_BUFFER, buffer)
            glBufferData(GL_ARRAY_BUFFER, m.vertices.len * sizeof(Vertex), m.vertices[0].addr, GL_STATIC_DRAW)

        if m.texCoords.len > 0:
            glGenBuffers(1, buffer.addr)
            glBindBuffer(GL_ARRAY_BUFFER, buffer)
            glBufferData(GL_ARRAY_BUFFER, m.vertices.len * sizeof(TexCoord), m.texCoords[0].addr, GL_STATIC_DRAW)

        if m.normals.len > 0:
            glGenBuffers(1, buffer.addr)
            glBindBuffer(GL_ARRAY_BUFFER, buffer)
            glBufferData(GL_ARRAY_BUFFER, m.vertices.len * sizeof(Normal), m.normals[0].addr, GL_STATIC_DRAW)

        if m.colors.len > 0:
            glGenBuffers(1, buffer.addr)
            glBindBuffer(GL_ARRAY_BUFFER, buffer)
            glBufferData(GL_ARRAY_BUFFER, m.vertices.len * sizeof(Color), m.colors[0].addr, GL_STATIC_DRAW)

        if m.indices.len > 0:
            b.indices = m.indices

        b.id = bufferedModel.meshes.len.MeshId
        bufferedModel.meshes.add(b)
    bufferedModel.id = len(this.models).ModelId
    this.models[bufferedModel.id] = bufferedModel
    result = bufferedModel.id


method render*(this: OglRenderer, tasks: seq[RenderTask]) =
    # Sort by z to render further items first
    # proc sortTasks(x, y: RenderTask): int = 
    #     let r = cmp(x.mode, y.mode)
    #     if r == 0:
    #         result = r
    #         return
    #     result = cmp(x.depthHint, y.depthHint)
    # tasks.sort(sortTasks)

    glClearColor(0.5, 0.5, 0.5, 1.0);        
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)

    # Setup matrices for Model-View-Projection
    let projection = glm.perspective(45f, 640f / 480f, 0.1f, 100.0f)
    let view = glm.lookAt(this.cameraEye, this.cameraLookAt, vec3f(0, 1, 0))

    let shaderProgram = this.shaderPrograms[this.defaultShaderProgram]
    shaderProgram.use()

    # Render each 
    for task in tasks:
        var bufferedModel = this.models[task.modelId]
        var bufferedMesh = bufferedModel.meshes[task.meshId]

        let mvp = projection * view * task.matrix
        let mvpId = glGetUniformLocation(shaderProgram.glProgramId, "mvp")
        glUniformMatrix4fv(mvpId, 1.GLsizei, false.GLboolean, mvp.arr[0].arr[0].unsafeAddr)

        glBindVertexArray(bufferedMesh.vaoId)
        # glBindBuffer(GL_ARRAY_BUFFER, this.vbo)
        # glBufferData(GL_ARRAY_BUFFER, task.vertices.len * sizeof(Vert), task.vertices[0].unsafeAddr, GL_DYNAMIC_DRAW)
        glDrawArrays(GL_TRIANGLES, 0, GLsizei(bufferedMesh.indices.len / 3)) # 3 indices per triangle

    # quit "Frame"


method endFrame*(this: OglRenderer) =
    swapBuffers(this.window)

proc getModelInstance*(this: OglRenderer, id: ModelId): ModelInstance =
    var model = this.models[id]
    result = new(ModelInstance)
    result.modelId = id
    result.meshes = newSeq[MeshInstance]()
    for m in model.meshes:
        var mesh = new(MeshInstance)
        mesh.meshId = m.id
        result.meshes.add(mesh)


method getModelInstance*(this: OglRenderer, path: string): ModelInstance =
    var id = this.loadModel(path)
    this.getModelInstance(id)


proc loadDefaultProgram(this: OglRenderer) =
    info "Loading Shader Program"
    
    # Default vertex shader
    var vertexShader = """
        #version 410 core

        layout (location = 0) in vec3 vertexPosition;
        layout (location = 1) in vec3 vertexColor;
        layout (location = 0) out vec3 fragmentColor;

        uniform mat4 mvp;

        void main()
        {
            gl_Position = mvp * vec4(vertexPosition, 1.0);
            fragmentColor = vertexColor;
        }"""

    #Default fragment shader
    var fragmentShader = """
        #version 410 core

        layout (location = 0) in vec3 fragmentColor;
        out vec4 finalColor;

        void main()
        {
            finalColor = vec4(fragmentColor, 1.0);
        }"""

    var program = newProgramFromSource(vertexShader, fragmentShader)
    program.use()
    this.shaderPrograms[program.id] = program
    this.defaultShaderProgram = program.id


proc loadShaderOgl(shaderType: ShaderType, shaderText: string): OglShader =
    info "Loading Shader " & ShaderNameMap[shaderType]
    var shaderId = glCreateShader(TextureTypeMap[shaderType])
    var shaders = allocCStringArray([shaderText])
    var lengths = [shaderText.len.GLint]
    
    glShaderSource(shaderId, 1.GLsizei, shaders, lengths[0].unsafeAddr)
    glCompileShader(shaderId)

    var success = 0.GLint
    glGetShaderiv(shaderId, GL_COMPILE_STATUS, success.addr)
    if success == 0:
        var
            buff = newString(512)
            len = 0.GLsizei

        glGetShaderInfoLog(shaderId, len(buff).GLsizei, len.addr, buff[0].addr)
        buff.setLen(len.int)
        quit buff

    let r = OglShader(glShaderId: shaderId, shaderType: shaderType, shaderText: shaderText)
    result = r


proc newShaderProgram(vs: OglShader, fs: OglShader): OglProgram =
    var programId = glCreateProgram()
    if programId == 0:
        error "No shader program created"
        quit ""

    glAttachShader(programId, vs.glShaderId)
    glAttachShader(programId, fs.glShaderId)
    glLinkProgram(programId)

    var success: GLint
    glGetProgramiv(programId, GL_LINK_STATUS, success.unsafeAddr)
    if success == 0:
        var
            buff = newString(512)
            len = 0.GLsizei

        glGetProgramInfoLog(programId, len(buff).GLsizei, len.addr, buff[0].addr)
        buff.setLen(len.int)
        error buff
        quit ""

    var program = new(OglProgram)
    program.glProgramId = programId
    result = program

    vs.delete()
    fs.delete()


proc newProgramFromSource*(vertexShader: string, fragmentShader: string): OglProgram =
    var vs = loadShaderOgl(ShaderType.VertexShader, vertexShader)
    var fs = loadShaderOgl(ShaderType.FragmentShader, fragmentShader)
    newShaderProgram(vs, fs)


proc newOglRenderer*(): OglRenderer =
    info "Creating OglRenderer"
    
    result = new(OglRenderer)
    result.loader = newAssimpLoader()
    result.models = newTable[ModelId, BufferedModel]()
    result.shaderPrograms = newTable[ShaderProgramId, OglProgram]()

method openWindow*(this: OglRenderer, width: int32, height: int32, title: string) =
    if not glfwInit():
        error "Init failed"
        quit()
    else:
        info "Init succeeded"

    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 2);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE.int32);

    info "Creating window"

    this.window = glfwCreateWindow(width, height, title, nil, nil, false)
    if (this.window == nil):
        glfwTerminate()
        error "Window create failed"
        quit()
    else:
        info "Created window"

    makeContextCurrent(this.window)

    # Initialize OpenGL
    loadExtensions()

    info "Loading extensions"

    # glViewport(0, 0, screenWidth, screenHeight)
    glClearColor(0.0, 0.0, 0.0, 1.0) # Set background color to black and opaque
    glClearDepth(1.0) # Set background depth to farthest
    glEnable(GL_DEPTH_TEST) # Enable depth testing for z-culling
    glDepthFunc(GL_LEQUAL) # Set the type of depth-test

    info cast[cstring](glGetString(GL_RENDERER))
    info cast[cstring](glGetString(GL_VERSION))

    info "Loading default program"

    this.loadDefaultProgram()

    info "Loaded default program"
