{ unstable, ... }:
{
  services = {
    ollama = {
      enable = true;

      package = unstable.ollama-cuda;
      host = "0.0.0.0";
      acceleration = "cuda";
      models = "/mnt/hdd/AI/linux/ollama/models";
      user = "ollama";
      environmentVariables = {
        OLLAMA_KEEP_ALIVE = "1m";
      };
    };
  };
}
