from resnnance.core import Resnnance
from resnnance.core.layers import *

from pyNN.connectors import FromListConnector
from resnnance.pyNN.connectors import ConvConnector, PoolConnector

class Builder():
    # PyNN connector to Resnnance layer conversion table
    conversion = {
        FromListConnector: Dense,
        ConvConnector: Conv2D,
        PoolConnector: Pooling
    }

    def __init__(self, simulator):
        self.simulator = simulator

    def build(self):
        """
        Takes all simulator populations and projections and generates
        a compile-ready Resnnance model
        """
        # TODO take self.simulator.populations and self.simulator.projections
        # and generate resnnance model
        self.simulator.model = Resnnance()

        # Search through all populations
        for population in self.simulator.populations:
            # For each population, look for incoming projections
            incoming = [projection for projection in self.simulator.projections \
                        if projection.post == population]

            if len(incoming) > 1:
                raise RuntimeError('Layers with multiple inputs not supported')

            # Add layer
            if len(incoming) == 0:
                # Create input layer
                layer_type = Input
            else:
                # Get layer type from single incoming projection connector type
                layer_type = Builder.conversion[incoming[0]._connector.__class__]

            # TODO Get layer information
            
            # ### Steps for dense layer

            # # Create weight matrix for incoming projection
            # self.map[layer.label]['weights'] = np.zeros(inproj.shape)

            # # Fill matrix with weights
            # for conn in inproj.connections:
            #     # Map projection connection weights into matrix (M, N): M = # synapses/pre neurons, N = # post neurons
            #     self.map[layer.label]['weights'][conn.presynaptic_index, conn.postsynaptic_index] = conn.weight

            # Create and add layer
            layer = layer_type(population.label)
            self.simulator.model.add_layer(layer)