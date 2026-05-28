{ pkgs, ... }:
{
  services = {
    ollama = {
      enable = false;
      package = pkgs.ollama-cuda;
      host = "0.0.0.0";
      models = "/mnt/hdd/AI/linux/ollama/models";
      user = "ollama";
      environmentVariables = {
        OLLAMA_KEEP_ALIVE = "10";
        OLLAMA_MAX_LOADED_MODELS = "1";
      };
    };
  };
}
