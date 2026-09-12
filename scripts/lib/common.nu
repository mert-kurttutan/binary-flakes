export def require-command [name: string] {
  if (which $name | is-empty) { error make $"($name) is required but not installed" }
}

export def strip-prefix [value: string, prefix: string = "v"] {
  $value | str trim | str replace --regex $'^($prefix)' ''
}

export def current-version [package_file: string] {
  let versions = (open --raw $package_file | parse --regex 'version = "(?P<version>[^"]+)"' | get version)
  if ($versions | is-empty) { error make $"No version found in ($package_file)" }
  $versions | first
}

export def log-info [message: string] { print $"(ansi green)[INFO](ansi reset) ($message)" }
export def log-warn [message: string] { print $"(ansi yellow)[WARN](ansi reset) ($message)" }

export def ensure-repository-root [] {
  for file in [flake.nix] {
    if (not ($file | path exists)) { error make $"($file) not found; run from repository root" }
  }
}
