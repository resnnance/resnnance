from itertools import repeat

from pyNN.common import projections
from pyNN.core import ezip
from pyNN.space import Space
from pyNN.connectors import FromListConnector

from resnnance.pyNN import simulator
from resnnance.pyNN.models.synapses import StaticSynapse
from resnnance.pyNN.connectors import MovingConnector
class Connection(projections.Connection):
    """
    Store an individual plastic connection and information about it. Provide an
    interface that allows access to the connection's weight, delay and other
    attributes.
    """

    def __init__(self, pre, post, **attributes):
        self.presynaptic_index = pre
        self.postsynaptic_index = post
        for name, value in attributes.items():
            setattr(self, name, value)

    def as_tuple(self, *attribute_names):
        # should return indices, not IDs for source and target
        return tuple([getattr(self, name) for name in attribute_names])


class Projection(projections.Projection):
    __doc__ = projections.Projection.__doc__
    _simulator = simulator
    _static_synapse_class = StaticSynapse

    def __init__(self, presynaptic_population, postsynaptic_population,
                 connector, synapse_type=None, source=None, receptor_type=None,
                 space=Space(), label=None):
        projections.Projection.__init__(self, presynaptic_population, postsynaptic_population,
                                   connector, synapse_type, source, receptor_type,
                                   space, label)

        #  Create connections
        self.connections = []
        self.info = {}
        connector.connect(self)

        # Resnnance projection
        simulator.state.projections.append(self)

    def __len__(self):
        return len(self.connections)

    def set(self, **attributes):
        raise NotImplementedError

    def _convergent_connect(self, presynaptic_indices, postsynaptic_index,
                            **connection_parameters):
        for name, value in connection_parameters.items():
            if isinstance(value, float):
                connection_parameters[name] = repeat(value)
        for pre_idx, other in ezip(presynaptic_indices, *connection_parameters.values()):
            other_attributes = dict(zip(connection_parameters.keys(), other))
            self.connections.append(
                Connection(pre_idx, postsynaptic_index, **other_attributes)
            )

    # def get_info(self):
    #     """
    #     Returns the relevant post-synaptic connection information
    #     """
    #     info = {}

    #     if isinstance(self._connector, MovingConnector):
    #         info = self.info
    #     elif isinstance(self._connector, FromListConnector):
    #         info = 