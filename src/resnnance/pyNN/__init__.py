from pyNN.common import control
from pyNN.common.control import DEFAULT_MAX_DELAY, DEFAULT_TIMESTEP, DEFAULT_MIN_DELAY

from resnnance.pyNN import simulator
from resnnance.pyNN.populations import Population, PopulationView, Assembly
from resnnance.pyNN.models.cells import *

# ReSNNance pacakge

def setup(timestep=DEFAULT_TIMESTEP, min_delay=DEFAULT_MIN_DELAY, **extra_params):
    """
    Initial configuration of the ReSNNance simulator (singleton model: there is only
    one instance of the simulator, defined here)
    """

    # Extract parameters from input arguments
    max_delay = extra_params.pop('max_delay', DEFAULT_MAX_DELAY)

    # Run pyNN common setup() - Mostly parameter checks
    control.setup(timestep, min_delay, **extra_params)

    # Instantiate simulator as singleton
    simulator.state = simulator.State()

    # Configure simulator
    if min_delay == "auto":
        min_delay = 0
    if max_delay == "auto":
        max_delay = 0
    simulator.state.min_delay = min_delay
    simulator.state.max_delay = max_delay
    simulator.state.dt = timestep


def end():
    """
    Simulator clean up and exit
    """

    # Remove simulator singleton
    simulator.state = None


run, run_until = control.build_run(simulator)
reset = control.build_reset(simulator)
get_current_time, get_time_step, get_min_delay, get_max_delay, num_processes, rank = control.build_state_queries(simulator)
