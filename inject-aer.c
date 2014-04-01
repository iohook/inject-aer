#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "util.h"

#define CMD_LN	1024
#define PCI_DEVFN(slot, func)   ((((slot) & 0x1f) << 3) | ((func) & 0x07))


void emulate_comm(int domain, int bus, int dev, int func, int flags, int sev)
{
	char *cmd, *p;
	FILE *pipe;
	int err = 0;
	int rootd, rootbus, rootdev, rootfunc;
	int root_aer, dev_aer, rests, ests, sourceid, irq;

	cmd = malloc(CMD_LN);
	sprintf(cmd, "find /sys/devices -name %04x:%02x:%02x.%01x", domain, bus, dev, func);
	pipe = popen(cmd, "r");
	if (!pipe) {
		err = -1;
		goto err;
	}

	if (fgets(cmd, CMD_LN, pipe) == NULL) {
		err = -2;
		goto err2;
	}

	p = strstr(cmd, "pci");
	if (!p) {
		err = -3;
		goto err2;
	}
	p = strchr(p, '/');
	if (!p) {
		err = -4;
		goto err2;
	}

	p++;
	sscanf(p, "%04x:%02x:%02x.%x", &rootd, &rootbus, &rootdev, &rootfunc);
	printf("found root port at:%x|%x:%x.%x\n", rootd, rootbus, rootdev, rootfunc);

	pclose(pipe);
	sprintf(cmd, "lspci -v | sed -n '/%02x:%02x.%x/,/Kernel/p' |grep 'Advanced Error'", bus, dev, func);
	pipe = popen(cmd, "r");
	if (!pipe) {
		err = -5;
		goto err2;
	}

	if (fgets(cmd, CMD_LN, pipe) == NULL) {
		err = -6;
		goto err2;
	}
	p = strstr(cmd, "Capabilities");
	if (!p) {
		err = -7;
		goto err2;
	}
	p = strchr(p, '[');
	if (!p) {
		err = -8;
		goto err2;
	}

	p++;
	/* AER capability offset of the device */
	dev_aer = strtol(p, NULL, 16);

	pclose(pipe);
	sprintf(cmd, "lspci -v | sed -n '/%02x:%02x.%x/,/Kernel/p' |grep 'Advanced Error'", rootbus, rootdev, rootfunc);
	pipe = popen(cmd, "r");
	if (!pipe) {
		err = -9;
		goto err2;
	}

	if (fgets(cmd, CMD_LN, pipe) == NULL) {
		err = -10;
		goto err2;
	}
	p = strstr(cmd, "Capabilities");
	if (!p) {
		err = -11;
		goto err2;
	}
	p = strchr(p, '[');
	if (!p) {
		err = -12;
		goto err2;
	}

	p++;
	/* AER capability offset of the root port */
	root_aer = strtol(p, NULL, 16);

	printf("root port aer at:0x%x, dev aer at: 0x%x\n", root_aer, dev_aer);

	switch (sev) {
	case E_CORRECTED:
		rests = 1;
		break;
	case E_UNCORRECTED:
		rests = (1 << 2) | (1 << 5);
		break;
	case E_FATAL:
		rests = (1<< 2) | (1 << 6);
		break;
	default:
		err = -13;
		printf("Incorrect sev passed in \n");
		goto err2;
	}

	sourceid = (bus << 8) | PCI_DEVFN(dev, func);
	ests = flags;
	/* pciconf overrides */
	sprintf(cmd, "echo \"%04x|%02x:%02x.%x+%x-1[%x/f]wc " /* Root Error (30h) */
		"%04x|%02x:%02x.%x+%x-2[%x/ffff]ro "   /* source id (34h) */
		"%04x|%02x:%02x.%x+%x-4[%x/ffffffff]wc " /* cor/unc status */
		"%04x|%02x:%02x.%x+%x-4[%x/ffffffff]rw\" " /* cor/unc mask */
		"> %s/pciconf",
		rootd, rootbus, rootdev, rootfunc, root_aer+0x30, rests,
		rootd, rootbus, rootdev, rootfunc, root_aer+0x34,  sourceid,
		domain, bus, dev, func, dev_aer + (sev == E_CORRECTED?0x10:0x04),
		ests,
		domain, bus, dev, func, dev_aer + (sev == E_CORRECTED?0x14:0x08),
		0, /* unmask all errors */
		IOHOOK_DIR);
	pclose(pipe);

	/* execute the cmd */
	pipe = popen(cmd, "r");
	if (!pipe) {
		err = -14;
		goto err2;
	}

	pclose(pipe);
	sprintf(cmd, "cat $(find /sys/devices -name '%04x:%02x:%02x.%x')/irq", rootd, rootbus, rootdev, rootfunc);
	pipe = popen(cmd, "r");
	if (!pipe) {
		err = -15;
		goto err2;
	}

	if (fgets(cmd, CMD_LN, pipe) == NULL) {
		err = -16;
		goto err2;
	}

	irq = atoi(cmd);
	if (!irq) {
		err = -17;
		goto err2;
	}

	pclose(pipe);
	sprintf(cmd, "echo %d > %s/irq", irq, IOHOOK_DIR);
	pipe = popen(cmd, "r");
	if (!pipe) {
		err = -18;
		goto err2;
	}

	pclose(pipe);
	sprintf(cmd, "echo 1 > %s/trigger", IOHOOK_DIR);
	pipe = popen(cmd, "r");
	if (!pipe) {
		err = -11;
		goto err2;
	}
err2:
	pclose(pipe);
err:
	if (err)
		printf("error %d: Failed command: %s\n", err, cmd);
	free(cmd);

}

void emulate_cor(int domain, int bus, int dev, int func, int flags)
{

	emulate_comm(domain, bus, dev, func, flags, E_CORRECTED);
}

void emulate_uncor(int domain, int bus, int dev, int func, int flags, int sev)
{
	emulate_comm(domain, bus, dev, func, flags, sev);

}
