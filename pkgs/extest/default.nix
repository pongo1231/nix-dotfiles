{ lib
, rustPlatform
, fetchFromGitHub
}:

rustPlatform.buildRustPackage (finalAttrs:
let
  version = "1.0";
in
{
  pname = "extest";
  inherit version;

  src = fetchFromGitHub {
    owner = "Supreeeme";
    repo = finalAttrs.pname;
    rev = version;
    sha256 = "sha256-bCZesSKgkarofFAVd51gfZTGKlBCkoLTmQave8krO5A=";
  };

  cargoSha256 = "sha256-7+YsEwPc2oRwRJ7DENuGpYZ4v3POWvgUs77TIz1HbFs=";

  meta = with lib; {
    description = "X11 XTEST reimplementation primarily for Steam Controller on Wayland";
    homepage = "https://github.com/Supreeeme/extest";
    license = licenses.mit;
    maintainers = with maintainers; [ pongo1231 ];
    platforms = platforms.linux;
  };
})
