# tflint: the bundled terraform ruleset (recommended preset) is enough for this repo
# and needs no plugin download.
config {
  call_module_type = "local"
}

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}
