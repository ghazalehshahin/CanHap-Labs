### Index

- [Setup](https://github.com/GAmuzak/CanHap-Labs/tree/main/Lab_1_Maze#setup)
- [Maze Design](https://github.com/GAmuzak/CanHap-Labs/tree/main/Lab_1_Maze#maze-design)
- [Iterative Improvements](https://github.com/GAmuzak/CanHap-Labs/tree/main/Lab_1_Maze#iterative-improvements)
- [Conclusion](https://github.com/GAmuzak/CanHap-Labs/tree/main/Lab_1_Maze#conclusion)

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

Implementing this with the `FBox` class would be straightforward and too trivial, so I decided to also implement a fog mechanic, which would wipe away as the player explored different parts of the maze. This way the experience is a visuo-haptic one, and the player can use their “past experience” to avoid going back on already explored sections.

# Iterative Improvements
First I setup a base world using the Fisica maze example as a template, and removing everything except for the start and end circles. Putting the cursor over the start circle starts the game, and reaching the end circle will end the game. The only way to test this right now is based on the `setSensor` parameter of the Haptic Tool being set to false on start of the game, and true on end. I then positioned them to the indended start and end positions. I also updated the icons to have a gate and treasure.

Next, I wanted to create the walls of the maze. I noticed however that to create a wall from the maze example, a lot of the code was very redundant. So I decided to make a simple `FWall`  class to extend the functionality of `FBox`  to make walls with a single line of code (well, 2 if you count adding it to the world). I also wanted the x and y parameters to be the starting point for the walls generation, so I offset the position with half the width and height. This was purely to make it easier to think about the walls growing from a point, and I could consider the grid similar to the maze I generated above.

# Conclusion
