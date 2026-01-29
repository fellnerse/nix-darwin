{
  stdenv,
  fetchurl,
  makeWrapper,
  lib,
}:

stdenv.mkDerivation rec {
  pname = "sshfs-mac";
  version = "3.7.5";

  src = fetchurl {
    url = "https://github.com/libfuse/sshfs/releases/download/sshfs-${version}/sshfs-${version}.pkg";
    sha256 = "611713612179cf7ccd2995051165da7d19e0ca199ae70d9680c3d3551f456d46";
  };

  nativeBuildInputs = [ makeWrapper ];

  unpackPhase = "true"; # .pkg files don't need unpacking for our purposes

  installPhase = ''
    mkdir -p $out/bin

    # Create an installer script that can be run to install SSHFS
    cat > $out/bin/install-sshfs-mac <<'EOF'
    #!/usr/bin/env bash
    set -e

    # Check if already installed
    if [ -f /usr/local/bin/sshfs ]; then
      INSTALLED_VERSION=$(/usr/local/bin/sshfs -V 2>&1 | head -1 | awk '{print $3}')
      if [ "$INSTALLED_VERSION" = "${version}" ]; then
        echo "SSHFS ${version} is already installed at /usr/local/bin/sshfs"
        exit 0
      fi
    fi

    echo "Installing SSHFS ${version}..."
    echo "This requires sudo access to install to /usr/local/bin"
    sudo installer -pkg ${src} -target /
    echo "SSHFS ${version} installed successfully!"
    echo "You can now use: sshfs user@host:/path /local/mount/point"
    EOF

    chmod +x $out/bin/install-sshfs-mac

    # Create a symlink to sshfs if it exists in /usr/local/bin
    # This allows Nix to "see" the system-installed sshfs
    cat > $out/bin/sshfs <<'EOF'
    #!/usr/bin/env bash
    if [ -f /usr/local/bin/sshfs ]; then
      exec /usr/local/bin/sshfs "$@"
    else
      echo "SSHFS is not installed. Run 'install-sshfs-mac' to install it."
      exit 1
    fi
    EOF

    chmod +x $out/bin/sshfs
  '';

  meta = with lib; {
    description = "Installer and wrapper for SSHFS on macOS (requires macFUSE)";
    longDescription = ''
      This package provides an installer script for SSHFS 3.7.5 on macOS.

      SSHFS requires macFUSE to be installed first. Install macFUSE via Homebrew:
        brew install --cask macfuse

      Then run:
        install-sshfs-mac

      After installation, you can use sshfs normally:
        sshfs user@host:/remote/path /local/mount/point
        umount /local/mount/point  # to unmount
    '';
    homepage = "https://github.com/libfuse/sshfs";
    platforms = platforms.darwin;
  };
}
