# Intro:
  - learning by scripting ;)
  - this is a bunch of scripts to run k8s setup and various security realated testcases

# Next
2024-mar-13:
- connect from POD to POD does not work, try harder
- PROXY seems to be more complicated then onliner, check https://www.arhea.net/posts/2020-06-16-kubernetes-http-proxies/
- rebuild VM /wo PROXY, finish network policies, then return and do it w/ PROXY
- continue section 2 lesson 16 at time: 7:04 continue with network policies.
- rebuild VMs wo/
- configure containerd to use proxy setup: 
  https://medium.com/@gargankur74/setting-up-standalone-kubernetes-cluster-behind-corporate-proxy-on-ubuntu-16-04-1f2aaa5a848
  https://stackoverflow.com/questions/77318225/how-to-configure-proxy-in-kubernetes-to-pull-images
  

# Done:
  - setup and proxy tests.
  - output tcp port 443 may be blocked via variable to force http proxy usage
  - cluster is up and running, nodes Ready, network added (cilium)
  - vagrant will create 3 VMs (proxy may be added later)
  - k8s master is initialized
