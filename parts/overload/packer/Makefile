
all: output/00.raw output/99.raw

output/00.raw: packer.py
	python packer.py 2>&1 > log_packer.txt
	tail -n 30 log_packer.txt
