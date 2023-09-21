from pyNN.connectors import Connector

class ConvConnector(Connector):
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

    def __init__(self, kernel_data, safe=True, callback=None):
        super().__init__(safe=safe, callback=callback)
        self.kernel = kernel_data

    def connect(self, projection):
        """
        Connect-up a Projection
        """

        # Get kernel data and make connections
        print(f'ConvConnector for {projection}')
        print(self.kernel)

class PoolConnector(Connector):
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

    def __init__(self, pool_data, safe=True, callback=None):
        super().__init__(safe=safe, callback=callback)
        self.pool = pool_data

    def connect(self, projection):
        """
        Connect-up a Projection
        """

        # Get kernel data and make connections
        print(f'PoolConnector for {projection}')
        print(self.pool)
