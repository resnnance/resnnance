from pyNN.common.control import BaseState

from typing import Optional
import logging

class ReSNNance(BaseState):
    """
    ReSNNance PyNN simulator interface
    """

    def __init__(self):
        super().__init__()

        # Simulator logger
        self.logger = logging.getLogger("resnnance")

        self.t = 0
        self.dt = 0


    def reset(self):
        """
        Reset the simulator
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
        self.logger.debug(f"T: {(tstop):.1f} ms")


# ReSNNance simulator singleton object (instantiated in setup())
# Optional[] is a type hint: state can be a ReSNNance object or None
state: Optional[ReSNNance] = None
