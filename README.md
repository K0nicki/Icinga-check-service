
  
  

# Icinga check service by name plugin

<a  href="https://icinga.com/"><img  src="https://warlord0blog.files.wordpress.com/2020/06/icinga2_logo.png?w=712"  width="200"/></a>

  

Icinga is Nagios forked monitoring tool. This repository contains script written in Powershell for monitoring specified Windows process

  

# Table of contents

*  [Check-service-by-name.ps1](#check-service-by-nameps1)

+  [Synopsis](#synopsis)

+  [Description](#description)

+  [Example](#example)

*  [Icinga2 configuration](#icinga2-configuration)

+  [Command](#command)

+  [Service](#service)

  

---

# Check-service-by-name.ps1

  

### Synopsis

Check-service-by-name.ps1 - let's check what's going on

### Description

The script checks CPU and RAM usage by the service which name is given as the parameter

### Example

```powershell

check-service-by-name.ps1

-s Chrome

-cpu_warn 10

-cpu_crit 20

-mem_warn 10

-mem_crit 20

-mem_warn_bytes 2000

-mem_crit_bytes 4000

```

  

Only service name parameter is required.

The reverse flag allows monitoring processes that should not consume less resources than a given threshold

  
  

# Icinga2 configuration

  

### Command

```powershell

object CheckCommand "ps-check-service-by-name" {

command = [ "C:\\Windows\\system32\\WindowsPowerShell\\v1.0\\powershell.exe" ]

  

arguments = {

"-command" = {

value = "$ps_check_service_path$"

required = true

}

"-service" = {

value = "$ps_check_service_name$"

required = true

}

"-cpu_warn" = {

set_if = "$ps_check_service_cpu_warn$"

value = "$ps_check_service_cpu_warn$"

}

"-cpu_crit" = {

set_if = "$ps_check_service_cpu_crit$"

value = "$ps_check_service_cpu_crit$"

}

"-mem_warn" = {

set_if = "$ps_check_service_mem_warn$"

value = "$ps_check_service_mem_warn$"

}

"-mem_crit" = {

set_if = "$ps_check_service_mem_crit$"

value = "$ps_check_service_mem_crit$"

}

"-mem_warn_bytes" = {

set_if = "$ps_check_service_mem_crit_bytes$"

value = "$ps_check_service_mem_crit_bytes$"

}

"-mem_crit_bytes" = {

set_if = "$ps_check_service_mem_crit_bytes$"

value = "$ps_check_service_mem_crit_bytes$"

}

"-reverse" = {

set_if = "$ps_check_service_reverse$"

}

";exit" = {

value = "$$LastExitCode"

}

}

  

vars.ps_check_service_path = "C:\\'Program Files'\\ICINGA2\\sbin\\check_service_by_name.ps1"

vars.ps_check_service_name = "$ps_check_service_by_name_name$"

vars.ps_check_service_mem_warn = "$ps_check_service_by_name_mem_warn$"

vars.ps_check_service_mem_crit = "$ps_check_service_by_name_mem_crit$"

vars.ps_check_service_cpu_warn = "$ps_check_service_by_name_cpu_warn$"

vars.ps_check_service_cpu_crit = "$ps_check_service_by_name_cpu_crit$"

vars.ps_check_service_mem_warn_bytes = "$ps_check_service_by_name_mem_warn_MB$"

vars.ps_check_service_mem_crit_bytes = "$ps_check_service_by_name_mem_crit_MB$"

vars.ps_check_service_reverse = "$ps_check_service_reverse$"

}

  

```

  

### Service

  

```powershell

apply Service "service" {

import "generic-service"

  

display_name = "service usage"

check_command = "ps-check-service-by-name"

enable_notifications = false

  

vars.ps_check_service_by_name_name = "service name"

vars.ps_check_service_by_name_cpu_warn = 10

vars.ps_check_service_by_name_cpu_crit = 20

vars.ps_check_service_by_name_mem_warn = 10

vars.ps_check_service_by_name_mem_crit = 20

vars.ps_check_service_by_name_mem_warn_MB = 2000

vars.ps_check_service_by_name_mem_crit_MB = 4000

  

command_endpoint = host.name

  

assign where host.address

}

```

  

---


## Visualization
<img  src="https://github.com/K0nicki/Icinga-check-service/blob/main/img/serviceExampleImg.png"  width="1000"/>

  

<small> *Visit the [Icinga] home page.*

  

[Icinga]: https://icinga.com/
