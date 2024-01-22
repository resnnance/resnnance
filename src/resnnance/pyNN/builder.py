import resnnance.core as rsnn

from resnnance.pyNN.connectors import ConvConnector, PoolConnector
from pyNN.connectors import FromListConnector

import numpy as np

class Builder():

    def __init__(self, simulator):
        self.simulator = simulator

    def build(self):
        """
        Takes all simulator populations and projections and generates
        a compile-ready Resnnance model
        """
        # Take self.simulator.populations and self.simulator.projections
        # and generate resnnance model
        self.simulator.model = rsnn.Model()

        # Create layers
        for population in self.simulator.populations:
            # For each population, look for incoming projections
            incoming = [projection for projection in self.simulator.projections \
                        if projection.post == population]

            # Get layer information from incoming projections
            if len(incoming) > 1:
                raise RuntimeError('Layers with multiple inputs not supported')

            layer_class = Builder.__get_layer_class(incoming)
            layer_info = Builder.__get_layer_info(incoming)
    
            # Create and add layer
            if len(incoming) == 0:
                layer = rsnn.Input(population.label, population.size)
            else:
                layer = layer_class(population.label, layer_info)

            self.simulator.model.add_layer(layer)
        
        # TODO check if sequential order is kept between projections and layers

    def __get_layer_class(incoming):
        """
        Get layer class from list of incoming projections
        """
        if len(incoming) == 0:
            # Create input layer
            layer_class = rsnn.Input
        else:
            # Get layer class from single incoming projection connector type
            layer_class = Builder.conversion[incoming[0]._connector.__class__]['class']
        
        return layer_class
    
    def __get_layer_info(incoming):
        """
        Returns resnnance layer info from list of incoming projections
        """
        if len(incoming) == 0:
            # TODO set input layer weights/values
            return None
        else:
            # Gets relevant __info function 
            info = Builder.conversion[incoming[0]._connector.__class__]['info']
            return info(incoming[0])

    def __info_dense(projection):
        """
        Returns dense layer weights from a PyNN FromListConnector
        """
        # Create weight matrix for incoming projection
        weights = np.zeros(projection.shape)

        # Fill matrix with weights
        for conn in projection.connections:
            # Map projection connection weights into matrix (M, N): M = # synapses/pre neurons, N = # post neurons
            weights[conn.presynaptic_index, conn.postsynaptic_index] = conn.weight

        return weights

    def __info_conv2d(projection):
        """
        Returns conv2D layer info from a PyNN ConvConnector
        """
        info = projection.info
        return info

    def __info_pooling(projection):
        """
        Returns pooling layer info from a PyNN PoolConnector
        """
        info = projection.info
        return info

    # PyNN connector to Resnnance layer conversion table
    conversion = {
        FromListConnector: {'class': rsnn.Dense,   'info': __info_dense},
        ConvConnector:     {'class': rsnn.Conv2D,  'info': __info_conv2d},
        PoolConnector:     {'class': rsnn.Pooling, 'info': __info_pooling},
    }