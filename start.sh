
AGENT_IMAGE=quay.io/el_guapo/tc-agent-ubi:20240118A
# AGENT_IMAGE=ubi:001

function ShowUsageInformation
{
    echo "ERROR: Missing parameter - must specify container IDentifier"
    echo ""
    echo "Supported Options:"
    echo "    [01 - 10] Agent containers intended to run on Production Server"
    echo "    - OR -"
    echo "    [A - C]   Agent containers intended to run on Prototype Server"
    echo ""
    echo "Usage: $0 <ID>"
    echo ""
}

# =============================================================================
# =============================================================================
# Script execution starts below
# =============================================================================
# =============================================================================

# Requires one parameter
# $1 = Container IDentifier
if [ -z "$1" ]
then
    ShowUsageInformation
    exit
fi

AGENT_ID=$1
AGENT_NAME=container-${AGENT_ID}

# Echo the valid command line entry
echo $0 $1
echo 'Starting ' ${AGENT_NAME}

# sudo podman run -d --name ${AGENT_NAME}                      \
# podman run --rm -it --name ${AGENT_NAME}                     \
# podman run --detach --user tc_agent                             \
#    --env SERVER_URL=http://usstlbas01:8111                     \
#    --env SERVER_URL=http://usstlbas02:8111                     \
#    --env SERVER_URL=http://10.1.1.21:8111                      \

#    --cap-add=sys_admin,mknod --device=/dev/fuse --security-opt label=disable \
#    --privileged                                                \
#    --detach                                                    \
#    --rm -it                                                    \
#    --user developer                                            \

podman run                                                      \
    --detach                                                    \
    --privileged                                                \
    --user developer                                            \
    --name ${AGENT_NAME}                                        \
    --env AGENT_NAME=${AGENT_NAME}                              \
    --env SERVER_URL=http://usstlbas01:8111                     \
    --volume ./config-${AGENT_ID}:/data/teamcity_agent/conf:U   \
    ${AGENT_IMAGE} 

