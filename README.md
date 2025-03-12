# Math Games Collection

A collection of educational math games developed with Godot 4, designed to make learning mathematics fun and interactive.

![Math Games Collection](https://github.com/user-attachments/assets/591ac29d-99a6-4ffd-92a2-67c23851040a)

---

## Play Online

The game is hosted online. Play it directly in your browser: [sugarlabs.pointblank.club](https://sugarlabs.pointblank.club)

---

## Games Included

### Four Color Map Game
Based on the four-color theorem in mathematics, this game challenges players to color a map using only four colors (Red, Blue, Green, Yellow) such that no adjacent regions share the same color.

![Four Color Map Game](https://github.com/user-attachments/assets/6336bd2e-f5c1-4614-9b71-b373e42e6f07)

**Features:**
- Generate new maps with varying complexity
- Color selection tools
- Eraser function for corrections
- Visual feedback on correct/incorrect coloring

### Broken Calculator
A puzzle game where players need to reach a target number using a calculator with limited or "broken" functionality.

![Broken Calculator](https://github.com/user-attachments/assets/8e5d40fe-bc7d-4e69-8dda-0ac2fa74ec80)

**Features:**
- Multiple difficulty levels (Easy, Medium, Hard)
- Target score system
- Tracks equations solved
- Toast messages added for vairous inputs. (Ex: Incorrect, Eq already used, Correct, etc.)

### Fifteen Puzzle
 A puzzle consisting of 15 squares, numbered 1 through 15, which can be slid horizontally or vertically within a four-by-four grid that has one empty space among its 16 locations. The object of the puzzle is to arrange the squares in numerical sequence using only the extra space in the grid to slide the numbered titles.

![Fifteen](https://github.com/user-attachments/assets/f4cda57b-c702-4c3e-b167-aa425f987e01)

**Features:**
- Varying difficulty modes : Easy (3x3), Medium (4x4), Hard (5x5) 
- Undo functionality 
- Time taken & Number of moves tracker to keep it engaging
- Visual slide animation on clicking a tile

##### More Games To Be Added Soon...

---

## Project Structure
```
./
├── Godot/            # Main Godot project files and assets
└── WebExport/       # Web export files including index.html
```

---

## Getting Started

### Prerequisites
- [Godot 4.x](https://godotengine.org/download/windows/) - Download and install the appropriate version for your operating system.

### Running the Game Locally
1. Clone this repository
2. Open Godot Engine
3. Click on "Import" and navigate to the `./Godot` directory
4. Open the project
5. Click the "Play" button in the top-right corner or press F5 to run the game

### Playing the Web Version Locally
Navigate to the `./WebExport` directory and open the `index.html` file in a modern web browser.