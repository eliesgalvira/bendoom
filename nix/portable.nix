{ lib, stdenv, runCommand, closureInfo, patchelf, coreutils, util-linux, alsa-lib, bendoom, variant ? "shareware" }:

let
  inherit (lib.filesystem) baseNameOf;
  inherit (lib.lists) optionals singleton;
  inherit (lib.strings) optionalString removeSuffix;

  linux = stdenv.hostPlatform.isLinux;
  runtime = closureInfo {
    rootPaths = singleton bendoom.game ++ optionals linux [ bendoom.alsa-plugins coreutils ];
  };
  name = "bendoom-${variant}-${stdenv.hostPlatform.system}";
in
runCommand "${name}.tar.gz" {
  nativeBuildInputs = optionals linux [ patchelf util-linux ];
} /* bash */ ''
  mkdir -p bundle/bin bundle/share
  cp ${bendoom.game}/bin/program bundle/bin/game
  cp ${bendoom.iwad} bundle/share/doom.wad
  cp ${../LICENSE} bundle/LICENSE
  cp ${../README.md} bundle/README.md
  cp -r ${removeSuffix "/share/games/doom/${baseNameOf bendoom.iwad}" bendoom.iwad}/share/doc bundle/share/doc
  ${optionalString linux /* bash */ ''
    mkdir bundle/lib
    printf '%s\n' bundle/bin/game bundle/bin/basenc > elf-files
    while IFS= read -r path; do
      if [ -d "$path/lib" ]; then
        while IFS= read -r -d ''' library; do
          [ "$(head -c 4 "$library")" = $'\177ELF' ] || continue
          target="bundle/lib/$(basename "$path")/''${library#"$path/"}"
          install -Dm755 "$library" "$target"
          printf '%s\n' "$target" >> elf-files
        done < <(find -L "$path/lib" -type f -name '*.so*' -print0)
      fi
    done < ${runtime}/store-paths
    cp "$(patchelf --print-interpreter bundle/bin/game)" bundle/bin/ld.so
    cp ${coreutils}/bin/basenc bundle/bin/basenc
    mkdir bundle/lib/alsa-lib
    for plugin in ${bendoom.alsa-plugins}/*.so; do
      target="bundle/lib/alsa-lib/$(basename "$plugin")"
      cp -L "$plugin" "$target"
      printf '%s\n' "$target" >> elf-files
    done
    ln -s ${baseNameOf "${bendoom.alsa-plugins.client}"}/lib/spa-0.2 bundle/lib/spa-0.2
    ln -s ${baseNameOf "${bendoom.alsa-plugins.client}"}/lib/pipewire-0.3 bundle/lib/pipewire-0.3
    cp -r ${bendoom.alsa-plugins.client}/share/pipewire bundle/share/pipewire
    cp -r ${alsa-lib}/share/alsa bundle/share/alsa
    chmod -R u+w bundle
    while IFS= read -r elf; do
      relative=$(realpath --relative-to="$(dirname "$elf")" bundle/lib)
      rpath=$(patchelf --print-rpath "$elf")
      rpath=''${rpath//\/nix\/store\//\$ORIGIN\/$relative\/}
      patchelf --set-rpath "$rpath" "$elf"
    done < elf-files
    patchelf --set-interpreter /unused bundle/bin/game
    patchelf --set-interpreter /unused bundle/bin/basenc
    hardlink -c bundle/lib
  ''}
  cat ${./portable.sh} ${./launch.sh} > bundle/bendoom
  chmod +x bundle/bendoom
  mkdir -p $out
  tar --sort=name --mtime=@1 --owner=0 --group=0 --numeric-owner --mode=u+w -czf $out/${name}.tar.gz -C bundle .
''
