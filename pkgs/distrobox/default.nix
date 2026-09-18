{
  lib,
  buildGoModule,
  fetchFromGitHub,
  installShellFiles,
}:
buildGoModule (finalAttrs: {
  pname = "distrobox";
  version = "2.0.0-rc.4-unstable-2026-09-17";

  src = fetchFromGitHub {
    owner = "89luca89";
    repo = "distrobox";
    rev = "f60fb9d35ecf5182c8235e703c312ab6affae643";
    hash = "sha256-B8ZfuSBa7Nkv/zlt9winxQcQ6Vk0g6nNf2DxE+bch14=";
  };

  vendorHash = "sha256-9/R3LTPzpmL8YEmwiCX1aAT6gNzdB10c4tXAzrnq5Zg=";

  ldflags = [
    "-X github.com/89luca89/distrobox/pkg/version.Version=${finalAttrs.version}"
  ];

  nativeBuildInputs = [ installShellFiles ];

  doCheck = false;

  postInstall = ''
    for sub in assemble create enter ephemeral generate-entry ls list rm stop upgrade; do
      ln -s distrobox $out/bin/distrobox-$sub
    done

    install -Dm755 internal/inside-distrobox/assets/distrobox-{init,export,host-exec} -t $out/bin

    installManPage man/man1/*.1
    installShellCompletion --bash completions/bash/distrobox --zsh completions/zsh/_distrobox

    install -Dm644 icons/terminal-distrobox-icon.svg \
      $out/share/icons/hicolor/scalable/apps/terminal-distrobox-icon.svg
    for size in 16 22 24 32 36 48 64 72 96 128 256; do
      install -Dm644 icons/hicolor/''${size}x''${size}/apps/terminal-distrobox-icon.png \
        $out/share/icons/hicolor/''${size}x''${size}/apps/terminal-distrobox-icon.png
    done
  '';

  meta = {
    description = "Wrapper around podman or docker to create and start containers";
    homepage = "https://distrobox.it/";
    license = lib.licenses.gpl3Only;
    mainProgram = "distrobox";
    platforms = lib.platforms.linux;
  };
})
