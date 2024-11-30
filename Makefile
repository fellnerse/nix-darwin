update:
	nix flake update

rebuild:
	darwin-rebuild switch --flake .#Sebastians-MacBook-Pro-2

check:
	darwin-rebuild check --flake .#Sebastians-MacBook-Pro-2

build:
	darwin-rebuild build --flake .#Sebastians-MacBook-Pro-2

switch:
	nix run nix-darwin -- switch --flake ~/.config/nix-darwin

trampoline:
	nix run github:hraban/mac-app-util -- mktrampoline "/nix/store/pfm28jpyp52a60ygc57bwn7x1wx7isq4-iterm2-3.5.2/Applications/iTerm2.app" /Applications/MyApp.app

sefe:
	home-manager switch --flake .#sefe -b backup

private:
	home-manager switch --flake .#private -b backup