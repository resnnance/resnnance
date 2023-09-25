import logging
from typing import Optional

from pyNN.common import control
from pyNN.common import populations

from resnnance.pyNN.builder import Builder

name = 'resnnance'

class ID(int, populations.IDMixin):

    def __init__(self, n):
        """Create an ID object with numerical value `n`."""
        int.__init__(n)
        populations.IDMixin.__init__(self)


class State(control.BaseState):
    """
    Resnnance PyNN simulator interface
    """

    def __init__(self):
        super().__init__()

        # Simulator logger
        self.logger = logging.getLogger("resnnance.pyNN")
        self.logger.setLevel(logging.INFO)

        # Create log handler (for console output)
        handler = logging.StreamHandler()
        handler.setLevel(logging.INFO)

        # Format log output
        formatter = logging.Formatter( '%(asctime)s - %(name)s - %(levelname)s: %(message)s')
        handler.setFormatter(formatter)
        self.logger.addHandler(handler)

        # Log Resnnance environment creation
        self.logger.info("Created new Resnnance pyNN environment")

        # PyNN common attributes
        self.min_delay = 0              # Minimum allowed synaptic delay (ms)
        self.max_delay = 0              # Maximum allowed synaptic delay (ms)
        self.dt = 0.1                   # Integration time step (ms)
        self.num_processes = 1          # MPI processes - meaningless on Resnnance, always 1
        self.mpi_rank = 0               # MPI rank - meaningless on Resnnance, always 0 (head node)

        # Clear recorders and reset
        self.clear()

        # Resnnance
        self.populations = []
        self.projections = []
        self.builder = Builder(self)

    def run(self, simtime):
        self.t += simtime
        self.running = True
        self.logger.info(f"Simulation T = {(self.t):.1f} ms")

    def run_until(self, tstop):
        self.t = tstop
        self.running = True
        self.logger.info(f"Simulation T = {(self.t):.1f} ms")

    def clear(self):
        self.recorders = set([])
        self.id_counter = 0
        self.segment_counter = -1
        self.reset()

    def reset(self):
        """Reset the state of the current network to time t = 0."""
        self.running = False
        self.t = 0
        self.t_start = 0
        self.segment_counter += 1

# Resnnance simulator singleton object (instantiated in setup())
# Optional[] is a type hint: state can be a State object or None
state: Optional[State] = None
