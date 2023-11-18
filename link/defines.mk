#check if dasm and acme are present systemwide
#ACME_EXE := $(shell command -v acme 2> /dev/null)
#DASM_EXE := $(shell command -v dasm 2> /dev/null)
#DALI_EXE := $(shell command -v dali 2> /dev/null)
X64_EXE  := $(shell command -v x64 2> /dev/null)

#gather all needed commands
ifndef X64_EXE
X64 := x64sc
else
X64 := x64
endif

ifndef ACME_EXE
ACME := $(abspath $(BASEDIR)/util/acme/acme)
else
ACME := acme
endif
ifndef DASM_EXE
DASM := $(abspath $(BASEDIR)/util/dasm/dasm)
else
DASM := dasm
endif
ifndef DALI_EXE
PACKER := $(abspath $(BASEDIR)/bitfire/packer/dali/dali)
else
PACKER := dali
endif

D64WRITE := $(abspath $(BASEDIR)/bitfire/d64write/d64write)
CRTWRITE := $(abspath $(BASEDIR)/bitfire/crtwrite/crtwrite)
KICKASS_JAR := $(BASEDIR)/util/kickass/KickAss.jar
JAVA := java

NODE := node

KICKASSOPT :=
ifdef crt
KICKASSOPT += -define crt
endif
ifdef release
KICKASSOPT += -define release :link_exit=$(link_exit)
endif

ACMEOPT := -v1 -f cbm
ifdef crt
ACMEOPT += -Dcrt=1
endif
ifdef release
ACMEOPT += -Drelease=1 -Dlink_exit=$(link_exit)
endif

DASMOPT := -t2 -p8 -v0
ifdef crt
DASMOPT += -Dcrt=1
endif
ifdef release
DASMOPT += -Drelease=1 -Dlink_exit=$(link_exit)
endif

CFLAGS := -Wall
LDLIBS := -lpng -lm
CC := gcc

PACKER_FLAGS :=
D64WRITE_FLAGS := -v

CHARCONV := $(abspath $(BASEDIR)/util/charconv/convert)
SPRITECONV := $(abspath $(BASEDIR)/util/spriteconv/convert)
