## Maze Generation

#### Resources

- [Understandle Stuff](https://www.cs.cmu.edu/~112-n23/notes/student-tp-guides/Mazes.pdf)
- [Genetic Stuff](https://www.ijml.org/vol6/602-IT023.pdf)
- [Cryptic shit](https://iajit.org/portal/PDF/vol.3,no.4/7-Adnan.pdf)

#### First version

Initial thought process was so:

- Given a grid dimension, Set everything to be a WALL
- Chose a start position, and run dfs
- While running dfs, we need need to see if we can reach
  - {-2, 0}, {2, 0}, {0, -2}, {0, 2}
  - We get all the neighbours from above
  - Now we need to create a gap since we are surrounded by walls
- We chose a random neighbour, and remove the WALL
- We chose the position between the neighbour and current_pos (nx+cx)/2, (ny+cy)/2
- And remove the WALL. One of these WALLs can be a dot or a pellet

**Result**: [generation1](./mazes/version1.txt) , fuck all

#### Second version

The above articles state, these mazes are somewhat symmetric.
Also I didn't consider the fact that enemies are generated at the center.
So need a path from center as well.

Also `specific design characteristic: no dead ends.` mazes:

__Dead ends__ are sections of the maze where a player can go to a cell but then has no other options for movement.
For example, if Pac-Man moves into a cell with only one adjacent empty cell, it can only return back.
That would suck.

If a cell has only one adjacent empty cell, it qualifies as a dead end (because it can only lead back to the one neighboring cell).

Gameplay Flow: Having no dead ends ensures that Pac-Man can continuously move-
through the maze without hitting a point where he cannot progress.

- We create half the maze, and then we invert and copy for the other half.

- Build the walls, filling:
  - top-row ((0,0)..(0,n-1))
  - left-columns ((0,0)..(n-1, 0))
  - right-columns ((0, n-1)..(n-1, n-1))
- bottom columns are blank, because we need to create a space for enemies
- run dfs for rest of the path
- calculating dead ends or not:
  - If a cell has only one empty adjacent cell, meaning the entry and exit is same, its a dead end
  - Check neighbours are also leading to dead end
- If a dead end cannot connect to another path, its a wall

**Result** [generation2](./mazes/version2.txt), less fuckall

### Version 3

- First fix, instead of starting from 2, 2, start from pacman.pos(x,y)
- Step 1, create the first connected path, using skipping by 2
- Step 2, create loops covering 3, 4 blocks. Select a random point on the grid and consume in batches of 3 and 6

