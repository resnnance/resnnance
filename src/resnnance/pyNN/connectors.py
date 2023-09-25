from pyNN.connectors import Connector

class MovingConnector(Connector):
    """
    Abstract base class for Connectors based on 
    moving kernels, pooling or CNN related layers
    """
    def connect(self, projection):
        """
        Copies connector info into projection -
        Does not generate connections since this is not
        a "physical" connector
        """
        projection.info = self.info

    def flatten(self):
        # TODO method that returns a dense connector (FromListConnector)
        # with the same functionality
        raise NotImplementedError

class ConvConnector(MovingConnector):
    """
    Make connections for a convolutional layer

    Arguments:
        `kernel_data`:
            A dictionary holding the convolutional layer data
        `safe`:
            if True, check that weights and delays have valid values. If False,
            this check is skipped.
        `callback`:
            if True, display a progress bar on the terminal.
    """

    def __init__(self, info, safe=True, callback=None):
        super().__init__(safe=safe, callback=callback)
        self.info = info

class PoolConnector(MovingConnector):
    """
    Make connections for a convolutional layer

    Arguments:
        `pool_data`:
            A dictionary holding the pooling layer data
        `safe`:
            if True, check that weights and delays have valid values. If False,
            this check is skipped.
        `callback`:
            if True, display a progress bar on the terminal.
    """

    def __init__(self, info, safe=True, callback=None):
        super().__init__(safe=safe, callback=callback)
        self.info = info