{ config, ... }:
let
  # Keep in sync with modules/common/home.nix.
  repo = "${config.home.homeDirectory}/.dotfiles-mac";
  inherit (config.lib.file) mkOutOfStoreSymlink;
in
{
  home.file.".config/git/allowed_signers".source =
    mkOutOfStoreSymlink "${repo}/git/allowed_signers";

  programs.git = {
    signing = {
      format = "ssh";
      key = "key::ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL9GnREAGTw8JMmTrGjM975t9eQOtqnUJmvMi5qBk0Ak guillaume.taffin@akur8.com";
      signByDefault = true;
    };

    settings = {
      user.name = "Guillaume Taffin";
      user.email = "guillaume.taffin@akur8.com";
      tag.gpgSign = true;
      gpg.ssh.allowedSignersFile = "${config.home.homeDirectory}/.config/git/allowed_signers";
      safe.directory = [
        "/Users/guillaume.taffin/dev/projects/work-projections"
        "/Users/guillaume.taffin/dev/projects/ai-transformation.plain-sandcastle-review-pipeline"
        "/Users/guillaume.taffin/dev/projects/ai-transformation.triage-workflow"
      ];
    };
  };
}
