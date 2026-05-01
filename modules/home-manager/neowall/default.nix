{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.neowall;
  neowallPackage = pkgs.callPackage ../../../packages/neowall/default.nix { };
  neowallCli = lib.getExe neowallPackage;

  renderedConfig =
    if cfg.mode == "shader" then
      ''
        default {
          shader shader.glsl
          shader_speed ${toString cfg.shader.speed}
        }
      ''
    else if cfg.mode == "slideshow" then
      ''
        default {
          path ${toString cfg.slideshow.path}/
          duration ${toString cfg.slideshow.duration}
          transition ${cfg.slideshow.transition}
        }
      ''
    else
      throw "Unsupported wallpaper mode: ${cfg.mode}";
in
{
  options.programs.neowall = {
    enable = lib.mkEnableOption "Neowall";

    mode = lib.mkOption {
      type = lib.types.enum [
        "shader"
        "slideshow"
      ];
      default = "shader";
    };

    shader = {
      path = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = ./shaders;
        description = "Path to a GLSL shader file";
      };
      speed = lib.mkOption {
        type = lib.types.float;
        default = 1.0;
      };
    };

    slideshow = {
      dir = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
      };
      duration = lib.mkOption {
        type = lib.types.int;
        default = 300;
      };
      transition = lib.mkOption {
        type = lib.types.enum [
          "none"
          "fade"
          "glitch"
          "wipe"
        ];
        default = "none";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      home.packages = [ neowallPackage ];
      xdg.configFile."neowall/config.vibe".text = renderedConfig;

      systemd.user.services.neowall = {
        Unit = {
          Description = "Neowall Daemon";
          After = [ "graphical-session.target" ];
          PartOf = [ "graphical-session.target" ];
        };
        Service = {
          Type = "simple";
          ExecStart = "${neowallCli} --foreground --verbose";
          Restart = "on-failure";
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };
    })

    (lib.mkIf (cfg.enable && cfg.mode == "slideshow") {
      assertions = [
        {
          assertion = cfg.slideshow.dir != null;
          message = "programs.neowall.slideshow.dir must be set when mode = \"slideshow\"";
        }
      ];
    })

    (lib.mkIf (cfg.enable && cfg.mode == "shader") {
      assertions = [
        {
          assertion = cfg.shader.path != null;
          message = "programs.neowall.shader.path must be set when mode = \"shader\"";
        }
      ];
      xdg.configFile."neowall/shaders/shader.glsl" = {
        text = builtins.readFile cfg.shader.path;
        force = true;
      };
    })
  ];
}
