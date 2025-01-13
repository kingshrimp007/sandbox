import networkx as nx
import matplotlib.pyplot as plt
import random

def create_torus_network(rows, cols):
    """Create a 2D torus network."""
    G = nx.grid_2d_graph(rows, cols, periodic=True)
    G = nx.DiGraph(G)  # Directed graph to simulate traffic direction

    # Add capacity to edges
    for u, v in G.edges():
        G[u][v]['capacity'] = 15 # Uniform capacity

    return G

def generate_traffic(origin, destination):
    """
    Generate traffic between an origin and a destination node.

    Parameters:
        origin (tuple): The origin node as a coordinate (e.g., (0, 0)).
        destination (tuple): The destination node as a coordinate (e.g., (3, 3)).
        min_traffic (int): The minimum traffic value (default: 5).
        max_traffic (int): The maximum traffic value (default: 20).

    Returns:
        tuple: A traffic demand tuple (origin, destination, traffic).
    """
    if origin == destination:
        raise ValueError("Origin and destination cannot be the same.")

    traffic = 1
    return (origin, destination, traffic)

def find_congestion_aware_path(G, origin, destination, channel_load, max_retries=3):
    """
    Find a congestion-aware path between origin and destination.

    Parameters:
        G (nx.DiGraph): The network graph.
        origin (tuple): The source node.
        destination (tuple): The target node.
        channel_load (dict): Current load on each channel (edge).
        max_retries (int): Maximum number of retries for finding alternate paths.

    Returns:
        list: A path as a list of nodes or None if no valid path is found.
    """
    retries = 0
    while retries < max_retries:
        try:
            # Modify edge weights based on congestion
            for u, v in G.edges():
                capacity = G[u][v]['capacity']
                load = channel_load.get((u, v), 0)
                # Set weight as 1 + congestion penalty if load exceeds 80% of capacity
                G[u][v]['weight'] = 1 + (load / capacity if load >= 0.8 * capacity else 0)

            # Find shortest path based on adjusted weights
            path = nx.shortest_path(G, source=origin, target=destination, weight='weight')
            
            # Check if the path is usable (no overloaded edges)
            if all(channel_load.get((path[i], path[i + 1]), 0) <= G[path[i]][path[i + 1]]['capacity']
                   for i in range(len(path) - 1)):
                return path
            else:
                retries += 1
        except nx.NetworkXNoPath:
            return None

    return None

def simulate_traffic(G, traffic_pairs):
    """Simulate traffic and calculate channel load."""
    channel_load = {edge: 0 for edge in G.edges()}
    for src, dst, traffic in traffic_pairs:
        try:
            path = nx.shortest_path(G, source=src, target=dst)
            for i in range(len(path) - 1):
                edge = (path[i], path[i+1])
                channel_load[edge] += traffic
        except nx.NetworkXNoPath:
            print(f"No path found between {src} and {dst}.")
    return channel_load

# Simulate traffic using the congestion-aware pathfinding function
def simulate_congestion_aware_traffic(G, traffic_pairs, channel_load):
    for origin, destination, traffic in traffic_pairs:
        path = find_congestion_aware_path(G, origin, destination, channel_load)
        if path:
            print(f"Path for {origin} -> {destination}: {path}")
            # Update channel load along the path
            for i in range(len(path) - 1):
                edge = (path[i], path[i + 1])
                channel_load[edge] += traffic
        else:
            print(f"No valid path for {origin} -> {destination}. Traffic dropped.")

def detect_overloads(G, channel_load):
    """Detect overloaded channels."""
    overloaded = []
    for edge, load in channel_load.items():
        capacity = G[edge[0]][edge[1]]['capacity']
        if load > capacity:
            overloaded.append(edge)
    return overloaded

def visualize_as_grid(G, channel_load, overloaded, rows, cols):
    """Visualize the torus network as a grid."""
    # Create a manual grid layout
    pos = {(x, y): (y, -x) for x, y in G.nodes()}  # Place nodes in a grid-like fashion
    plt.figure(figsize=(10, 10))
    
    # Draw the nodes
    nx.draw(G, pos, with_labels=True, node_color="lightblue", node_size=700)

    # Annotate edges with channel load and capacity
    edge_labels = {edge: f"{channel_load[edge]}/{G[edge[0]][edge[1]]['capacity']}" for edge in G.edges()}
    nx.draw_networkx_edge_labels(G, pos, edge_labels=edge_labels)

    # Highlight overloaded edges
    nx.draw_networkx_edges(G, pos, edgelist=overloaded, edge_color="red", width=2)

    plt.title(f"Torus Network ({rows}x{cols}) with Channel Load")
    plt.show()

def visualize_torus(G, channel_load, overloaded):
    """Visualize the torus network."""
    pos = nx.spring_layout(G)  # Circular layout for visualization
    plt.figure(figsize=(10, 10))
    nx.draw(G, pos, with_labels=True, node_color='lightblue', node_size=700)

    # Add edge labels
    edge_labels = {edge: f"{channel_load[edge]}/{G[edge[0]][edge[1]]['capacity']}" for edge in G.edges()}
    nx.draw_networkx_edge_labels(G, pos, edge_labels=edge_labels)

    # Highlight overloaded channels
    if overloaded:
        nx.draw_networkx_edges(G, pos, edgelist=overloaded, edge_color='red', width=2)

    plt.title("Torus Network with Channel Load")
    plt.show()

# Parameters
rows, cols = 4, 4  # Torus dimensions
G = create_torus_network(rows, cols)

# Simulate random traffic between node pairs
# traffic_pairs = [
#     ((0, 0), (3, 3), 5),
#     ((1, 1), (2, 2), 8),
#     ((0, 3), (3, 0), 10),
#     ((2, 0), (1, 3), 15),
# ]
traffic_pairs = []
channel_load = {edge: 0 for edge in G.edges()}

for _ in range(50):  # Generate 50 traffic demands
    # origin = (random.randint(0, rows - 1), random.randint(0, cols - 1))
    # destination = (random.randint(0, rows - 1), random.randint(0, cols - 1))
    origin = (0, 0)
    destination = (3, 3)

    # # Avoid same origin and destination
    # while origin == destination:
    #     destination = (random.randint(0, rows - 1), random.randint(0, cols - 1))
    
    # traffic_pairs.append(generate_traffic(origin, destination))
    traffic_pairs.append((origin, destination, 1))

# channel_load = simulate_traffic(G, traffic_pairs)
simulate_congestion_aware_traffic(G, traffic_pairs, channel_load)
overloaded = detect_overloads(G, channel_load)

# Print overloaded channels
if overloaded:
    print("Overloaded Channels:")
    for edge in overloaded:
        print(f"Channel {edge} is overloaded.")
else:
    print("No channels are overloaded.")

# Visualize the network
visualize_torus(G, channel_load, overloaded)
# visualize_as_grid(G, channel_load, overloaded, rows, cols)
