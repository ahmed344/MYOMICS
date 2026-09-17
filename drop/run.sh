#!/usr/bin/env bash
# Launch DROP 1.6.1 FRASER2 then OUTRIDER inside the docker_drop.sh container.
#
# Usage (after: bash docker_drop.sh):
#   bash /workspace/drop/run.sh dryrun
#   bash /workspace/drop/run.sh fraser      # aberrantSplicing / FRASER2
#   bash /workspace/drop/run.sh outrider    # aberrantExpression / OUTRIDER
#   bash /workspace/drop/run.sh all         # fraser then outrider
#   bash /workspace/drop/run.sh init        # drop init only
set -euo pipefail

DROP_DIR="/workspace/drop"
PROFILE="${DROP_DIR}/profiles/drop"
MODE="${1:-}"

usage() {
    echo "Usage: bash /workspace/drop/run.sh {init|dryrun|fraser|outrider|all}" >&2
    echo "Run this inside the DROP container started by docker_drop.sh." >&2
}

require_container() {
    local missing=()
    local exe
    for exe in drop snakemake STAR samtools; do
        if ! command -v "${exe}" >/dev/null 2>&1; then
            missing+=("${exe}")
        fi
    done
    if ((${#missing[@]})); then
        echo "Missing on PATH: ${missing[*]}" >&2
        echo "Start the DROP image with docker_drop.sh first; do not run this on the host." >&2
        exit 1
    fi
}

prepare_writable_home() {
    local home_root="${HOME:-/tmp/myomics_home}"
    mkdir -p \
        "${home_root}" \
        "${home_root}/.cache" \
        "${home_root}/.config" \
        "${home_root}/R" \
        "${home_root}/tmp"
    export R_LIBS_USER="${R_LIBS_USER:-${home_root}/R}"
    export TMPDIR="${TMPDIR:-${home_root}/tmp}"
}

init_drop_project() {
    cd "${DROP_DIR}"
    if [[ -d .drop ]]; then
        echo "DROP project already initialized (${DROP_DIR}/.drop)."
        return 0
    fi
    echo "Running drop init in ${DROP_DIR} (does not overwrite config.yaml)."
    drop init
}

run_snakemake() {
    cd "${DROP_DIR}"
    snakemake --profile "${PROFILE}" "$@"
}

require_container
prepare_writable_home

case "${MODE}" in
    init)
        init_drop_project
        ;;
    dryrun)
        init_drop_project
        run_snakemake -n aberrantSplicing
        run_snakemake -n aberrantExpression
        ;;
    fraser)
        init_drop_project
        run_snakemake aberrantSplicing
        ;;
    outrider)
        init_drop_project
        run_snakemake aberrantExpression
        ;;
    all)
        init_drop_project
        run_snakemake aberrantSplicing
        run_snakemake aberrantExpression
        ;;
    "")
        usage
        exit 1
        ;;
    *)
        echo "Unknown mode: ${MODE}" >&2
        usage
        exit 1
        ;;
esac
