import ../graphics

type 
    Mesh* = ref object of RootObj
        vertices*: seq[Vertex]
        texCoords*: seq[TexCoord]
        normals*: seq[Normal]
        colors*: seq[Color]
        indices*: seq[int32]

    Model* = ref object of RootObj
        meshes*: seq[Mesh]

    ModelLoader* = ref object of RootObj

method loadModel*(this: ModelLoader, path: string): Model {.base.} = discard

proc newModel*(): Model =
    result = new(Model)
    result.meshes = newSeq[Mesh]()

proc hasVertices*(this: Mesh): bool = this.vertices.len > 0
proc hasTexCoords*(this: Mesh): bool = this.texCoords.len > 0
proc hasNormals*(this: Mesh): bool = this.normals.len > 0
proc hasColors*(this: Mesh): bool = this.colors.len > 0
proc hasIndices*(this: Mesh): bool = this.indices.len > 0