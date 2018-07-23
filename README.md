# Nature's-Pathfinding-Algorithm
Pathfinding via a genetic algorithm

Starts with an initial swarm of 1,000 black units who must get close to a green unit while avoiding yellow obstacles. As each generation progresses, the best performer will remain (highlighted in blue) in the next generation. The rest of the population will die off and be replaced by offspring. The parents of the offspring will be chosen with probability proportional to fitness. At the end of each generation, the population size is reduced by 15% until it reaches 100 units.

# Fitness

The fitness, f, of each unit is displayed above it. The fitness is calculated like so:

    f = 1 / (distance between this unit and score unit)^2

If the unit died by hitting an obstacle, it suffers a 20% penalty.

Unless the unit landed on the score unit, then the fitness is calculated like so:

    f = 0.5 + 1 / (steps taken to get to the unit)^2
