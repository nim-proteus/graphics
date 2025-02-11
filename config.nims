if existsEnv("ASSIMP_LIBRARY_PATH"):
  --dynlibOverride:assimp
  --passL:"$ASSIMP_LIBRARY_PATH"
# begin Nimble config (version 2)
when withDir(thisDir(), system.fileExists("nimble.paths")):
  include "nimble.paths"
# end Nimble config
