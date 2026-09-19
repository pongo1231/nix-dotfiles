obj-m += adios.o

# ADIOS is a blk-mq elevator, so it needs the kernel's private block/ headers
# (elevator.h, blk.h, blk-mq.h, blk-mq-sched.h). Those are not installed with
# the kernel headers, so take them from the kernel build tree's source.
ccflags-y += -I$(srctree)/source/block -I$(srctree)/block

KDIR ?= /lib/modules/$(shell uname -r)/build

all:
	+$(MAKE) -C $(KDIR) M=$(CURDIR) modules

clean:
	+$(MAKE) -C $(KDIR) M=$(CURDIR) clean
