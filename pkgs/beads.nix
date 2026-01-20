{
  lib,
  buildGoModule,
  fetchFromGitHub,
  installShellFiles,
}:

buildGoModule rec {
  pname = "beads";
  version = "unstable-2026-01-20";

  src = fetchFromGitHub {
    owner = "steveyegge";
    repo = "beads";
    rev = "main";
    hash = "sha256-FZTXNUAV2wPGvpZ6YHPtNAvijhs9nfuS+qkkIefYOSY=";
  };

  vendorHash = "sha256-YU+bRLVlWtHzJ1QPzcKJ70f+ynp8lMoIeFlm+29BNPE=";

  nativeBuildInputs = [ installShellFiles ];

  subPackages = [ "cmd/bd" ];

  # Tests require git which is not available in the build environment
  doCheck = false;

  # Generate shell completions
  postInstall = ''
    installShellCompletion --cmd bd \
      --bash <($out/bin/bd completion bash) \
      --fish <($out/bin/bd completion fish) \
      --zsh <($out/bin/bd completion zsh)
  '';

  meta = with lib; {
    description = "Distributed, git-backed graph issue tracker for AI agents";
    homepage = "https://github.com/steveyegge/beads";
    license = licenses.mit;
    maintainers = [ ];
  };
}
