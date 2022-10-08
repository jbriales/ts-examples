#!/usr/bin/env bats

load /usr/local/lib/bats-support/load.bash
load /usr/local/lib/bats-assert/load.bash

@test "full ts project" {
  cd "$BATS_TEST_TMPDIR"

  tsc --init

  mkdir src
  cat <<EOF >src/main.ts
import {foo} from 'foo.ts'
EOF

  cat <<EOF >src/foo.ts
export function foo() {}
EOF

  ts-node --swc src/main.ts
}

@test "mjs file importing ts module" {
  cd "$BATS_TEST_TMPDIR"

  tsc --init
  # NOTE: The defaults from `tsc --init` are quite different to my own

  mkdir src
  cat <<EOF >src/main.mjs
import {foo} from 'foo.ts'
EOF

  cat <<EOF >src/foo.ts
export function foo() {}
EOF

  # ts-node fails here when the main is mjs:
  run ts-node --swc src/main.mjs
  assert_failure 1
  assert_output --partial "Error [ERR_MODULE_NOT_FOUND]: Cannot find package 'foo.ts' imported from"

  # ts-node-esm still fails
  run ts-node-esm --swc src/main.mjs
  assert_failure 1
  assert_output --partial "CustomError: Cannot find package 'foo.ts' imported from"

  # Modify the tsconfig:
  cat <<EOF >tsconfig.json
{
  "compilerOptions": {
    "outDir": "./built",
    "allowJs": true,
    "target": "ES2022"
  },
  "include": [
    "./src/**/*"
  ],
  "ts-node": {
    "swc": true
  }
}
EOF

  # Now it works with `ts-node-esm`:
  run ts-node-esm --swc src/main.mjs
  assert_success

  # But still not w/ normal `ts-node`:
  run ts-node --swc src/main.mjs
  assert_failure 1
  assert_output --partial "Error [ERR_MODULE_NOT_FOUND]: Cannot find package 'foo.ts' imported from"
}