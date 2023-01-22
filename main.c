#include <iostream>
#include <cstdio>

int main() {
	FILE* disk = fopen("SDcontents.bin", "r+b");
	if (disk == NULL) {
		fprintf(stderr, "bench.cpp:55: PANIC! Disk image \"SDcontents.bin\" not found!\nAbborting\n");
		exit(1);
	}
	uint64_t buffer, seek;
	fflush(disk);
	fseek(disk, seek, SEEK_SET);
	buffer = 0;
	if (fread(&buffer, 8, 1, disk) != 1)
		cout << "Errot while reading size " << (int) top->size << " at " << seek << endl;
	top->data = buffer;
		cout << "read of size " << (int) top->size << " at " << seek << " = " << buffer << endl;

	return 0;
}
