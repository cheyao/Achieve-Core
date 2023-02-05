# Achieve Core

RISC-V (rv64i) SOC for ![AchieveOS](https://github.com/cheyao/AchieveOS)

I do not promise I've done everything corrrectly, so is something looks wrong, it is wrong!

I decided to make the main storage unit a sdcard

MMIO:
| Start              | End                | Usage                   |
|--------------------|--------------------|-------------------------|
| 0x0000000000000000 | 0xFFFFFFFEFFFFFFFF | RAM                     |
| 0xFFFFFFFF00000000 | 0xFFFFFFFF000BFFFF | Screen memory           |
| 0xFFFFFFFF000C0000 | 0xFFFFFFFF000C0FFF | SD data                 |
| 0xFFFFFFFF000C1000 | 0xFFFFFFFF000C1000 | SD addr                 |
| 0xFFFFFFFF000C1001 | 0xFFFFFFFF000C1001 | SD status + command     |
| 0xFFFFFFFF000C1002 | 0xFFFFFFFF000C1002 | UART data               |
| 0xFFFFFFFF???????? | 0xFFFFFFFFFFFEFFFE | Reserved for future use |
| 0xFFFFFFFFFFFEFFFF | 0xFFFFFFFFFFFEFFFF | Debug print int         |
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

# Floating points
Floating points are still not implemented (cuz the IEEE 754 standerd is fucking useless)

Im gonna implement the posit floating points after
