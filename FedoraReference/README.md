
# Podman Container in Container reference image

Reference [repository](https://github.com/containers/podman/tree/main/contrib/podmanimage/stable)

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




