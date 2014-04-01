Inject-aer can inject PCIE errors into the Linux kernel by using I/O Hook
to emulate h/w events. More information about I/O Hook can be found at
https://github.com/iohook/kernel. Inject-aer can parses the trace event
output of /sys/kernel/debug/tracing/events/ras/aer_event, and regenerate the
same errors. It can be used to test the PCIE AER handler in Linux kernel.

To use it, the kernel needs to include the patches of I/O Hook and be compiled
with CONFIG_IO_HOOK=y. An existing trace event output of aer_event is requied.

bash# cat input.txt
...
kworker/29:1-421   [029] .... 344952.758437: aer_event: 0000:03:00.0 PCIe Bus
 Error: severity=Corrected, Bad TLP|Receiver Error| Bad DLLP|RELAY_NUM Rollover
|Advisory Non-Fatal
kworker/29:1-421   [029] .... 344952.758437: aer_event: 0000:00:02.0 PCIe Bus
 Error: severity=Uncorrected, non-fatal, Flow Control Protocol |ECRCReceiver
 Overflow|Unsupported Request
...

To regenerate the same event(s), do

bash # echo 1 > /sys/kernel/debug/tracing/events/ras/enable
bash # ./inject-aer input.txt

If successful, the same event(s) will appear in /sys/kernel/debug/tracing/trace

The offical source code for inject-aer can be found at
https://github.com/iohook/inject-aer.git

Authors:

Rui Wang

Copyright 2014 by Intel Corporation
   inject-aer is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public
   License as published by the Free Software Foundation; version
   2.

   inject-aer is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   General Public License for more details.

   You should find a copy of v2 of the GNU General Public License somewhere
   on your Linux system; if not, write to the Free Software Foundation,
   Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA


