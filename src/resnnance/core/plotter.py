from .logger import resnnance_logger

import os
import numpy as np
import networkx as nx
import matplotlib.pyplot as plt

class Plotter(object):

    def __init__(self):
        # Log
        self.logger = resnnance_logger("plotter")

    def plot(self, model, path=None):
        # Check model
        if not model.layers:
            self.logger.warning("Empty Resnnance model")
            return

        # Create directed graph representation of the model
        self.logger.info("Plotting Resnnance model...")
        network = nx.DiGraph()
        [network.add_node(layer.label, layer=layer) for layer in model.layers]

        for i, layer in enumerate(model.layers):
            if not i == 0:
                network.add_edge(model.layers[i-1].label, model.layers[i].label)

        # Plot graph
        self.__plot_network(network, path)

    def __plot_network(self, network, path=None):

        # Sizes and positions
        posx = [i for i in range(network.number_of_nodes())]
        pos  = {node: [posx[i], 0] for i, node in enumerate(network.nodes)}
        node_sizes = [400*np.log((ndata['layer'].get_size() + 120)/100) for node, ndata in network.nodes(data=True)]

        # Draw
        fig = plt.figure(1, figsize=(network.number_of_nodes(), 7)) #, dpi=72)
        nx.draw(network, pos, node_size=node_sizes)

        # Draw labels
        labels  = {node: ndata['layer'].get_size() for node, ndata in network.nodes(data=True)}
        for node, ndata in network.nodes(data=True):
            plt.text(pos[node][0],  0.0005, s=ndata['layer'].get_size(),  horizontalalignment='center')
            plt.text(pos[node][0], -0.0005, s=ndata['layer'].label, horizontalalignment='center', verticalalignment='top', rotation='vertical')

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

    def __plot_weights(self):
        raise NotImplementedError

        # # Print connections
        # import matplotlib.pyplot as plt
        # plt.imshow(self.map[layer.label]['weights'], interpolation='none')
        # plt.show()