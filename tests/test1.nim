# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import unittest

import graphics
import graphics/oglrenderer 
import std/logging
import glm
import os

test "can render duck":
    let fmtStr = "[$time] - $levelname: "
    addHandler(newConsoleLogger(fmtStr = fmtStr))
    # addHandler(newRollingFileLogger(filename = "log.txt", fmtStr = fmtStr))

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

    var fragmentShader = """
        #version 410 core
        out vec4 finalColor;

        in vec3 oNormal;
        in vec2 oUv;

        void main()
        {
            finalColor = vec4(1.0f, 1.0f, 0.0f, 1.0f);
        }"""

    var g = newGraphics(newOglRenderer())
    g.openWindow(640, 480, "Sample")
    g.getRenderer().setCameraEye(vec3f(0, 0, 100))
    var id = g.getRenderer().loadShaderProgram(vertexShader, fragmentShader)
    g.getRenderer().useShaderProgram(id)
    
    var path = "tests/res/models/duck.dae"
    var modelId = g.loadModel(path)
    var mi = g.getModelInstance(modelId)

    var light = newLight(vec3f(0, 0, 0), vec3f(1, 1, 1), 1.0f)

    var tasks = newSeq[RenderTask]()
    for mesh in mi.meshes:
        # Where do we store the translate and rotation and scale?
        tasks.add(RenderTask(mode: RenderMode.Projection, modelId: mi.id, meshId: mesh.meshId, matrix: translate(mat4f(), mesh.translation) * glm.mat4(mesh.rotation) * glm.scale(mat4f(), vec3f(0.2f, 0.2f, 0.2f))))

    while g.isRunning():
        g.render(tasks)

