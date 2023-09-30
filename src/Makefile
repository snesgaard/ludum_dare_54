love_bin:=love

$(love_bin):
	make -C nodeworks download

download: $(love_bin)

play: build
	$(love_bin) .
	
test:
	$(love_bin) . test

build:
	make -C art


.PHONY: test
