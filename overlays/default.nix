{ ashyterm }:
final: _prev: {
  freedownloadmanager = final.callPackage ../packages/freedownloadmanager.nix { };
  ashy-terminal =
    ashyterm.packages.${final.stdenv.hostPlatform.system}.ashyterm-all.overrideAttrs
      (oldAttrs: {
        postInstall = (oldAttrs.postInstall or "") + ''
          substituteInPlace $out/bin/ashyterm \
            --replace-fail \
              'execute_ashy="python3 __init__.py"' \
              'execute_ashy="python3 -m ashyterm"'
        '';
      });
}