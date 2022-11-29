import assimp
import ../graphics
import model
import os

type 
    AssimpLoader* = ref object of ModelLoader

method loadModel*(this: AssimpLoader, path: string): Model = 
    if not fileExists(path):
        raise newException(IOError, "File does not exist: " & path)

    var scene = assimp.aiImportFile(path, {})
    if scene == nil:
        raise newException(IOError, "Invalid model file: " & path)

    result = newModel()
    for m in scene.imeshes:
        var mesh: Mesh = new(model.Mesh)
        mesh.vertices = newSeqOfCap[Vertex](m.vertexCount)
        mesh.vertices.setLen(m.vertexCount)
        copyMem(mesh.vertices[0].addr, m.vertices, m.vertexCount * sizeof(TVector3d))
        mesh.indices = newSeqOfCap[int32](3 * m.faceCount)

        if m.hasNormals:
            mesh.normals.setLen(m.vertexCount)
            copyMem(mesh.normals[0].addr, m.normals, m.vertexCount * sizeof(TVector3d))

        if m.hasUvs:
            mesh.texCoords = newSeqOfCap[TexCoord](m.vertexCount)
            mesh.texCoords.setLen(m.vertexCount)
            copyMem(mesh.texCoords[0].addr, m.texCoords[0], m.vertexCount * sizeof(TVector3d))

        if m.hasColors:
            mesh.colors = newSeqOfCap[Color](m.vertexCount)
            mesh.colors.setLen(m.vertexCount)
            copyMem(mesh.colors[0].addr, m.colors[0], m.vertexCount * sizeof(TColor4d))

        if m.hasFaces:
            mesh.indices = newSeqOfCap[int32](3 * m.faceCount)
            for f in m.ifaces:
                var idx = mesh.indices.len
                mesh.indices.setLen(idx + 3)
                copyMem(mesh.indices[idx].addr, f.indices,  3 * sizeof(cint))

        result.meshes.add(mesh)

proc newAssimpLoader*(): AssimpLoader =
    result = new(AssimpLoader)
    