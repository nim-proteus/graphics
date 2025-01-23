if existsEnv("ASSIMP_LIBRARY_PATH"):
  --dynlibOverride:assimp
  --passL:"$ASSIMP_LIBRARY_PATH"