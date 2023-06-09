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

# test "can create window":
#     let fmtStr = "[$time] - $levelname: "
#     addHandler(newConsoleLogger(fmtStr = fmtStr))
#     # addHandler(newRollingFileLogger(filename = "log.txt", fmtStr = fmtStr))

#     var g = newGraphics(newOglRenderer())
#     g.openWindow(640, 480, "Sample")

#     # var path = "some/path/to/model.xyz"
#     # discard g.loadModel(path)
#     # var mi = g.getModelInstance(path)

#     var tasks = newSeq[RenderTask]()
#     # for mesh in mi.meshes:
#     #     tasks.add(RenderTask(mode: RenderMode.Projection, modelId: mi.id, meshId: mesh.meshId))

#     g.render(tasks)

test "can render duck":
    let fmtStr = "[$time] - $levelname: "
    addHandler(newConsoleLogger(fmtStr = fmtStr))
    # addHandler(newRollingFileLogger(filename = "log.txt", fmtStr = fmtStr))

    var g = newGraphics(newOglRenderer())
    g.openWindow(640, 480, "Sample")
    g.getRenderer().setCameraEye(vec3f(0, 0, 100))

    info os.getCurrentDir()

    var path = "tests/res/models/duck.dae"
    discard g.loadModel(path)
    var mi = g.getModelInstance(path)

    var tasks = newSeq[RenderTask]()
    for mesh in mi.meshes:
        echo "Mesh id: ", mesh.meshId
        # Where do we store the translate and rotation and scale?
        tasks.add(RenderTask(mode: RenderMode.Projection, modelId: mi.id, meshId: mesh.meshId, matrix: translate(mat4f(), mesh.translation) * glm.mat4(mesh.rotation) * glm.scale(mat4f(), vec3f(0.1f, 0.1f, 0.1f))))

    echo "Mesh count: ", mi.meshes.len
    echo "Tasks count: ", tasks.len
    while g.isRunning():
        g.render(tasks)

