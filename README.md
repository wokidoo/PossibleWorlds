# PossibleWorlds

Inspired by [*A Force Dynamic Model of Narrative Agents*](https://ojs.aaai.org/index.php/AIIDE/article/view/18890/18655), this project aims to implement a system that would allow game developpers to simulate the ideals and perception of narrative agents for the Godot game engine.

## ✨ Features
- **PossibleWorld**: Each instance of PossibleWorld represents a set of propositions, each associated with a *bias* value ranging from -1 to 1 (disagree and agree respectively).
- **PossibleWorldMind**: An instance of an individual with both a perceived world and an ideal *PossibleWorld*. The former represents what an agent believes to be true while the latter represents what the same agent's wishes were true. These two worlds need not be in agreement and drives the internal tension calculated as the sum of the tension between each proposition within known to the agent.
- **PossibleWorldState**: A collection of *PossibleWorldMind*s that inhabit a world state. Manages all relevant agents (*PossibleWorldMind*) and enables computations such as perceived world diff and ideal world tension between agents. 

## 📝 Disclaimer
While the goal is to gradually enhance this system so that it might be used in later game development  projects, it is currently very experimental. Use at your own risk...

📢 Feedback is welcome and very appreciated! 🚀
