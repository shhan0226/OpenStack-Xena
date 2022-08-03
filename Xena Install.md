# Xena Install
- 이 게시글은 ARM서버기반 OpenStack-Xena 설치 스크립트이다.

## Prerequisites
- Controller Node와 Compute Node 두개의 서버에 OpenStack을 설치를 기준으로 한다.
- 각 노드의 OS는 ubuntu20.04이다.


## Installation
1. Controller Node의 IP 및 환경설정
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

2. Controller Node의 OpenStack 설치시작 
```
cd OpenStack-Xena/controller-release
source start.sh
```

3. Interactive Input step.1 
- Default는 `[ENTER KEY]`, Passwd는 `{STACK_PASSWD}`
- `Is Compute Node installed?`가 발생하면 스크립트 진행을 멈추고, Compute Node의 Openstack 설치를 진행한다.

4. Compute Node의 IP 및 환경설정
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

5. Compute Node의 OpenStack 설치시작 
```
cd OpenStack-Xena/compute-release
source start.sh
```

6. Interactive Input step.2
- Default는 `[ENTER KEY]`
- `Are you going to install Neutron?`이 발생하면 스크립트 진행을 멈추고, 다시 Controller Node의 Openstack 설치를 진행한다.

7. Controller Node의 OpenStack 설치
- Compute Node의 Nova-Compute가 설치되면 다음 스크립트를 진행한다.
  - Compute Node가 정상적으로 동작하는지 확인한다.
- 나머지 스크립트를 진행한다.

8. Compute Node의 OpenStack 설치
- 나머지 스크립트를 진행한다.




