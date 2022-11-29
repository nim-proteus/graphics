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