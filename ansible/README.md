[//]: # (Time-stamp: <2024-07-18 07:25:32 UTC liman>)

# Ansible Configuration For Lab Servers

The Ansible configuration here was used to support setting
up lab servers in Google Cloud. The Ansible scripts do *not*
comprise all necessary additions and changes to make things
work, but they provide support for some of the more tedious
tasks.

To run a full playbook on all hosts, do

```
ansible-playbook -b -i hosts playbooks/hackathon.yml
```
