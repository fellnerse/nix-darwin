{
  lib,
  buildGoModule,
  fetchFromGitHub,
  makeWrapper,
  installShellFiles,
  beads,
  tmux,
  git,
}:

buildGoModule rec {
  pname = "gastown";
  version = "unstable-2026-01-20";

  src = fetchFromGitHub {
    owner = "steveyegge";
    repo = "gastown";
    rev = "main";
    hash = "sha256-MomC6UMBoH1KgRAXD/cibumrBoyqsKC/XWrdBZA3xhs=";
  };

  vendorHash = "sha256-ripY9vrYgVW8bngAyMLh0LkU/Xx1UUaLgmAA7/EmWQU=";

  nativeBuildInputs = [
    makeWrapper
    installShellFiles
  ];

  subPackages = [ "cmd/gt" ];

  # Wrap the binary to ensure runtime dependencies are available
  postInstall = ''
    wrapProgram $out/bin/gt \
      --prefix PATH : ${
        lib.makeBinPath [
          beads
          tmux
          git
        ]
      }

    # Generate shell completions
    installShellCompletion --cmd gt \
      --bash <($out/bin/gt completion bash) \
      --fish <($out/bin/gt completion fish) \
      --zsh <($out/bin/gt completion zsh)
  '';

  meta = with lib; {
    description = "Multi-agent orchestration system for Claude Code";
    homepage = "https://github.com/steveyegge/gastown";
    license = licenses.mit;
    maintainers = [ ];
  };
}
