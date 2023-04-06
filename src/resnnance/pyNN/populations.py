import numpy as np

from pyNN.common import populations
from pyNN.standardmodels import StandardCellType

from resnnance.pyNN import simulator
from resnnance.pyNN.recording import Recorder

class Assembly(populations.Assembly):
    _simulator = simulator


class Population(populations.Population):
    __doc__ = populations.Population.__doc__
    _simulator = simulator
    _recorder_class = Recorder
    _assembly_class = Assembly

    def _create_cells(self):
        id_range = np.arange(simulator.state.id_counter,
                             simulator.state.id_counter + self.size)
        self.all_cells = np.array([simulator.ID(id) for id in id_range],
                                  dtype=simulator.ID)

        def is_local(id):
            return (id % simulator.state.num_processes) == simulator.state.mpi_rank
        self._mask_local = is_local(self.all_cells)

        if isinstance(self.celltype, StandardCellType):
            parameter_space = self.celltype.native_parameters
        else:
            parameter_space = self.celltype.parameter_space
        parameter_space.shape = (self.size,)
        parameter_space.evaluate(mask=self._mask_local, simplify=False)
        self._parameters = parameter_space.as_dict()

        for id in self.all_cells:
            id.parent = self
        simulator.state.id_counter += self.size

        # ReSNNance population
        simulator.state.core.network.add_node(self.label, population=self)

    def _set_initial_value_array(self, variable, initial_values):
        pass

    def _get_view(self, selector, label=None):
        return PopulationView(self, selector, label)

    def _get_parameters(self, *names):
        if isinstance(self.celltype, StandardCellType):
            if any(name in self.celltype.computed_parameters() for name in names):
                # need all parameters in order to calculate values
                native_names = self.celltype.get_native_names()
            else:
                native_names = self.celltype.get_native_names(*names)
            native_parameter_space = self._get_native_parameters(*native_names)
            parameter_space = self.celltype.reverse_translate(native_parameter_space)
        else:
            parameter_space = self._get_native_parameters(*native_names)
        return parameter_space

    def _get_native_parameters(self, *names):
        """
        return a ParameterSpace containing native parameters
        """
        parameter_dict = {}
        for name in names:
            parameter_dict[name] = simplify(self._parameters[name])
        return ParameterSpace(parameter_dict, shape=(self.local_size,))

    def _set_parameters(self, parameter_space):
        """parameter_space should contain native parameters"""
        parameter_space.evaluate(simplify=False, mask=self._mask_local)
        for name, value in parameter_space.items():
            self._parameters[name] = value


class PopulationView(populations.PopulationView):
    _simulator = simulator

    def _get_parameters(self, *names):
        if isinstance(self.celltype, StandardCellType):
            if any(name in self.celltype.computed_parameters() for name in names):
                # need all parameters in order to calculate values
                native_names = self.celltype.get_native_names()
            else:
                native_names = self.celltype.get_native_names(*names)
            native_parameter_space = self._get_native_parameters(*native_names)
            parameter_space = self.celltype.reverse_translate(native_parameter_space)
        else:
            parameter_space = self._get_native_parameters(*native_names)
        return parameter_space

    def _get_native_parameters(self, *names):
        """
        return a ParameterSpace containing native parameters
        """
        parameter_dict = {}
        for name in names:
            value = self.parent._parameters[name]
            if isinstance(value, np.ndarray):
                value = value[self.mask]
            parameter_dict[name] = simplify(value)
        return ParameterSpace(parameter_dict, shape=(self.size,))  # or local size?

    def _set_parameters(self, parameter_space):
        """parameter_space should contain native parameters"""
        for name, value in parameter_space.items():
            try:
                self.parent._parameters[name][self.mask] = value.evaluate(simplify=True)
            except ValueError:
                raise errors.InvalidParameterValueError(
                    f"{name} should not be of type {type(value)}")

    def _set_initial_value_array(self, variable, initial_values):
        pass

    def _get_view(self, selector, label=None):
        return PopulationView(self, selector, label)


