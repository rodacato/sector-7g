# Sector 7-G template — non-secret env so Kamal can RENDER config/deploy*.yml locally.
#
# Copy to the app repo as .devcontainer/kamal-env.sh, then tailor:
#   - <APP_UPPER> = the repo name upper-cased (DOJO, STOCKERLY): it names a shell
#     variable, so `<APP>` lower-cased would give you `dojo_ROOT`.
#   - Keep only the derivations this repo's deploy config actually reads: the ERB
#     in config/deploy*.yml is the authority on which vars must exist.
# This file is SOURCED by every shell (post-create.sh wires it into the rc files).
# It must stay side-effect free and safe to source twice.
#
# Real secrets never live here. A deploy runs in GitHub Actions, which injects them
# from the "production" GitHub Environment. Delete this header block when done.

: "${<APP_UPPER>_ROOT:=$(git rev-parse --show-toplevel 2>/dev/null)}"
[ -n "${<APP_UPPER>_ROOT:-}" ] || return 0 2>/dev/null || exit 0

# GitHub Actions sets these for free; locally, derive them from the git remote so
# the common case needs no config at all.
if [ -z "${GITHUB_REPOSITORY:-}" ]; then
  _kamal_slug="$(git -C "$<APP_UPPER>_ROOT" config --get remote.origin.url 2>/dev/null |
    sed -E 's#^(git@[^:]+:|https?://[^/]+/)##; s#\.git$##')"
  [ -n "$_kamal_slug" ] && export GITHUB_REPOSITORY="$_kamal_slug"
  unset _kamal_slug
fi

# Owner only — for configs that interpolate the registry account
# (GITHUB_ACTOR in some repos, GITHUB_USERNAME in others; match yours).
[ -z "${GITHUB_ACTOR:-}" ] && [ -n "${GITHUB_REPOSITORY:-}" ] &&
  export GITHUB_ACTOR="${GITHUB_REPOSITORY%%/*}"

if [ -r "$<APP_UPPER>_ROOT/.devcontainer/local.env" ]; then
  set -a
  . "$<APP_UPPER>_ROOT/.devcontainer/local.env"
  set +a
fi
