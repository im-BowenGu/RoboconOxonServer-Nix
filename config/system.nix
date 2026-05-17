{ lib, pkgs, ... }:
{
  nixpkgs.hostPlatform = "x86_64-linux";
  system-manager.allowAnyDistro = true;

  environment.systemPackages = with pkgs; [
    nix
    podman docker-client podman-compose nginx curl wget sqlite
    cni-plugins aardvark-dns slirp4netns
    git
    panel-1panel
  ];

  systemd.services.podman = {
    enable = true;
    description = "Podman API Service";
    documentation = [ "man:podman(1)" ];
    requires = [ "podman.socket" ];
    after = [ "podman.socket" ];
    serviceConfig = {
      Type = "exec";
      ExecStart = "${pkgs.podman}/bin/podman system service --time=0";
      Restart = "on-failure";
      RestartSec = 10;
    };
    wantedBy = [ "default.target" ];
  };

  systemd.sockets.podman = {
    enable = true;
    description = "Podman API Socket";
    socketConfig = {
      ListenStream = "/run/podman/podman.sock";
      SocketMode = "0660";
      SocketUser = "root";
      SocketGroup = "root";
    };
    wantedBy = [ "sockets.target" ];
  };

  systemd.tmpfiles.rules = [
    "d /run/docker 0755 root root -"
    "L+ /run/docker.sock - - - - /run/podman/podman.sock"
    "L+ /run/docker/docker.sock - - - - /run/podman/podman.sock"
    "d /opt/1panel/tmp 0755 root root -"
  ];

  systemd.services."1panel-core" = {
    enable = true;
    description = "1Panel Core Service";
    after = [ "network-online.target" "podman.socket" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.panel-1panel}/bin/1panel-core";
      ExecReload = "/bin/kill -s HUP $MAINPID";
      Restart = "always";
      RestartSec = 5;
      StartLimitIntervalSec = 3600;
      StartLimitBurst = 5;
      LimitNOFILE = 1048576;
      LimitNPROC = 1048576;
      LimitCORE = 1048576;
      KillMode = "mixed";
      TimeoutStopSec = 90;
      Environment = [
        "PATH=/run/system-manager/sw/bin:/usr/bin:/bin"
        "HOME=/root"
      ];
    };
    wantedBy = [ "multi-user.target" ];
  };

  systemd.services."1panel-agent" = {
    enable = true;
    description = "1Panel Agent Service";
    after = [ "network-online.target" "1panel-core.service" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.panel-1panel}/bin/1panel-agent";
      ExecReload = "/bin/kill -s HUP $MAINPID";
      Restart = "always";
      RestartSec = 5;
      StartLimitIntervalSec = 3600;
      StartLimitBurst = 5;
      LimitNOFILE = 1048576;
      LimitNPROC = 1048576;
      LimitCORE = 1048576;
      KillMode = "mixed";
      TimeoutStopSec = 90;
      Environment = [
        "PATH=/run/system-manager/sw/bin:/usr/bin:/bin"
        "HOME=/root"
      ];
    };
    wantedBy = [ "multi-user.target" ];
  };

  services.nginx = {
    enable = true;
    package = pkgs.nginx;
    virtualHosts."default" = {
      serverName = "_";
      default = true;
      listen = [
        { addr = "0.0.0.0"; port = 80; }
      ];
      locations."/" = {
        extraConfig = "return 302 http://$host:37490;";
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /run/docker 0755 root root -"
    "L+ /run/docker.sock - - - - /run/podman/podman.sock"
    "L+ /run/docker/docker.sock - - - - /run/podman/podman.sock"
    "d /opt/1panel/tmp 0755 root root -"
  ];
}
