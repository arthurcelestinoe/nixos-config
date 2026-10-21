{ ashyterm }:
final: _prev:
let
  # Compatibilidade temporária com a exigência uv_build<0.12 do Ashy.
  # Versão e hashes provenientes do Nixpkgs.
  uvBuildForAshy = final.python3Packages.uv-build.overridePythonAttrs (_: {
    version = "0.11.28";

    src = final.fetchFromGitHub {
      owner = "astral-sh";
      repo = "uv";
      tag = "0.11.28";
      hash = "sha256-/mTH2hojC+l0yxn+LEAIj8FTA/nWKIPZ7uLMVJxebw4=";
    };

    cargoDeps = final.rustPlatform.fetchCargoVendor {
      pname = "uv-build";
      version = "0.11.28";

      src = final.fetchFromGitHub {
        owner = "astral-sh";
        repo = "uv";
        tag = "0.11.28";
        hash = "sha256-/mTH2hojC+l0yxn+LEAIj8FTA/nWKIPZ7uLMVJxebw4=";
      };

      hash = "sha256-FvLl32JfIq5a1NnLtnFJyy5T+vkcOD+qfQLDy6NYhHg=";
    };
  });
in
{
  freedownloadmanager =
    final.callPackage ../packages/freedownloadmanager.nix { };

  ashy-terminal =
    ashyterm.packages.${final.stdenv.hostPlatform.system}.ashyterm-all.override {
      python3Packages = final.python3Packages // {
        uv-build = uvBuildForAshy;
      };
    };
}
