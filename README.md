# Intro:
  - learning by scripting ;)
  - this is a bunch of scripts to run k8s setup and various security realated testcases

# Next
2024-mar-21: continue:  section 2 lesson 16 at time: 7:04 continue with network policies.
- finish test w/ network policy deny - file is already present
- aftert net-policy test, return to PROXY: seems to be more complicated then onliner, check https://www.arhea.net/posts/2020-06-16-kubernetes-http-proxies/
- configure containerd to use proxy setup: 
  https://medium.com/@gargankur74/setting-up-standalone-kubernetes-cluster-behind-corporate-proxy-on-ubuntu-16-04-1f2aaa5a848
  https://stackoverflow.com/questions/77318225/how-to-configure-proxy-in-kubernetes-to-pull-images
  

# Done:
  - POD-POD communication tested
  - firewalld for calico network - all POD-POD is allowed
  - setup and proxy tests.
  - output tcp port 443 may be blocked via variable to force http proxy usage
  - cluster is up and running, nodes Ready, network added (cilium)
  - vagrant will create 3 VMs (proxy may be added later)
  - k8s master is initialized
