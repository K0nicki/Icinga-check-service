# Icinga check service by name plugin
<a href="https://icinga.com/"><img src="https://warlord0blog.files.wordpress.com/2020/06/icinga2_logo.png?w=712" width="200"/></a>

Icinga is Nagios forked monitoring tool. This repository contains script written in Powershell for monitoring specified Windows process

## Check-service-by-name.ps1

### Synopsis
   Check-service-by-name.ps1 - let's check what's going on
### Description
   The script checks CPU and RAM usage by the service which name is given as the parameter
### Example
```
   check-service-by-name.ps1  
    -s <YOUR_SERVICE>  
    -cpu_warn 10  
    -cpu_crit 20  
    -mem_warn 10  
    -mem_crit 20  
    -mem_warn_bytes 2000  
    -mem_crit_bytes 4000
```

Only service name parameter is required. If threshold parameters are not specified, script will always quit with OK status

---

<small> *Visit the [Icinga] home page.*

[Icinga]: https://icinga.com/
