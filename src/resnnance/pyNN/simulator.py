import logging
from typing import Optional

from pyNN.common import control

import resnnance.core as core


class State(control.BaseState):
    """
    ReSNNance PyNN simulator interface
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

        # Log ReSNNance environment creation
        self.logger.info("Created new ReSNNance pyNN environment")

        # PyNN common attributes
        self.t = 0                      # Current time (ms)
        self.dt = 0                     # Integration time step (ms)
        self.min_delay = 0              # Minimum allowed synaptic delay (ms)
        self.max_delay = 0              # Maximum allowed synaptic delay (ms)
        self.num_processes = 1          # MPI processes - meaningless on ReSNNance, always 1
        self.mpi_rank = 0               # MPI rank - meaningless on ReSNNance, always 0 (head node)
        self.recorders = set([])        # Empty set of recorders

        # ReSNNance
        self.core = core.ReSNNance()    # Core generator/simulator


    def reset(self):
        """
        Resets the simulator
        """

        # Reset simulator time
        self.t = 0


    def run_until(self, tstop):
        """
        Runs the simulator
        """

        # Update simulator time
        self.t = tstop

        # Log simulation runtime
        self.logger.info(f"Simulation T = {(tstop):.1f} ms")


# ReSNNance simulator singleton object (instantiated in setup())
# Optional[] is a type hint: state can be a State object or None
state: Optional[State] = None
