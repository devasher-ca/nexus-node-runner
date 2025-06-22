# Node Runner - Nexus Edition

A Nexus-themed 2D platformer game built with **Godot 4.4+** for browser compatibility.

## 🚀 Game Overview

**Node Runner** is a 2D platformer where you collect compute shards to activate Nexus Nodes across the network. Solve pattern-matching puzzles to power up nodes and progress through increasingly challenging levels.

### 🎮 Core Gameplay

- **Collect Shards**: Gather glowing compute shards scattered throughout each level
- **Activate Nodes**: Use collected shards to power Nexus Nodes
- **Solve Puzzles**: Complete pattern-matching mini-games to activate nodes
- **Progress**: Complete all nodes in a level to advance to the next

### 🎯 Game Features

- **3 Challenging Levels** with increasing difficulty
- **Pattern-Matching Puzzles** with time limits
- **Nexus-Themed Visuals** with starfield backgrounds and glowing effects
- **Smooth Platformer Controls** with responsive movement and jumping
- **Browser-Compatible** HTML5 export with single-threaded support

## 🎨 Nexus Theme

The game reflects Nexus culture and values through:

- **Cyan/Blue Color Palette** reminiscent of Nexus branding
- **Compute Shard Collectibles** representing computational resources
- **Hexagonal Node Design** inspired by network topology
- **Proof-of-Work Puzzles** as pattern-matching challenges
- **Network Activation** metaphor for level progression

## 🕹️ Controls

| Action              | Keys                 |
| ------------------- | -------------------- |
| Move Left/Right     | `A`/`D` or `←`/`→`   |
| Jump                | `Space`, `W`, or `↑` |
| Interact with Nodes | `E`                  |
| Pause               | `Escape`             |

## 🏗️ Technical Architecture

### Core Scripts

- **`Player.gd`** - Character movement, shard collection, node interaction
- **`Shard.gd`** - Collectible compute shards with animations
- **`NexusNode.gd`** - Interactive nodes that trigger puzzles
- **`PuzzlePopup.gd`** - Pattern-matching mini-game logic
- **`HUD.gd`** - User interface and progress tracking
- **`GameManager.gd`** - Level management and game flow coordination

### Scene Structure

```
GameScene
├── GameManager (Main game logic)
├── Camera2D (Player following camera)
├── HUD (CanvasLayer - UI overlay)
├── PuzzlePopup (CanvasLayer - Puzzle interface)
└── Background (Parallax starfield)
```

## 🌐 Browser Compatibility

Optimized for HTML5 export with:

- **Single-threaded mode** for maximum browser compatibility
- **WebGL 2.0 rendering** via GL Compatibility mode
- **Responsive canvas** that adapts to browser window
- **No external dependencies** - pure GDScript implementation

## 🛠️ Development Setup

### Prerequisites

- **Godot 4.4+** (Download from [godotengine.org](https://godotengine.org))

### Running the Game

1. Clone this repository
2. Open `project.godot` in Godot
3. Press `F5` to run the game
4. Or press `F6` to run the MainMenu scene

### Building for Web

1. In Godot, go to **Project → Export**
2. Select the **Web** export preset
3. Click **Export Project**
4. Choose your build directory
5. Upload the generated files to a web server

## 🎲 Puzzle Design

The pattern-matching puzzles feature:

- **Binary Patterns** that players must replicate
- **Time Pressure** to add challenge
- **Visual Feedback** with Nexus-themed colors
- **Scalable Difficulty** across levels

Example puzzle flow:

1. Node shows target pattern (e.g., `1 0 1 1`)
2. Player clicks buttons to match pattern
3. Submit solution within time limit
4. Success activates the node, failure allows retry

## 🚀 Future Enhancements

Potential expansions could include:

- **Additional Puzzle Types** (sequence memory, logic gates)
- **More Levels** with unique mechanics
- **Sound Effects** and background music
- **Leaderboards** for fastest completion times
- **Mobile Controls** for touch devices

## 📄 License

This project is **open source** and available for the Nexus community to enjoy, modify, and extend.

## 🤝 Contributing

Feel free to:

- Report bugs or suggest improvements
- Add new puzzle types or levels
- Enhance visuals or add sound effects
- Optimize for different platforms

---

**Built with ❤️ for the Nexus community**

_Challenge yourself, activate the network, and become the ultimate Node Runner!_
