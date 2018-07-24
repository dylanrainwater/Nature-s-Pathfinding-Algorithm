/* Nature's Pathfinding Algorithm */
Population p;										/* The currently rendered population */
PVector score_pos;							/* The position of the score particle */
ArrayList<Obstacle> obstacles;  /* Obstacles for population to avoid */
int threshold = 100;						/* Maximum number of movements for each unit */

// Create window
// Initiate variables and create obstacles
void setup() {
	size(1000, 600);
	p = new Population(1000);
	
	score_pos = new PVector(width - 25, 25);
	obstacles = new ArrayList<Obstacle>();
	obstacles.add(new Obstacle(width / 4, height - 400, 20, 600));
	obstacles.add(new Obstacle(width / 2, 0, 20, 200));
	obstacles.add(new Obstacle(width / 1.2, height - 400, 20, 600));
}

// Draws the graphics 
// Called continuously until program ends
void draw() {
	background(255);
	
	// Draw units
	p.draw();
	
	// Draw obstacles
	for (Obstacle o : obstacles) {
		o.draw();
	}
	
	// Draw score
	fill(0, 255, 0, 127);
	ellipse(score_pos.x, score_pos.y, 15, 15);
}

/* Obstacle
	 Serves as a way to create paths on screen. Units die upon touching obstacles.
	 Obstacles are represented on screen by a yellow-orange rectangle.
*/
class Obstacle {
	// Position and size
	int x, y, w, h;
	Obstacle(int x, int y, int w, int h) {
		this.x = x;
		this.y = y;
		this.w = w;
		this.h = h;
	}

	// Checks for collisions with nodes
 	// Kills nodes that collide
	void update() {
		for (Node n : p.nodes) {
			if (n.pos.x < x + w && n.pos.x + n.size > x &&
				 	n.pos.y < y + h && n.pos.y + n.size > y) {
				n.dead = true;
				n.hit_obstacle = true;
			}
		}
	}

	void draw() {
		update();
		fill(120, 120, 0);
		rect(x, y, w, h);
	}
}

/* Population
	 Container for all units. Controls natural selection process.
*/
class Population {
	ArrayList<Node> nodes;
	int gen = 1; // Current generation
	int pop_size;

	Population(int pop_size) {
		this.pop_size = pop_size;
		
		nodes = new ArrayList<Node>();
		for (int i = 0; i < pop_size; i++) {
				nodes.add(new Node(20, height - 20, null));
		}
	}

	void draw() {
		for (Node n : nodes) {
			n.draw();
		}
		
		fill(0);
		text("Generation " + gen, 10, 10);
		text("Pop. Size " + pop_size, 10, 20);
		text("Movements " + threshold, 10, 30);
		
		if (all_dead()) {
			next_gen();
		}
	}

	/* Determines if all units are dead (or have hit the goal) */
	bool all_dead() {
		for (Node n : nodes) {
			if (!n.dead && !n.on_goal) return false;
		}
		return true;
	}

	double avg_fitness() {
		double fit = 0.0;
		for (Node n : nodes) {
			fit += n.fitness();
		}
		return fit / nodes.size();
	}

	// Reset the population and begin the next generation
	// Keeps the best unit, reproduces to replace the rest.
	// Threshold is increased by 50% (with a limit of 1000).
	// Population size is decreased by 15% (with a limit of 100).
	void next_gen() {
		println("Generation " + gen + " Avg. Fitness: " + avg_fitness());
		gen++;
		
		// Increase threshold
		threshold *= 1.5;
		
		if (threshold >= 1000) {
			threshold = 1000;
		}
		
		// Decrease population size
		pop_size *= 0.85;
		
		if (pop_size <= 100) {
			pop_size = 100;
		}
		
		// Find best unit, color it blue, and add to next generation
		Node n;
		n = get_best();
		n.r = 0;
		n.g = 0;
		n.b = 255;
		n.reset();
		ArrayList<Node> next_gen = new ArrayList<Node>();
		next_gen.add(n);
		
		// Select a parent (with probability proportional to fitness) and let it reproduce
		int i = 1;
		while (next_gen.size() < pop_size) {
			next_gen.add(new Node(20, height - 20, select_parent().crossover()));
			next_gen.get(i).mutate();
			i++;
		}
		
		// Replace current population with new generation
		nodes = next_gen;
	}

	/* get_best returns the unit with the highest fitness. 
		 If there are multiple units tied for best, it will just pick the last
		 tied unit it comes across. */
	Node get_best() {
		int best_fit = -1;
		int index = 0;
		
		for (int i = 0; i < nodes.size(); i++) {
			int fit = nodes.get(i).fitness();
			if (fit >= best_fit) {
				best_fit = fit;
				index = i;
			}
		}
		
		return nodes.get(index);
	}

	/* Randomly selects parent with probability proportional to fitness */
	Node select_parent() {
		int total_fitness = 0;
		for (Node n : nodes) {
			total_fitness += n.fitness();
		}
		
		int wheel = 0;
		int choose = random(total_fitness);
		for (Node n : nodes) {
			int fitness = n.fitness();
			wheel += fitness;
			if (wheel >= choose) {
				return n;
			}
		}
		
		return null;
	}
}

/* Brain
	 Determines movements for units.
*/
class Brain {
	int step = -1; // Current step
	int total_steps = 0; // Number of steps in lifetime
	ArrayList<PVector> forces; // To be applied to unit's acceleration
	int min_force = -2;
	int max_force = 2;
	
	Brain() {
		forces = new ArrayList<PVector>();
		for (int i = 0; i < 400; i++) {
			int x = (int) random(min_force, max_force);
			int y = (int) random(min_force, max_force);
			forces.add(new PVector(x, y));
		}
	}

	// Get next force to apply to unit
	PVector next_step() {
			total_steps++;
			if (++step >= forces.size()) {
				step = 0;
			}
		
			return forces.get(step);
	}

	// Creates a new brain with the same forces and returns it
	Brain clone() {
		Brain new_b = new Brain();
		for (int i = 0; i < forces.size(); i++) {
			new_b.forces.set(i, forces.get(i));
		}
		return new_b;
	}

	// Randomly mutates each force
	void mutate() {
		double mutation_rate = 0.01; // 1% chance of each force being mutated
		for (int i = 0; i < forces.size(); i++) {
			if (random() <= mutation_rate) {
				int x = (int) random(min_force, max_force);
				int y = (int) random(min_force, max_force);
				forces.set(i, new PVector(x, y));
			}
		}
	}

	void reset() {
		step = -1;
		total_steps = 0;
	}
}

/* Node
	 This is the class for each node / unit. It maintains logic and properties
	 for movment, position, acceleration, color, etc.
*/
class Node {
	PVector pos;
	PVector vel;
	PVector acc;
	
	PVector opos; // original position
	int r, g, b;
	int size;
	Brain brain;
	bool dead;
	bool on_goal;
	bool hit_obstacle;
	
	Node(int x, int y, Brain parent) {
		pos = new PVector(x, y);
		opos = new PVector(x, y);
		vel = new PVector(0, 0);
		acc = new PVector(0, 0);
		r = g = b = 0;
		dead = on_goal = hit_obstacle = false;
		
		size = 15;
		if (parent == null) {
			brain = new Brain();
		} else {
			brain = parent;
		}
	}
	
	void update() {
		acc.add(brain.next_step());
		vel.add(acc);
		vel.limit(5);
		pos.add(vel);
		
		// Die if unit has moved too much or is outside of the screen
		if (brain.total_steps >= threshold || pos.x >= width || pos.x <= 0 || pos.y >= height || pos.y <= 0) {
			dead = true;
		}
		
		if (pos.x >= score_pos.x && pos.x <= score_pos.x + size && pos.y >= score_pos.y && pos.y <= score_pos.y + size) {
			on_goal = true;
		}
	}

	void draw() {
		fill(r, g, b, 127);
		if (!dead && !on_goal) {
			update();
		}
		ellipse(pos.x, pos.y, size, size);
		text(fitness(), pos.x - size, pos.y - size);
	}

	// Fitness is determined by distance to goal, with a 20% penalty for hitting an obstacle.
	// If the unit ends on the goal, the fitness is determined by number of steps taken to get there.
	double fitness() {
		double fit;
		if (on_goal) {
			fit = .5 + 1.0 / (brain.total_steps*brain.total_steps);
		} else {
			int d = dist(pos.x, pos.y, score_pos.x, score_pos.y)
			fit = 1.0 / (d*d);
			if (hit_obstacle) fit *= 0.8;
		}
		return fit*10000;
	}

	void mutate() {
		brain.mutate();
	}

	Brain crossover() {
		return brain.clone();
	}

	void reset() {
		pos.x = opos.x;
		pos.y = opos.y;
		vel.x = vel.y = acc.x = acc.y = 0;
		dead = on_goal = hit_obstacle = false;
		brain.reset();
	}
}
