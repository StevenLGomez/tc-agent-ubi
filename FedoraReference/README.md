
# Podman Container in Container reference image

Reference github [repository](https://github.com/containers/podman/tree/main/contrib/podmanimage/stable)

5dc8074 Nov 13, 2023

--------

**Created branch: fedora-ref**   
In directory *FedoraReference*  
```
# Build & container
podman build -t tc:f01 .

```

--------
Test rootless behavior using examples from Brian Smith, Red Hat Principal Technical Account Manager   

Reference [video](https://www.youtube.com/watch?v=ZgXpWKgQclc)
--------

**Test standard user -> root inside**   
```
# Start container instance 
podman run -d --name fedora-rootinside tc:f01  tail -f /dev/null

# Enter container shell
podman exec -it fedora-rootinside /bin/bash

# In container shell
whoami             # Shows root 
id                 # Shows root id information
sleep 1000 &       # Start background process in container
exit               # Return to host

# In host shell, confirm container task ownership
ps -ef | grep "sleep 1000" | grep -v grep        # Shows 'developer' user

# Display task uid 
ps -ef n | grep "sleep 1000" | grep -v grep      # Shows uid 1000 (matching developer)
```

**Test standard user -> NON-root inside**   
```
# Start container instance 
podman run -d --name fedora-rootless --user sync tc:f01 tail -f /dev/null

# Enter container shell
podman exec -it fedora-rootless /bin/bash

# In container shell
whoami             # Shows sync 
id                 # Shows sync id information
sleep 1500 &       # Start background process in container

grep sync /etc/passwd     # In container, sync user is uid 5

exit               # Return to host

# In host shell, confirm container task ownership
ps -ef | grep "sleep 1500" | grep -v grep        # Shows running as 100000 + (5 - 1) 

# Display task uid 
ps -ef n | grep "sleep 1500" | grep -v grep      # Shows same uid as above 
```

**Test (built in ) podman user -> NON-root inside**   
```
# Start container instance 
podman run -d --name pm-rootless --user podman tc:f01 tail -f /dev/null

# Enter container shell
podman exec -it pm-rootless /bin/bash

# In container shell
whoami             # Shows podman 
id                 # Shows uid=1000(podman) gid=1000(podman) groups=1000(podman)
sleep 2000 &       # Start background process in container

grep podman /etc/passwd     # In container, podman user is uid 1000

exit               # Return to host

# In host shell, confirm container task ownership
ps -ef | grep "sleep 2000" | grep -v grep        # Shows running as 100999 (100000 + (1000 - 1))

# Display task uid 
ps -ef n | grep "sleep 2000" | grep -v grep      # Shows same uid as above 
```

**Test local directory volume - full rootless**   
```
# Start container instance 
podman system prune    # Remove previous container instances (that didn't have the volume attached)
cd ~/tmp
mkdir test-vol
vi test-vol/hello.txt  # Add some simple text

# In ~/tmp working directory
podman run -d --name vtest --user podman --volume ./test-vol:/home/podman tc:f01 tail -f /dev/null

podman exec -it vtest /bin/bash
# /home/podman owned by root inside

podman stop vtest
podman system prune

# Add --rm to allow restarting without removing previous container
podman run -it --rm --name vtest --user podman --volume ./test-vol:/home/podman tc:f01 /bin/bash
# /home/podman owned by root inside

podman run -it --rm --name vtest --volume ./test-vol:/home/podman tc:f01 /bin/bash
sleep 999 &

# On host
ps -ef | grep "sleep 999" | grep -v grep
develop+    8088    8068  0 14:09 pts/0    00:00:00 sleep 999

# Minor change, create hostvol inside container.
podman run -it --rm --user podman --name vtest --volume ./test-vol:/home/podman/hostvol tc:f01 /bin/bash
# /home/podman/hostvol can be entered, but it is owned by root inside the container.

# Add the SELINUX :Z flag (allow container write permission, for THIS container only)
podman run -it --rm --user podman --name vtest --volume ./test-vol:/home/podman/hostvol:Z tc:f01 /bin/bash

# On host
sudo useradd podman          # Running above, hoostvol still owned by root

podman run -it --rm --user podman --name vtest --device=/dev/fuse --volume ./test-vol:/home/podman/hostvol:Z tc:f01 /bin/bash

sudo chown -R 101000:101000 test-vol/
# hostvol owned by 1001:1001

sudo chown -R 100999:100999 test-vol/
podman run -it --rm --user podman --name vtest --device=/dev/fuse --volume ./test-vol:/home/podman/hostvol:Z tc:f01 /bin/bash
# The above seems to work, it was possible to change file in the test volume

```



