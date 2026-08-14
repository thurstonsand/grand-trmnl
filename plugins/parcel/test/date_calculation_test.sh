#!/usr/bin/env bash
set -euo pipefail

root="$(git rev-parse --show-toplevel)"
gem_home="$(mise where 'gem:trmnl_preview')/libexec"
ruby="$(mise which ruby)"

GEM_HOME="$gem_home" GEM_PATH="$gem_home" "$ruby" "$root/plugins/parcel/test/date_calculation_test.rb"
