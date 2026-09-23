{ pkgs, ... }:

{
  home.packages = [
    # CMake 4.4 prevents Lean 4.30 from forwarding its install prefix to stage1.
    # TODO: Remove this override once the pinned lean4 includes
    # https://github.com/leanprover/lean4/pull/14411 and builds without it.
    (pkgs.lean4.overrideAttrs (old: {
      cmakeFlags = (old.cmakeFlags or [ ]) ++ [
        "-DSTAGE1_CMAKE_INSTALL_PREFIX=${builtins.placeholder "out"}"
      ];
    }))
  ];
}
