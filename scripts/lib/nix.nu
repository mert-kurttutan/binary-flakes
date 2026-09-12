export def replace-version [content: string, version: string] {
  $content | str replace --regex 'version = "[^"]+"' $"version = \"($version)\""
}

export def replace-binding-hash [content: string, binding: string, hash: string] {
  mut in_binding = false
  mut replaced = false
  mut output = []
  for line in ($content | lines) {
    if ($line | str starts-with $"  ($binding) = ") { $in_binding = true }
    if $in_binding and (not $replaced) and ($line | str contains "hash = ") {
      $output = ($output | append ($line | str replace --regex 'hash = "[^"]+"' $"hash = \"($hash)\""))
      $replaced = true
    } else { $output = ($output | append $line) }
    if $in_binding and ($line | str trim) == "else null;" { $in_binding = false }
  }
  ($output | str join "\n") + "\n"
}

export def replace-map-hash [content: string, map: string, key: string, hash: string] {
  mut in_map = false
  mut replaced = false
  mut target = false
  mut output = []
  for line in ($content | lines) {
    if ($line | str contains $"($map) = {") { $in_map = true; $replaced = false }
    if $in_map and (not $replaced) and ($line | str contains $"\"($key)\"") {
      $output = ($output | append ($line | str replace --regex '= "[^"]+"' $"= \"($hash)\""))
      $replaced = true
    } else if $in_map and (not $replaced) and ($line | str starts-with $"    ($key) = {") {
      $output = ($output | append $line)
      $target = true
    } else if $target and ($line | str contains "hash = ") {
      $output = ($output | append ($line | str replace --regex 'hash = "[^"]+"' $"hash = \"($hash)\""))
      $replaced = true
      $target = false
    } else { $output = ($output | append $line) }
    if $in_map and ($line | str starts-with "  };") { $in_map = false }
  }
  ($output | str join "\n") + "\n"
}
