from .logger import resnnance_logger

import os
import networkx as nx
import matplotlib.pyplot as plt

class ResnnancePlotter(object):

    def __init__(self):
        # Log
        self.logger = resnnance_logger("resnnance.plotter")

    def plot(self, model, path=None):
        self.logger.info("Plotting Resnnance model...")

        network = nx.DiGraph()

        [network.add_node(layer.label, population=layer) for layer in model.layers]
        [network.add_edge(conn.pre.label, conn.post.label, projection=conn) for conn in model.connections]

        # Sizes and positions
        posx = [i for i in range(network.number_of_nodes())]
        pos  = {node: [posx[i], 0] for i, node in enumerate(network.nodes)}
        node_sizes = [ndata['population'].size for node, ndata in network.nodes(data=True)]

        # Draw
        fig = plt.figure(1, figsize=(network.number_of_nodes(), 7)) #, dpi=72)
        nx.draw(network, pos, node_size=node_sizes)

        # Draw labels
        labels  = {node: ndata['population'].size for node, ndata in network.nodes(data=True)}
        for node, ndata in network.nodes(data=True):
            plt.text(pos[node][0],  0.0005, s=ndata['population'].size,  horizontalalignment='center')
            plt.text(pos[node][0], -0.0005, s=ndata['population'].label, horizontalalignment='center', verticalalignment='top', rotation='vertical')

        # # Get connector name
        # edge_labels = dict([((u, v), d['projection']._connector.__class__.__name__) for u, v, d in model.network.edges(data=True)])
        # # Draw edge labels
        # nx.draw_networkx_edge_labels(model.network, pos, edge_labels=edge_labels)

        # Save
        if path != None:
            plt.savefig(os.path.join(path, 'SNN.png'))
        else:
            plt.show()

        self.logger.info("Plotting Resnnance model - OK")