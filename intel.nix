{ pkgs
, fetchgit
, libglvnd
, llvmPackages
, libclc
, glslang
, cmake
, ...
}: {
  nixpkgs.overlays = [
    /*
      (self: super: {
      mesa = super.mesa.overrideAttrs (finalAttrs: previousAttrs: {
        version = "22.3.0";
        enableOpenCL = false;

        src = super.fetchgit {
          url = "https://gitlab.freedesktop.org/mesa/mesa.git";
          rev = "479eb67aacf4df4562156b497cf4fd50d93e421e";
          sha256 = "GMT+zRsAZdzxoDXYYPvQYCJZV4LViQrZKqSKCveR0Ys=";
        };

        patches = [
          ./mesa/opencl.patch
          ./mesa/disk_cache-include-dri-driver-path-in-cache-key.patch
        ];

        /*
        postPatch =
        previousAttrs.postPatch
        or ""
        + ''
          substituteInPlace meson.build --replace "prog_glslang = find_program('glslangValidator')" ""
          substituteInPlace meson.build --replace "if run_command(prog_glslang, [ '--quiet', '--version' ], check : false).returncode() == 0" "if true"
        '';
        *

        buildInputs =
          previousAttrs.buildInputs
          or []
          ++ [
            super.libclc
            super.glslang
          ];

        mesonFlags = [
          "--sysconfdir=/etc"
          "--datadir=${placeholder "drivers"}/share" # Vendor files

          # Don't build in debug mode
          # https://gitlab.freedesktop.org/mesa/mesa/blob/master/docs/meson.html#L327
          "-Db_ndebug=true"

          "-Ddisk-cache-key=${placeholder "drivers"}"
          "-Ddri-search-path=${super.libglvnd.driverLink}/lib/dri"

          "-Dplatforms=x11,wayland"
          "-Dgallium-drivers=auto"
          "-Dvulkan-drivers=auto"

          "-Ddri-drivers-path=${placeholder "drivers"}/lib/dri"
          "-Dvdpau-libs-path=${placeholder "drivers"}/lib/vdpau"
          "-Domx-libs-path=${placeholder "drivers"}/lib/bellagio"
          "-Dva-libs-path=${placeholder "drivers"}/lib/dri"
          "-Dd3d-drivers-path=${placeholder "drivers"}/lib/d3d"
          "-Dgallium-nine=true" # Direct3D in Wine
          "-Dosmesa=true" # used by wine
          "-Dmicrosoft-clc=disabled" # Only relevant on Windows (OpenCL 1.2 API on top of D3D12)

          # To enable non-mesa gbm backends to be found (e.g. Nvidia)
          "-Dgbm-backends-path=${super.libglvnd.driverLink}/lib/gbm:${placeholder "out"}/lib/gbm"
          "-Dglvnd=true"
          #"-Dgallium-opencl=icd" # Enable the gallium OpenCL frontend
          #"-Dclang-libdir=${super.llvmPackages.clang-unwrapped.lib}/lib"
        ];
      });
      })
    */
  ];

  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };

  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [ intel-media-driver ];
  };

  #services.xserver.videoDrivers = ["intel"];
}
