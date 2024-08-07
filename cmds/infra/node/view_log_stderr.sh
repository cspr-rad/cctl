#!/usr/bin/env bash

function _help() {
    echo "
    COMMAND
    ----------------------------------------------------------------
    cctl-infra-node-view-log-stderr

    DESCRIPTION
    ----------------------------------------------------------------
    Displays a node's error log file.

    ARGS
    ----------------------------------------------------------------
    node        Ordinal identifier of a node. Optional.
    filter      Filter with which to grep log. Optional.

    DEFAULTS
    ----------------------------------------------------------------
    node        1
    "
}

function _main()
{
    local NODE_ID=${1}
    local FILTER=${2}

    if [ "$FILTER" = "" ]; then
        less "$(get_path_to_node "${NODE_ID}")"/logs/node-stderr.log
    else
        less "$(get_path_to_node "${NODE_ID}")"/logs/node-stderr.log | grep $FILTER
    fi
}

# ----------------------------------------------------------------
# ENTRY POINT
# ----------------------------------------------------------------

source "$CCTL"/utils/main.sh

unset _FILTER
unset _HELP
unset _NODE_ID

for ARGUMENT in "$@"
do
    KEY=$(echo "$ARGUMENT" | cut -f1 -d=)
    VALUE=$(echo "$ARGUMENT" | cut -f2 -d=)
    case "$KEY" in
        filter) _FILTER=${VALUE} ;;
        help) _HELP="show" ;;
        node) _NODE_ID=${VALUE} ;;
        *)
    esac
done

if [ "${_HELP:-""}" = "show" ]; then
    _help
else
    _main "${_NODE_ID:-1}" "$_FILTER"
fi
