from resnnance.core import Resnnance
from resnnance.core.layers import *

class Builder():

    def __init__(self, simulator):
        self.simulator = simulator
        self.model = Resnnance()

    def build(self):
        """
        Takes all simulator populations and projections and generates
        a compile-ready Resnnance model
        """
        model = Resnnance()

        # TODO take self.simulator.populations and self.simulator.projections
        # and generate resnnance model

        self.model = model

    # def __equip_post_layer(self, projection):
    #     # Search for post-synaptic layer in population list
    #     population = projection.postsynaptic_population
    #     if population in self.populations:
    #         # Create layer with population and projection info
    #         self.__layer_creator(self, population, projection)
    #     else:
    #         raise ValueError(
    #             'Projection post-synaptic layer does not match any \
    #              layer in the model')

    # def __layer_creator(self, population, projection):
    #     # TODO create layer based on projection.connector type
    #     # TODO extract layer info from projection.connector data
    #     layer = Layer()
        
    #     # Add layer to model
    #     self.model.add_layer()