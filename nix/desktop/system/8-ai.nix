{ ... }:
{
  services = {
    ollama = {
      enable = true;

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
