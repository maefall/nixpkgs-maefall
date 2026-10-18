{ lib, stdenv, fetchzip, fetchurl
, rustPlatform, pkg-config
, pnpm, nodejs
, gtk3, webkitgtk_4_1, librsvg, libayatana-appindicator
, dbus, mpv, openssl, glib-networking, gsettings-desktop-schemas
, autoPatchelfHook, makeWrapper, ...
}:
let
  pname = "limusic";
  version = "1.3.0-rc.8";
  rev = "0b6d18dfe016da9c7cf76301653b887cf37fe87b";

  src = fetchzip {
    url = "https://github.com/SimoHypers/limusic/archive/${rev}.tar.gz";
    hash = "sha256-1+lhzQqm/aLMPlmgMLA1iS8iSNmYxD539x4485nut9A=";
  };

  v8Archive = fetchurl {
    url = "https://github.com/denoland/rusty_v8/releases/download/v130.0.7/librusty_v8_release_x86_64-unknown-linux-gnu.a.gz";
    hash = "sha256-pkdsuU6bAkcIHEZUJOt5PXdzK424CEgTLXjLtQ80t10=";
  };

  ipadicSrc = fetchurl {
    url = "https://github.com/lindera-morphology/mecab-ipadic/archive/refs/tags/2.7.0-20070801.tar.gz";
    hash = "sha256-CZ5G6A1V58DWkGeDr/cTdI4a6Q9Gxe+W7BU7vwm/VVA=";
  };

  pnpmDeps = pnpm.fetchDeps {
    sourceRoot = "source/ui";
    pnpm = pnpm;
    fetcherVersion = 1;
    inherit pname src;
    hash = "sha256-cQBJLoYlQf6Q/eL8WI08uzl/F16RK1Ncyo7LsuduWk4=";
  };

in rustPlatform.buildRustPackage {
  inherit pname version src;

  cargoHash = "sha256-kks81RoV1qXyT+CI4yMHGxx2E+gVoYyriuflsyhKm1s=";
  doCheck = false;

  pnpmRoot = "ui";
  pnpmDeps = pnpmDeps;

  preBuild = ''
    export LINDERA_IPADIC_URL="${ipadicSrc}"
    export RUSTY_V8_ARCHIVE="${v8Archive}"
    cd ui && pnpm build && cd ..
  '';

  postPatch = ''
    lindera_rs=$(find "$cargoDepsCopy" -path "*/lindera-ipadic*/build.rs" -print -quit)
    if [ -n "$lindera_rs" ]; then
      sed -i "/Download a tarball/,/dest.flush()/c\
            // Copy pre-fetched dictionary tarball\\
            std::fs::copy(std::env::var(\"LINDERA_IPADIC_URL\").unwrap(), \&tmp_path)?;" \
        "$lindera_rs"
    fi
  '';

  nativeBuildInputs = [
    nodejs
    pkg-config
    rustPlatform.cargoSetupHook
    pnpm.configHook
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    gtk3 webkitgtk_4_1 librsvg
    libayatana-appindicator dbus
    mpv openssl
    glib-networking gsettings-desktop-schemas
  ];

  postInstall = ''
    mv "$out/bin/limusic-app" "$out/bin/limusic"
    wrapProgram "$out/bin/limusic" \
      --set GIO_MODULE_DIR "${glib-networking}/lib/gio/modules" \
      --set GIO_EXTRA_MODULES "${glib-networking}/lib/gio/modules" \
      --set XDG_DATA_DIRS "$GSETTINGS_SCHEMAS_PATH"
  '';

  meta = {
    description = "Desktop YouTube Music client with listen-together, lyrics, and visualizations";
    homepage = "https://github.com/SimoHypers/limusic";
    license = lib.licenses.gpl3Plus;
    platforms = [ "x86_64-linux" ];
    mainProgram = "limusic";
  };
}
