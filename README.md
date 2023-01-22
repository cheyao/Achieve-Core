# Achieve Core

RISC-V (rv64i) SOC for ![AchieveOS](https://github.com/cheyao/AchieveOS)

I do not promise I've done everything corrrectly, so is something looks wrong, it is wrong!

I decided to make the main storage unit a sdcard

MMIO:
| Start              | End                | Usage                   |
|--------------------|--------------------|-------------------------|
| 0x0000000000000000 | 0xFFFFFFFEFFFFFFFF | RAM                     |
| 0xFFFFFFFF00000000 | 0xFFFFFFFF000C0000 | Screen memory           |
| 0xFFFFFFFF000C0000 | 0xFFFFFFFF000C0001 | SD data                 |
| 0xFFFFFFFF000C0001 | 0xFFFFFFFF000C0002 | SD addr                 |
| 0xFFFFFFFF000C0002 | 0xFFFFFFFF000C0003 | SD status + command     |
| 0xFFFFFFFF000C0003 | 0xFFFFFFFF000C0004 | UART data               |
| 0xFFFFFFFF???????? | 0xFFFFFFFFFFFF0000 | Reserved for future use |
| 0xFFFFFFFFFFFF0000 | 0xFFFFFFFFFFFFFFFF | BIOS                    |

### TODO list

Still got a lot to do!

- [x] RISC-V Core
- [ ] Achieve BIOS
- [ ] VGA lines and stuff 
- [ ] Printf <-- Version 0.0.1

# SD protocol

SD status meanings:
| Mask   | Description    |
|--------|----------------|
| 0x0001 | Data ready     |
| 0x0002 | SDcard present |
