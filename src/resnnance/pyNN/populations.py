import numpy as np

from pyNN.common import populations

from resnnance.pyNN import simulator
from resnnance.pyNN.recording import Recorder

class ID(int, populations.IDMixin):
    _simulator = simulator


class Population(populations.Population):
    _simulator = simulator
    _recorder_class = Recorder

    @property
    def all_cells(self):
        cells = np.array([ID(i) for i in range(self.size)])
        return cells

    @property
    def _mask_local(self):
        # All cells are local
        return np.ones((self.size,), bool) 
    
    def _create_cells(self):
        pass

    def _get_view(self, selector, label=None):
        return PopulationView(self, selector, label)


class PopulationView(populations.PopulationView):
    _simulator = simulator


class Assembly(populations.Assembly):
    _simulator = simulator


