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

test "can create window":
    let fmtStr = "[$time] - $levelname: "
    addHandler(newConsoleLogger(fmtStr = fmtStr))
    # addHandler(newRollingFileLogger(filename = "log.txt", fmtStr = fmtStr))

    var g = newGraphics(newOglRenderer())
    g.openWindow(640, 480, "Sample")

    # var path = "some/path/to/model.xyz"
    # discard g.loadModel(path)
    # var mi = g.getModelInstance(path)

    var tasks = newSeq[RenderTask]()
    # for mesh in mi.meshes:
    #     tasks.add(RenderTask(mode: RenderMode.Projection, modelId: mi.id, meshId: mesh.meshId))

    g.render(tasks)
