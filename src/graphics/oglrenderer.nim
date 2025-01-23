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

        # Resources
        currentShaderProgramId: ShaderProgramId
        models: TableRef[ModelId, BufferedModel]
        shaderPrograms: TableRef[ShaderProgramId, OglProgram]
        lights*: TableRef[LightId, Light]

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
        # indices*: seq[int32]
        faceCount*: GLsizei

    UniformTypes* {.pure.} = enum
        Int
        Float
        Vec2
        Vec3
        Vec4
        Mat3
        Mat4


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

proc newProgramFromSource(this: OglRenderer, vertexShader: string, fragmentShader: string): OglProgram


proc delete*(this: OglShader) = 
    glDeleteShader(this.glShaderId)
    this.glShaderId = 0


proc use*(this: OglProgram) =
    glUseProgram(this.glProgramId)

proc setUniform*(this: OglProgram, name: string, value: Mat4f) =
    var location = glGetUniformLocation(this.glProgramId, name)
    glUniformMatrix4fv(location, 1, GL_FALSE, value.arr[0].arr[0].unsafeAddr)

proc setUniform*(this: OglProgram, name: string, value: Vec3f) =
    var location = glGetUniformLocation(this.glProgramId, name)
    glUniform3fv(location, 1, value.arr[0].unsafeAddr)

proc setUniform*(this: OglProgram, name: string, value: Vec4f) =
    var location = glGetUniformLocation(this.glProgramId, name)
    glUniform4fv(location, 1, value.arr[0].unsafeAddr)

proc setUniform*(this: OglProgram, name: string, value: float) =
    var location = glGetUniformLocation(this.glProgramId, name)
    glUniform1f(location, value)

proc setUniform*(this: OglProgram, name: string, value: bool) =
    var location = glGetUniformLocation(this.glProgramId, name)
    glUniform1i(location, value.int32)

proc setUniform*(this: OglProgram, name: string, value: Mat3f) =
    var location = glGetUniformLocation(this.glProgramId, name)
    glUniformMatrix3fv(location, 1, GL_FALSE, value.arr[0].arr[0].unsafeAddr)

proc setUniform*(this: OglProgram, name: string, value: Vec2f) =
    var location = glGetUniformLocation(this.glProgramId, name)
    glUniform2fv(location, 1, value.arr[0].unsafeAddr)


method loadTexture*(this: OglRenderer, path: string): Texture = 
    discard


method loadModel*(this: OglRenderer, path: string): ModelId = 
    var model = this.loader.loadModel(path)
    var bufferedModel = new(BufferedModel)
    bufferedModel.meshes = newSeq[BufferedMesh]()

    for m in model.meshes:
        var buffer: GLuint
        var b = new(BufferedMesh)
        # Vertex array object, one per mesh
        glGenVertexArrays(1, b.vaoId.addr)
        glBindVertexArray(b.vaoId)
        
        glGenBuffers(1, buffer.addr)
        glBindBuffer(GL_ARRAY_BUFFER, buffer)
        glBufferData(GL_ARRAY_BUFFER, m.vertices.len * sizeof(Vertex), m.vertices[0].addr, GL_STATIC_DRAW)
        glVertexAttribPointer(0, 3, cGL_FLOAT, GL_FALSE, 0, nil)
        glEnableVertexAttribArray(0)

        if m.hasNormals():
            glGenBuffers(1, buffer.addr)
            glBindBuffer(GL_ARRAY_BUFFER, buffer)
            glBufferData(GL_ARRAY_BUFFER, m.vertices.len * sizeof(Normal), m.normals[0].addr, GL_STATIC_DRAW)
            glVertexAttribPointer(1, 3, cGL_FLOAT, GL_FALSE, 0, nil)
            glEnableVertexAttribArray(1)

        if m.hasTexCoords():
            glGenBuffers(1, buffer.addr)
            glBindBuffer(GL_ARRAY_BUFFER, buffer)
            glBufferData(GL_ARRAY_BUFFER, m.vertices.len * sizeof(TexCoord), m.texCoords[0].addr, GL_STATIC_DRAW)
            glVertexAttribPointer(2, 2, cGL_FLOAT, GL_FALSE, 0, nil)
            glEnableVertexAttribArray(2)

        if m.hasColors():
            glGenBuffers(1, buffer.addr)
            glBindBuffer(GL_ARRAY_BUFFER, buffer)
            glBufferData(GL_ARRAY_BUFFER, m.vertices.len * sizeof(Color), m.colors[0].addr, GL_STATIC_DRAW)
            glVertexAttribPointer(3, 3, cGL_FLOAT, GL_FALSE, 0, nil)
            glEnableVertexAttribArray(3)

        if m.hasIndices():
            b.faceCount = m.indices.len.GLsizei
            glGenBuffers(1, buffer.addr)
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, buffer)
            glBufferData(GL_ELEMENT_ARRAY_BUFFER, m.indices.len * sizeof(uint32), m.indices[0].unsafeaddr, GL_STATIC_DRAW)

        b.id = bufferedModel.meshes.len.MeshId
        bufferedModel.meshes.add(b)
    bufferedModel.id = len(this.models).ModelId
    this.models[bufferedModel.id] = bufferedModel
    result = bufferedModel.id


method loadShaderProgram*(this: OglRenderer, vertexShaderText: string, fragmentShaderText: string): ShaderProgramId =
    var program = this.newProgramFromSource(vertexShaderText, fragmentShaderText)
    result = program.id

method useShaderProgram*(this: OglRenderer, shaderProgramId: ShaderProgramId) =
    var program = this.shaderPrograms[shaderProgramId]
    program.use()
    this.currentShaderProgramId = shaderProgramId

method addLight*(this: OglRenderer, light: Light) =
    light.id = len(this.lights).LightId
    this.lights[light.id] = light
    discard

method getLights(this: OglRenderer): seq[Light] = 
    result = values(this.lights)

method clearLight(this: OglRenderer, name: LightName) = discard

method preRender*(this: OglRenderer) =
    if this.currentShaderProgramId == 0:
        this.useShaderProgram(this.defaultShaderProgram)

    var program = this.shaderPrograms[this.currentShaderProgramId]
    for i,li in pairs(this.lights):
        program.setUniform("lights" & i, li.position)
    discard

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
    let view = glm.lookAt(this.getCameraEye(), this.getCameraLookAt(), vec3f(0, 1, 0))

    let shaderProgram = this.shaderPrograms[this.currentShaderProgramId]
    
    # Render each 
    for task in tasks:
        var bufferedModel = this.models[task.modelId]
        var bufferedMesh = bufferedModel.meshes[task.meshId]

        let mvp = projection * view * task.matrix
        shaderProgram.setUniform("mvp", mvp)
        
        glBindVertexArray(bufferedMesh.vaoId)
        glDrawElements(GL_TRIANGLES, bufferedMesh.faceCount, GL_UNSIGNED_INT, nil)
        glBindVertexArray(0)

    # quit "Frame"


method endFrame*(this: OglRenderer) =
    glfwPollEvents()
    swapBuffers(this.window)

method getModelInstance*(this: OglRenderer, id: ModelId): ModelInstance =
    var model = this.models[id]
    result = new(ModelInstance)
    result.modelId = id
    result.meshes = newSeq[MeshInstance]()
    for m in model.meshes:
        var mesh = new(MeshInstance)
        mesh.meshId = m.id
        mesh.rotation = glm.quatf(vec3f(1, 0, 0), 0)
        mesh.translation = vec3f(0, 0, 0)
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
        layout (location = 1) in vec3 normal;
        layout (location = 2) in vec3 uv;

        uniform mat4 mvp;
        out vec3 oNormal;
        out vec2 oUv;

        void main()
        {
            gl_Position = mvp * vec4(vertexPosition, 1.0);
            oNormal = normal;
            oUv = uv.xy;
        }"""

    #Default fragment shader
    var fragmentShader = """
        #version 410 core
        out vec4 finalColor;

        in vec3 oNormal;
        in vec2 oUv;

        void main()
        {
            finalColor = vec4(1.0f, 0.0f, 0.0f, 1.0f);
        }"""

    var program = this.newProgramFromSource(vertexShader, fragmentShader)
    this.defaultShaderProgram = program.id
    this.useShaderProgram(program.id)


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

        glGetShaderInfoLog(shaderId, len(buff).GLsizei, len.addr, cast[cstring](buff[0].addr))
        buff.setLen(len.int)
        quit buff

    let r = OglShader(glShaderId: shaderId, shaderType: shaderType, shaderText: shaderText)
    result = r


proc newShaderProgram(this: OglRenderer, vs: OglShader, fs: OglShader): OglProgram =
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

        glGetProgramInfoLog(programId, len(buff).GLsizei, len.addr, cast[cstring](buff[0].addr))
        buff.setLen(len.int)
        error buff
        quit ""

    var program = new(OglProgram)
    program.glProgramId = programId
    result = program

    program.id = ShaderProgramId(len(this.shaderPrograms) + 1)
    this.shaderPrograms[program.id] = program

    vs.delete()
    fs.delete()


proc newProgramFromSource*(this: OglRenderer, vertexShader: string, fragmentShader: string): OglProgram =
    var vs = loadShaderOgl(ShaderType.VertexShader, vertexShader)
    var fs = loadShaderOgl(ShaderType.FragmentShader, fragmentShader)
    this.newShaderProgram(vs, fs)


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

method isWindowOpen*(this: OglRenderer): bool =
    not windowShouldClose(this.window)