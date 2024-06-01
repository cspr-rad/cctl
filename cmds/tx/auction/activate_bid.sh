#!/usr/bin/env bash

function _help() {
    echo "
    COMMAND
    ----------------------------------------------------------------
    cctl-tx-auction-activate-bid

    DESCRIPTION
    ----------------------------------------------------------------
    Activates a bid within the system auction contract.

    ARGS
    ----------------------------------------------------------------
    node            Either ordinal identifier of a running node or random. Optional.
    validator       Ordinal identifier of target validator.

    DEFAULTS
    ----------------------------------------------------------------
    node            random
    "
}

function _main()
{
    local NODE_ID=${1}
    local VALIDATOR_ID=${2}

    local CHAIN_NAME=$CCTL_NET_NAME
    local GAS_PAYMENT=$CCTL_DEFAULT_GAS_PAYMENT
    local NODE_ADDRESS
    local PATH_TO_CLIENT=$(get_path_to_node_client)
    local PATH_TO_CONTRACT="$(get_path_to_assets)/bin/activate_bid.wasm"
    local TX_HASH
    local VALIDATOR_ACCOUNT_KEY=$(get_account_key "$CCTL_ACCOUNT_TYPE_NODE" "$VALIDATOR_ID")
    local VALIDATOR_SECRET_KEY=$(get_path_to_secret_key "$CCTL_ACCOUNT_TYPE_NODE" "$VALIDATOR_ID")

    if [ "$NODE_ID" == "random" ]; then
        NODE_ADDRESS=$(get_node_address_rpc)
    elif [ "$NODE_ID" -eq 0 ]; then
        NODE_ADDRESS=$(get_node_address_rpc)
    else
        NODE_ADDRESS=$(get_node_address_rpc "$NODE_ID")
    fi

    log_break
    log "dispatching auction tx -> activate_bid.wasm"
    log_break
    log "chain = $CHAIN_NAME"
    log "dispatch node = $NODE_ADDRESS"
    log "path to contract wasm = $PATH_TO_CONTRACT"
    log_break
    log "bidder id = $VALIDATOR_ID"
    log "bidder account key = $VALIDATOR_ACCOUNT_KEY"
    log_break

    TX_HASH=$(
        $PATH_TO_CLIENT put-deploy \
            --chain-name "$CHAIN_NAME" \
            --node-address "$NODE_ADDRESS" \
            --payment-amount "$GAS_PAYMENT" \
            --ttl "5minutes" \
            --secret-key "$VALIDATOR_SECRET_KEY" \
            --session-arg "$(get_cl_arg_account_key 'validator_public_key' "$VALIDATOR_ACCOUNT_KEY")" \
            --session-path "$PATH_TO_CONTRACT" \
            | jq '.result.deploy_hash' \
            | sed -e 's/^"//' -e 's/"$//'
        )

    log "tx hash = $TX_HASH"
    log_break
}

# ----------------------------------------------------------------
# ENTRY POINT
# ----------------------------------------------------------------

source "$CCTL"/utils/main.sh

unset _HELP
unset _NODE_ID
unset _VALIDATOR_ID

for ARGUMENT in "$@"
do
    KEY=$(echo "$ARGUMENT" | cut -f1 -d=)
    VALUE=$(echo "$ARGUMENT" | cut -f2 -d=)
    case "$KEY" in
        help) _HELP="show" ;;
        node) _NODE_ID=${VALUE} ;;
        validator) _VALIDATOR_ID=${VALUE} ;;
        *)
    esac
done

if [ "${_HELP:-""}" = "show" ]; then
    _help
else
    _main \
        "${_NODE_ID:-"random"}" \
        "$_VALIDATOR_ID"
fi
