{
  stdenv,
  fetchFromGitHub,
  meson, ninja, pkg-config,
  libglvnd, libpng, libjpeg,
  wayland, wayland-protocols,
  libX11, libXrandr,
}:

stdenv.mkDerivation rec {
  pname = "neowall";
  version = "0.4.6";

  src = fetchFromGitHub {
    owner = "1ay1";
    repo = "neowall";
    rev = "v${version}";
    hash = "sha256-esI7m5V6ISpoXllLNjb52TdVMKel4FKOKPa40n3rofo=";
  };

  nativeBuildInputs = [ meson ninja pkg-config ];
  buildInputs = [ libglvnd libpng libjpeg wayland wayland-protocols libX11 libXrandr ];

  meta.mainProgram = "neowall";
}
