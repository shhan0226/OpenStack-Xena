# OpenStack-Xena
- This is an ARM server-based OpenStack-Xena installation script.

## Prerequisites
- It is based on installing OpenStack on two servers, Controller Node and Compute Node.
- The OS of each node is ubuntu20.04.


## Installation
1. Configuration of Controller Node
```
cd OpenStack-Xena/controller-release
vi start.sh
>
# Inpute Value
H_NAMEv="controller"    # hostname
SET_IPv="192.168.1.5"   # controller IP
SET_IP2v="192.168.1.6"  # compute IP
SET_IP_ALLOWv="192.168.0.0/22" # allow IP
INTERFACE_NAME_v="eth0" # interface
STACK_PASSWDv="stack"   # passwd 
```

2. Start the OpenStack installation of the Controller Node
```
cd OpenStack-Xena/controller-release
source start.sh
```

3. Interactive Input (step.1)
- Default is `[ENTER KEY]`, Passwd is `{STACK_PASSWD}`
- When `Is Compute Node installed?` occurs, stop input. (in Controller Node)
- Start the Openstack installation of Compute Node. (in Compute Node)

4.Configuration of Compute Node
```
cd OpenStack-Xena/compute-release
vi start.sh
>
# Inpute Value
H_NAMEv="compute1"    # hostname
SET_IPv="192.168.1.5"   # controller IP
SET_IP2v="192.168.1.6"  # compute IP
SET_IP_ALLOWv="192.168.0.0/22" # allow IP
INTERFACE_NAME_v="eth0" # interface
STACK_PASSWDv="stack"   # passwd 
```

5. Start the OpenStack installation of the Compute Node
```
cd OpenStack-Xena/compute-release
source start.sh
```

6. Interactive Input (step.2)
- Default is `[ENTER KEY]`
- When `Are you going to install Neutron?` occurs, stop input. (in Compute Node)
- Restart the Openstack installation of Controller Node. (in Controller Node) 


7. OpenStack Installation on Controller Node
- When Nova-Compute of Compute Node is installed, proceed with the following script.
  - Check if the Compute Node is operating normally.
- Proceed with the rest of the script.

8. Install OpenStack on Compute Node
- Proceed with the rest of the script.




