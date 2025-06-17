update:
	nix flake update

update-unstable:
	nix flake update nixpkgs-unstable

system:
	sudo darwin-rebuild switch --flake .#Sebastians-MacBook-Pro-2

check:
	darwin-rebuild check --flake .#Sebastians-MacBook-Pro-2

build:
	darwin-rebuild build --flake .#Sebastians-MacBook-Pro-2

trampoline:
	nix run github:hraban/mac-app-util -- mktrampoline "/nix/store/pfm28jpyp52a60ygc57bwn7x1wx7isq4-iterm2-3.5.2/Applications/iTerm2.app" /Applications/MyApp.app

user:
	home-manager switch --flake .#$(USER) -b backup


gc:
	nix-env --delete-generations old
	nix-store --gc
	nix-collect-garbage -d