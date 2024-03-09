# Intro:
  - learning by scripting ;)
  - this is a bunch of scripts to run k8s setup and various security realated testcases

# Next
2024-mar-07:
- skip firewalld, nftables - we are runngin wo/
  - alter, when cluster is setup, try to blok outgoing 443 port and use proxy 
  - implement nqinx and proxy configuration
- continue /w test after setup

# Done:
  - cluster is up and running, nodes NotReady
  - vagrant will create 3 VMs (proxy may be added later)
  - k8s master is initialized
