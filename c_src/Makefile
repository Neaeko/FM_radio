SHELL = /bin/sh

OBJS = main.o fm_radio.o audio.o
CC = g++

all:
	touch audio_dump.bin
	touch audio_output.txt
	touch audio_trimmed.txt
	$(CC) fm_radio.cpp audio.cpp main.cpp -o fm_radio
	./fm_radio test/usrp.dat
	hexdump -C audio_dump.bin > audio_output.txt
	python3 clean.py

radio:
	$(CC) fm_radio.cpp audio.cpp main.cpp -o fm_radio

all_data:
	touch audio_dump.bin
	touch audio_output.txt
	touch audio_trimmed.txt
	./fm_radio test/usrp.dat
	hexdump -C audio_dump.bin > audio_output.txt
	python3 clean.py

bin:
	touch audio_dump.bin
	./fm_radio test/usrp.dat

hex:
	touch audio_output.txt
	hexdump -C audio_dump.bin > audio_output.txt

trim: 
	touch audio_trimmed.txt
	python3 clean.py

clean:
	-rm *.bin *.txt

