import networkx as nx
import matplotlib.pyplot as plt
import random

def create_torus_network(rows, cols):
    """Create a 2D torus network where each node is a router."""
    G = nx.grid_2d_graph(rows, cols, periodic=True)
    G = nx.DiGraph(G)  # Directed graph to simulate traffic direction

    # Add capacity to each edge
    for u, v in G.edges():
        G[u][v]['capacity'] = 100  # Random channel capacity

    return G

def generate_traffic(origin, destination, min_traffic=5, max_traffic=20):
    """Generate traffic between an origin and a destination node."""
    if origin == destination:
        raise ValueError("Origin and destination cannot be the same.")

    traffic = random.randint(min_traffic, max_traffic)
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

def simulate_congestion_aware_traffic(G, traffic_pairs, channel_load):
    """Simulate traffic using the congestion-aware pathfinding function."""
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
    """Identify overloaded channels."""
    overloaded = []
    for edge, load in channel_load.items():
        if load > G[edge[0]][edge[1]]['capacity']:
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
    pos = nx.circular_layout(G)  # Circular layout for visualization
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


if __name__ == "__main__":
    # Define torus dimensions (rows x columns)
    rows, cols = 4, 4
    G = create_torus_network(rows, cols)

    # Initialize channel loads
    channel_load = {edge: 0 for edge in G.edges()}

    # Generate random traffic pairs
    traffic_pairs = []
    for _ in range(10):  # Generate 10 traffic demands
        origin = (random.randint(0, rows - 1), random.randint(0, cols - 1))
        destination = (random.randint(0, rows - 1), random.randint(0, cols - 1))
        while origin == destination:  # Ensure origin and destination are different
            destination = (random.randint(0, rows - 1), random.randint(0, cols - 1))
        traffic_pairs.append(generate_traffic(origin, destination))

    # Simulate traffic
    simulate_congestion_aware_traffic(G, traffic_pairs, channel_load)

    # Detect overloaded channels
    overloaded = detect_overloads(G, channel_load)

    # Visualize the network as a grid
    visualize_torus(G, channel_load, overloaded)
