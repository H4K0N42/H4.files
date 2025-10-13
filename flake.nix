{
  description = "My dotfiles";
  outputs = { self, nixpkgs }: {
    # expose the files directory
    defaultPackage.x86_64-linux = ./.;
  };
}
