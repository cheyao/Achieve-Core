STARTUP(build/start.o)

MEMORY {
    RAM (rxx) : ORIGIN = 0, LENGTH = 0x1800
}


SECTIONS {
   everything : {
	  . = ALIGN(4);
	  build/start.o (.text)
     *(.*)
   } > RAM
}
