{ pkgs, ... }:
{
  imports = [ ../../modules/common/podman.nix ];

  home.packages = with pkgs; [
    # containers / k8s / cloud (docker-compose comes with the podman module)
    kubectx
    stern
    cloudflared
    doppler
    aws-sam-cli
    # languages
    go
    # net
    mosh
    # documents (cv-base: pandoc --pdf-engine=tectonic; pandoc itself is on brew)
    tectonic
  ];

  programs.git = {
    signing = {
      format = "openpgp";
      key = "A2AE5B3978A9CF52";   # Guillaume Taffin <cloudgt.dev@gmail.com>, rsa3072, expires 2027-08-17
      signByDefault = true;
    };

    settings = {
      user.name = "Guillaume Taffin";
      user.email = "cloudgt.dev@gmail.com";
      tag.gpgSign = true;
    };
  };
}
