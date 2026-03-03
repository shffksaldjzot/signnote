# To learn more about how to use Nix to configure your environment
# see: https://developers.google.com/idx/guides/customize-idx-env
{ pkgs, ... }: {
  # Which nixpkgs channel to use.
  channel = "stable-24.05"; # or "unstable"

  # Use https://search.nixos.org/packages to find packages
  packages = [
    pkgs.jdk17
    pkgs.unzip
  ];

  # Sets environment variables in the workspace
  env = {};

  idx = {
    # Search for the extensions you want on https://open-vsx.org/ and use "publisher.id"
    extensions = [
      "Dart-Code.flutter"
      "Dart-Code.dart-code"
      "google.gemini-cli-vscode-ide-companion"
    ];

    # Enable previews (미리보기 설정)
    previews = {
      enable = true;
      previews = {
        web = {
          # Flutter 웹 앱 미리보기
          command = [
            "flutter"
            "run"
            "--machine"
            "-d"
            "web-server"
            "--web-hostname"
            "0.0.0.0"
            "--web-port"
            "$PORT"
          ];
          manager = "flutter";
          cwd = "signnote_app";
        };
      };
    };

    # Workspace lifecycle hooks
    workspace = {
      # Runs when a workspace is first created
      onCreate = {
        default.openFiles = [ ".idx/dev.nix" ];
      };
      # Runs when the workspace is (re)started
      onStart = {
        # 필요시 백그라운드 작업 추가 가능
      };
    };
  };
}
