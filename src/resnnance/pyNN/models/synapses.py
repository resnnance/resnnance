from pyNN.standardmodels import synapses, build_translations

from resnnance.pyNN import simulator

class StaticSynapse(synapses.StaticSynapse):
    __doc__ = synapses.StaticSynapse.__doc__
    translations = build_translations(
        ('weight', 'weight'),
        ('delay', 'delay')
    )

    def _get_minimum_delay(self):
        d = simulator.state.min_delay
        if d == 'auto':
            d = state.dt
        return d
