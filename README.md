# Vault & Forwarded-For Support

Related to [Vault Github Issue: 9651](https://github.com/hashicorp/vault/issues/9651). Vault 1.5.0 (going as far back as 1.4.1) was tested at the time of authoring and the setup script (`5.install_vault.sh`) will attempt to install what's the latest at the time of execution. 

**PS** - adjust resources (cpu & ram) detailed in `Vagrantfile` if things are a bit too slow.

## Makeup & Concept

When launched - URLs & IPs include:
 - HAProxy via **name**: [http://vault.somewhere.local:60100/](http://vault.somewhere.local:60100/) - OR **direct** - [http://192.168.178.199:60100](http://192.168.178.199:60100)
 - Vault UI via **LB**: [http://vault.somewhere.local](http://vault.somewhere.local:60100/) - OR **direct w/o LB** [http://192.168.178.176:8200](http://192.168.178.176:8200) 

HTTPS should also work and is ready to be enabled on Vault (if needed).


```
          xFF_IP1      xFF_IP2  
          🌍           🌍       
      💻--||--     💻--||--     
  ...    / \  ...     / \  ...
  ________________________________________
            TLS    ╲        ╲ 
     connections    ╲        ╲
                      ╔╦══════════════╦.199
                      ║ load-balancer  ║
      backend         ║   (haproxy)    ║
  ,=============.     ╚╩══════════════╩╝
  |   servers   |             ║
  |.-----------.|             ▼
  || v1, v2, … || ◄ ════ ◄ ═══╝
  |'-----------'|
  |||||||||||||||
  |=============|
   v1 = vault1, etc...
```


## Quick setup

```bash
# // ON LOCAL-MACHINE - add LB HOST / IP entry
printf "192.168.178.199 vault.somewhere.local\n" | sudo tee -a /etc/hosts ;

vagrant up ;
```


### ~~1. **Bug / Issue** - X-Forwarded-For is neglected & has no effect~~

Works as expected where [`x_forwarded_for_reject_not_authorized` and `x_forwarded_for_reject_not_present`](https://www.vaultproject.io/docs/configuration/listener/tcp#x_forwarded_for_reject_not_authorized) are set as part of the listener stanza.

```bash
vagrant ssh haproxy ;
# vagrant@haproxy:~$ \
sudo tcpdump -q -A -i eth1 dst 'port 8200' ;
  # // ^^ for seeing outgoing x-forwarded-for VS its on health checks without it.

vagrant ssh haproxy ;
# vagrant@haproxy:~$ \
cat vault_init.json
  # // ^^ VAULT TOKEN

# // ON LOCAL-MACHINE - try VAULT STATUS
VAULT_ADDR=http://192.168.178.176:8200 vault status ;
  # // ^^ shoould NOT get response

# // ON LOCAL-MACHINE - try LB Address via browser & should get a response:
http://192.168.178.199  # OPEN IN BROWSER
```


### 2. **Feature / Enhancement** - Rate limiting (global or otherwise) NOT using X-Forwarded-For

```bash
# // From a few (two to four) differing IPs execute similar request at the same time concurrently:
printf "192.168.178.199 vault.somewhere.local\n" | sudo tee -a /etc/hosts ;
export VAULT_ADDR=http://vault.somewhere.local VAULT_TOKEN='………' ;

# // from SOURCE-1 IP approach Vault via its LB:
curl -X PUT -H "X-Vault-Token: ${VAULT_TOKEN}" -d '{"data":{"value":"………"}}' ${VAULT_ADDR}/v1/kv/data/test ;
# // ^^ repeat from another host at the same time:

# // from SOURCE-2 IP approach Vault via its LB:
curl -X PUT -H "X-Vault-Token: ${VAULT_TOKEN}" -d '{"data":{"value":"………"}}' ${VAULT_ADDR}/v1/kv/data/test ;
```


### 3. **Feature / Enhancement** - X-Forwarded-For support in in Audit Logs instead of remote_address IP being static.

```bash
sudo jq -r '.request.remote_address' /vaudit.log
  # ………
  # 192.168.178.199
  # 192.168.178.199
  # 192.168.178.199
  # ^^ all the same or own bind ip.
```


------
