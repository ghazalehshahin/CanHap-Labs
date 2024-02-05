### Index

- [Setup]()
- [Maze Design]()
- [Iterative Improvements]()
- [Conclusion]()

---

# Setup

Since our node currently does not have access to the gen 3 2diy, we used the previous cohort’s already assembled gen 2 2diy boards.

The software setup was easy enough to follow along, and all the sample codes worked with some minor parameter changes for the selected port. The current issue is the assumption is the first available serial port will be the haply board, however it doesn’t seem to work the same on PCs. This causes some minor issues with git syncing the project across multiple computers (home and lab), however it is a minor nitpick and might be potentially resolved with the gen3 devices (and maybe smarter error handling).

---

# Maze Design

For designing mazes quickly, I found this online tool called (somewhat bluntly) [Online Maze Designer](https://www.theedkins.co.uk/jo/maze/makemaze/index.htm). It contained a helpful guide on quickly designing fun mazes, and I finalized on the following parameters: 

Size: 11
Maze Data: `111000111011011010100011101100011011011011100011010110100011111111111111` 

<img src = "imgs/Maze.png" width ="150">

Implementing this with the FBox class would be straightforward and too trivial, so I decided to also implement a fog mechanic, which would wipe away as the player explored different parts of the maze. This way the experience is a visuo-haptic one, and the player can use their “past experience” to avoid going back on already explored sections.

# Iterative Improvements

# Conclusion
