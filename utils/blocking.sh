#!/usr/bin/env bash

#######################################
# Awaits for the chain to proceed N eras.
# Arguments:
#   Future era offset to apply.
#######################################
function await_n_eras()
{
    local OFFSET=${1}
    local CURRENT
    local FUTURE

    CURRENT=$(get_chain_era)
    FUTURE=$((CURRENT + OFFSET))
    while [ "$CURRENT" -lt "$FUTURE" ];
    do
        sleep 10.0
        CURRENT=$(get_chain_era)
    done
}

#######################################
# Awaits for the chain to proceed N blocks.
# Arguments:
#   Future block height offset to apply.
#   Whether to log progress or not.
#   Node ordinal identifier.
#######################################
function await_n_blocks()
{
    local OFFSET=${1}
    local EMIT_LOG=${2:-false}
    local NODE_ID=${3:-''}

    local CURRENT
    local FUTURE

    # 60 second retry period to allow for network upgrades.
    CURRENT=$(get_chain_height "$NODE_ID" 60)
    if [ "$CURRENT" == "N/A" ]; then
        log "unable to get current block height using node $NODE_ID"
        exit 1
    fi
    FUTURE=$((CURRENT + OFFSET))

    while [ "$CURRENT" -lt "$FUTURE" ];
    do
        if [ "$EMIT_LOG" = true ]; then
            log "current block height = $CURRENT :: future height = $FUTURE ... sleeping 2 seconds"
        fi
        sleep 2.0
        CURRENT=$(get_chain_height "$NODE_ID" 60)
        if [ "$CURRENT" == "N/A" ]; then
            log "unable to get current block height using node $NODE_ID"
            exit 1
        fi
    done

    if [ "$EMIT_LOG" = true ]; then
        log "current block height = $CURRENT"
    fi
}

#######################################
# Awaits for the chain to proceed N eras.
# Arguments:
#   Future era offset to apply.
#   Whether to log progress or not.
#######################################
function await_until_era_n()
{
    local ERA=${1}
    local EMIT_LOG=${2:-false}

    # 60 second retry period to allow for network upgrades.
    while [ "$(get_chain_era '' 60)" -lt "$ERA" ]; do
        if [ "$EMIT_LOG" = true ]; then
            log "waiting for future era = $ERA ... sleeping 2 seconds"
        fi
        sleep 2.0
    done
}

#######################################
# Awaits for the chain to proceed N blocks.
# Arguments:
#   Future block offset to apply.
#######################################
function await_until_block_n()
{
    local HEIGHT=${1}

    # 60 second retry period to allow for network upgrades.
    while [ "$HEIGHT" -lt "$(get_chain_height '' 60)" ]; do
        sleep 10.0
    done
}

#######################################
# Awaits for a node to sync to genesis.
# Arguments:
#   Node ordinal identifier.
#   Timeout for function.
#######################################
function await_node_historical_sync_to_genesis() {
    local NODE_ID=${1}
    local SYNC_TIMEOUT_SEC=${2}

    log "awaiting node $NODE_ID to do historical sync to genesis"
    local WAIT_TIME_SEC=0
    local LOWEST=$(get_node_lowest_available_block "$NODE_ID")
    local HIGHEST=$(get_node_highest_available_block "$NODE_ID")
    while [ -z $HIGHEST ] || [ -z $LOWEST ] || [ $LOWEST -ne 0 ] || [ $HIGHEST -eq 0 ]; do
        log "node $NODE_ID lowest available block: $LOWEST, highest available block: $HIGHEST"
        if [ $WAIT_TIME_SEC -gt $SYNC_TIMEOUT_SEC ]; then
            log "ERROR: node 1 failed to do historical sync in ${SYNC_TIMEOUT_SEC} seconds"
            exit 1
        fi
        WAIT_TIME_SEC=$((WAIT_TIME_SEC + 1))
        sleep 5.0
        LOWEST=$(get_node_lowest_available_block "$NODE_ID")
        HIGHEST="$(get_node_highest_available_block "$NODE_ID")"
    done
}