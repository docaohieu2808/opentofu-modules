# Applies for real (random + local providers, no cloud) and cleans up afterwards.
run "writes_a_greeting_file" {
  command = apply

  assert {
    condition     = fileexists(output.file_path)
    error_message = "The greeting file must exist after apply"
  }

  assert {
    condition     = startswith(file(output.file_path), "hello, ${output.pet_name}")
    error_message = "File content must be '<greeting>, <pet name>'"
  }
}

run "greeting_is_configurable" {
  command = apply

  variables {
    greeting = "goodbye"
  }

  assert {
    condition     = startswith(file(output.file_path), "goodbye, ")
    error_message = "greeting variable must reach the file"
  }
}

run "invalid_greeting_is_rejected" {
  command = plan

  variables {
    greeting = "Hello World!"
  }

  expect_failures = [var.greeting]
}
