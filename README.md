# tc-agent-ubi

Container build and deploy project to support non-root container based agents for TeamCity

### Experimentation with user permission issues

```
# Using config for Agent A
podman run -it --rm --user tc_agent --name ubitest --volume ./config-A:/data/teamcity_agent/conf:Z ubi:001 /bin/bash

touch /data/teamcity_agent/conf/buildAgent.properties  # In Container, permission denied
exit

# On host
sudo chown -R 101000:101000 config-A   # Nope, needs to have offset of user running the container

# Retried using 'developer' offset
sudo chown -R 100999:100999 config-A   # Success, can now touch files /data/teamcity_agent/conf

# Podman failed due to expecting /home/tc_agent to be writeable
# Reverting name throughout to be 'developer'

sudo userdel --remove tc_agent   # OK
sudo userdel --remove podman     # Failed, processes still attached

sudo killall -u podman           # Then userdel worked.

podman run -it --rm --user developer --name ubitest --volume ./config-A:/data/teamcity_agent/conf:Z ubi:001 /bin/bash







```



