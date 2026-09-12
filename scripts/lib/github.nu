use common.nu [require-command strip-prefix]

export def latest-tag [repository: string, prefix: string = "v"] {
  require-command gh
  let result = (^gh release view --repo $repository --json tagName -q '.tagName' | complete)
  if $result.exit_code != 0 { error make ($result.stderr | str trim) }
  strip-prefix $result.stdout $prefix
}

export def latest-manifest-version [url: string, field: string] {
  let response = (http get $url)
  let manifest = if (($response | describe) == "string") { $response | from json } else { $response }
  $manifest | get $field
}
