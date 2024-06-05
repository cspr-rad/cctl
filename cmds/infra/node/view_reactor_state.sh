#!/usr/bin/env bash

function _help() {
    echo "
    COMMAND
    ----------------------------------------------------------------
    cctl-infra-node-view-reactor-state

    DESCRIPTION
    ----------------------------------------------------------------
    Displays reactor status at specified node(s).

    ARGS
    ----------------------------------------------------------------
    node        Ordinal identifier of a node. Optional.

    DEFAULTS
    ----------------------------------------------------------------
    node        all
    "
}

function _main()
{
    local NODE_ID=${1}

    if [ "$NODE_ID" = "all" ]; then
        for NODE_ID in $(seq 1 "$CCTL_COUNT_OF_NODES")
        do
            if [ $(get_is_node_up "$NODE_ID") = true ]; then
                echo "------------------------------------------------------------------------------------------------------------------------------------"
                _display_reactor_state "$NODE_ID"
            fi
        done
        echo "------------------------------------------------------------------------------------------------------------------------------------"
    else
        if [ $(get_is_node_up "$NODE_ID") = true ]; then
            _display_reactor_state "$NODE_ID"
        else
            log_warning "node $NODE_ID is not running"
        fi
    fi
}

function _display_reactor_state()
{
    local NODE_ID=${1}

    local API_ENDPOINT="$(get_address_of_node_rest_server "$NODE_ID")"/status
    local API_RESPONSE=$(
        curl $CCTL_CURL_ARGS_FOR_NODE_RELATED_QUERIES --header 'Content-Type: application/json' \
            --location \
            --request GET "$API_ENDPOINT" \
            | jq '.reactor_state' \
            | sed -e 's/^"//' -e 's/"$//'
    )

    if [ -z "$API_RESPONSE" ]; then
        log "node #$NODE_ID reactor state: N/A"
    else
        log "node #$NODE_ID reactor state = $API_RESPONSE"
    fi
}

# ----------------------------------------------------------------
# ENTRY POINT
# ----------------------------------------------------------------

source "$CCTL"/utils/main.sh

unset _HELP
unset _NODE_ID

for ARGUMENT in "$@"
do
    KEY=$(echo "$ARGUMENT" | cut -f1 -d=)
    VALUE=$(echo "$ARGUMENT" | cut -f2 -d=)
    case "$KEY" in
        help) _HELP="show" ;;
        node) _NODE_ID=${VALUE} ;;
        *)
    esac
done

if [ "${_HELP:-""}" = "show" ]; then
    _help
else
    _main "${_NODE_ID:-"all"}"
fi
