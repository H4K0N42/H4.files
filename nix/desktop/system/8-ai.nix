{ unstable, ... }:
{
  services = {
    ollama = {
      enable = false;
      package = unstable.ollama-cuda;
      host = "0.0.0.0";
      acceleration = "cuda";
      models = "/mnt/hdd/AI/linux/ollama/models";
      user = "ollama";
      environmentVariables = {
        OLLAMA_KEEP_ALIVE = "10";
        OLLAMA_MAX_LOADED_MODELS = "1";
      };
    };
  };
}
