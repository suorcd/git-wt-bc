{
  description = "A utility to clone a git repo into a clean bare + worktree structure";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      # Systems to support
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      # Helper to generate outputs for all systems
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # The script logic
      scriptName = "gwbc";
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.writeShellApplication {
            name = scriptName;

            # Dependencies available to the script at runtime
            runtimeInputs = [
              pkgs.git
              pkgs.coreutils
            ];

            text = ''
              # Fail on error, undefined vars, or pipe failures
              set -euo pipefail

              if [ -z "''${1:-}" ]; then
                  echo "Usage: ${scriptName} <repo-url> [directory-name]"
                  exit 1
              fi

              REPO_URL="$1"
              # Use 2nd argument as dir name, or derive from URL
              DIR_NAME="''${2:-$(basename "$REPO_URL" .git)}"

              echo "🟢 Setting up Bare Worktree Environment for: $DIR_NAME"

              # 1. Create the container directory
              mkdir -p "$DIR_NAME"

              # Enter main directory
              pushd "$DIR_NAME" > /dev/null

                  # 2. Clone the repo as a bare repo named '.git'
                  # This makes the folder structure look like a standard repo to tools
                  # but keeps the working directory clean.
                  echo "⬇️  Cloning bare repository..."
                  git clone --bare "$REPO_URL" .git

                  # Enter the bare repo to configure it
                  pushd .git > /dev/null
                      echo "⚙️  Configuring refspecs..."
                      
                      # Force tracking of all remote heads to local heads
                      git config remote.origin.fetch "+refs/heads/*:refs/heads/*"
                      
                      # Fetch all branches based on new config
                      git fetch origin
                  
                  # Exit bare repo
                  popd > /dev/null

                  # 3. Determine default branch
                  # We check the bare repo's HEAD
                  HEAD_REF=$(git --git-dir=.git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null || echo "")
                  DEFAULT_BRANCH=$(basename "$HEAD_REF")

                  if [ -z "$DEFAULT_BRANCH" ]; then
                      echo "⚠️  Could not detect default branch. Defaulting to 'main'."
                      DEFAULT_BRANCH="main"
                  fi

                  # 4. Create the primary worktree
                  echo "checking out worktree for $DEFAULT_BRANCH..."
                  git --git-dir=.git worktree add "$DEFAULT_BRANCH"

              # Exit main directory
              popd > /dev/null

              echo "✅ Setup Complete!"
              echo "   Bare Repo: $DIR_NAME/.git"
              echo "   Worktree:  $DIR_NAME/$DEFAULT_BRANCH"
            '';
          };
        }
      );

      # Expose as an app so you can run `nix run`
      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/${scriptName}";
        };
      });
    };
}
