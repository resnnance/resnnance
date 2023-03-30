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


    def clear(self):
        """
        Clear the simulator structure
        """


    def run_until():
        """
        Runs the simulator
        """


# ReSNNance simulator singleton object (instantiated in setup())
# Optional[] is a type hint: state can be a ReSNNance object or None
state: Optional[ReSNNance] = None
