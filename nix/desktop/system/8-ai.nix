{ ... }:
{
  services = {
    ollama.enable = false;
    open-webui.enable = false;

    ollama.acceleration = "cuda";
    ollama.models = "/mnt/hdd/AI/ollama/models";
    ollama.user = "ollama";
    ollama.group = "ollama";

    open-webui.host = "127.0.0.1";
    open-webui.port = 10001;
    open-webui.environment = {
      ANONYMIZED_TELEMETRY = "False";
      DO_NOT_TRACK = "True";
      SCARF_NO_ANALYTICS = "True";
      OLLAMA_API_BASE_URL = "http://127.0.0.1:11434";
      OLLAMA_KEEP_ALIVE = "60";
      WEBUI_AUTH = "False";
    };
  };
}
