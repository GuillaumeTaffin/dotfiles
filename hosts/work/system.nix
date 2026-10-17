{ ... }:
{
  homebrew = {
    # Imperative installs on this machine were never audited: keep them.
    onActivation.cleanup = "none";
    taps = [
      { name = "atlassian/acli"; trusted = true; }
    ];

    brews = [
      "tfenv"
      "docker"
      "lima"
      "codex"
      "gemini-cli"
      "googleworkspace-cli"
      "atlassian/acli/acli"
      "pandoc"
      "pandoc-crossref"
    ];

    casks = [
      "gpg-suite"
      "stats"
      "session-manager-plugin"
      "appcleaner"
      "jetbrains-toolbox"
    ];
  };
}
