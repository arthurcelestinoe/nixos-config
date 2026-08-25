{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  dpkg,
  makeWrapper,
  xdg-utils,
  ffmpeg,
  bubblewrap,
  brotli,
  cairo,
  dbus,
  fontconfig,
  freetype,
  gdk-pixbuf,
  glib,
  gtk3,
  harfbuzz,
  krb5,
  libdrm,
  libglvnd,
  libpulseaudio,
  libxkbcommon,
  pango,
  wayland,
  xorg,
  libxcb,
  xcbutil,
  xcbutilcursor,
  xcbutilimage,
  xcbutilkeysyms,
  xcbutilrenderutil,
  xcbutilwm,
  zlib,
  zstd,
}:

stdenv.mkDerivation {
  pname = "freedownloadmanager";
  version = "6.34.4.6974";

  src = fetchurl {
    url = "https://files2.freedownloadmanager.org/6/latest/freedownloadmanager.deb";
    hash = "sha256-KZxb7xgLV4riI+A6EIJ5w7gOx/m84+F5JGnUbe4vxs0=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
    makeWrapper
  ];

  buildInputs = [
    brotli
    cairo
    dbus
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gtk3
    harfbuzz
    krb5
    libdrm
    libglvnd
    libpulseaudio
    libxkbcommon
    pango
    stdenv.cc.cc.lib
    wayland
    libX11
    libxcb
    xcbutil
    xcbutilcursor
    xcbutilimage
    xcbutilkeysyms
    xcbutilrenderutil
    xcbutilwm
    zlib
    zstd
  ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x "$src" .
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/opt" "$out/bin" "$out/share/applications" \
      "$out/share/icons/hicolor/256x256/apps"
    cp -a opt/freedownloadmanager "$out/opt/"

    # Estes plugins opcionais exigem versões específicas de clientes de banco
    # de dados e do libtiff do Ubuntu. O FDM não os usa para seus downloads.
    rm -f \
      "$out/opt/freedownloadmanager/plugins/imageformats/libqtiff.so" \
      "$out/opt/freedownloadmanager/plugins/sqldrivers/libqsqlibase.so" \
      "$out/opt/freedownloadmanager/plugins/sqldrivers/libqsqlmimer.so" \
      "$out/opt/freedownloadmanager/plugins/sqldrivers/libqsqlmysql.so" \
      "$out/opt/freedownloadmanager/plugins/sqldrivers/libqsqloci.so"  \
      "$out/opt/freedownloadmanager/plugins/sqldrivers/libqsqlodbc.so" \
      "$out/opt/freedownloadmanager/plugins/sqldrivers/libqsqlpsql.so"

    install -Dm644 usr/share/applications/freedownloadmanager.desktop \
      "$out/share/applications/freedownloadmanager.desktop"
    substituteInPlace "$out/share/applications/freedownloadmanager.desktop" \
      --replace-fail "/opt/freedownloadmanager/fdm" "fdm" \
      --replace-fail "/opt/freedownloadmanager/icon.png" "freedownloadmanager"

    install -Dm644 "$out/opt/freedownloadmanager/icon.png" \
      "$out/share/icons/hicolor/256x256/apps/freedownloadmanager.png"

    makeWrapper "$out/opt/freedownloadmanager/fdm" "$out/bin/fdm" \
      --prefix PATH : ${lib.makeBinPath [ xdg-utils ffmpeg bubblewrap ]} \
      --set-default QT_PLUGIN_PATH "$out/opt/freedownloadmanager/plugins"

    runHook postInstall
  '';

  # O executável principal e o host nativo encontram as bibliotecas privadas
  # pelo próprio RUNPATH. Os nomes abaixo pertencem apenas a plugins SQL que
  # não são necessários ao funcionamento do gerenciador.
  autoPatchelfIgnoreMissingDeps = [
    "libclntsh.so.23.1"
    "libfbclient.so.2"
    "libmimerapi.so"
    "libmysqlclient.so.21"
    "libtiff.so.5"
  ];

  meta = {
    description = "Gerenciador e acelerador de downloads Free Download Manager";
    homepage = "https://www.freedownloadmanager.org/";
    license = lib.licenses.unfree;
    mainProgram = "fdm";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
