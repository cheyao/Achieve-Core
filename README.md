# Achieve Core

RISC-V (rv64i) SOC for ![AchieveOS](https://github.com/cheyao/AchieveOS)

I do not promise I've done everything corrrectly, so is something looks wrong, it is wrong!

MMIO:
0xFFFFFFFF0000000 - 0xFFFFFFFF000C0000 - Screen memory
0xFFFFFFFF00C0000 - 0xFFFFFFFF000C0001 - SD data
0xFFFFFFFF00C0001 - 0xFFFFFFFF000C0002 - SD command
0x??????????????? - 0x???????????????? - Reserved for future use
0xFFFFFFFFF000000 - 0xFFFFFFFFFFFFFFFF - BIOS
