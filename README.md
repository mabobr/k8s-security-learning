# Intro:
  - learning by scripting ;)
  - this is a bunch of scripts to run k8s setup and various security realated testcases

# Next
2024-mar-24:
- finish network policies - test labeling, 
  question: will policy open, if i label namespace AFTER policy apply?
  play w/ p;olicies, write down take-away

- continue:  section 2 lesson 19 at time: 0:0
- configure containerd to use proxy setup: 
  https://medium.com/@gargankur74/setting-up-standalone-kubernetes-cluster-behind-corporate-proxy-on-ubuntu-16-04-1f2aaa5a848
  https://stackoverflow.com/questions/77318225/how-to-configure-proxy-in-kubernetes-to-pull-images
  

# Done:
  - works w/ PROXY
  - POD-POD communication tested
  - firewalld for calico network - all POD-POD is allowed
  - setup and proxy tests.
  - output tcp port 443 may be blocked via variable to force http proxy usage
  - cluster is up and running, nodes Ready, network added (cilium)
  - vagrant will create 3 VMs (proxy may be added later)
  - k8s master is initialized
