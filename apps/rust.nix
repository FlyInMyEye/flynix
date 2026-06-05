{ ... }:

{
  home-manager.sharedModules = [
    ({ config, pkgs, ... }: {
      home.packages = with pkgs; [
        rustup
        cargo-edit
        cargo-watch
        cargo-audit
        cargo-outdated
        cargo-bloat
        cargo-expand
        cargo-flamegraph
        cargo-binutils
        cargo-deny
        cargo-udeps
        cargo-machete
        cargo-nextest
        cargo-criterion
        cargo-llvm-cov
        cargo-make
        cargo-release
        cargo-cross
        wasm-pack
        cargo-generate
      ];

      home.sessionVariables = {
        CARGO_HOME = "${config.home.homeDirectory}/.cargo";
        RUSTUP_HOME = "${config.home.homeDirectory}/.rustup";
      };

      home.file.".cargo/config.toml".text = ''
    [build]
    # Use all CPU cores for compilation
    jobs = 6

    [cargo-new]
    # Default author information
    name = "archbtw"
    email = "user@example.com"

    [registries.crates-io]
    protocol = "sparse"

    [net]
    # Use git2 for faster git operations
    git-fetch-with-cli = true

    [profile.dev]
    # Faster linking on Linux
    split-debuginfo = "unpacked"

    [profile.release]
    # Enable link-time optimization for smaller binaries
    lto = true
    # Enable all optimizations
    codegen-units = 1
    panic = "abort"

    [target.x86_64-unknown-linux-gnu]
    linker = "clang"
    rustflags = ["-C", "link-arg=-fuse-ld=lld"]
      '';
    })
  ];
}
