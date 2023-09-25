from .logger   import resnnance_logger
from .compiler import ResnnanceCompiler
from .plotter  import ResnnancePlotter

class Resnnance(object):

    def __init__(self):
        # Logger
        self.logger = resnnance_logger()

        # Model build
        self.compiler = ResnnanceCompiler()

        # Plotter
        self.plotter = ResnnancePlotter()

        # Model data
        self.layers = []
        self.connections = []   # deprecated
        self.logger.info("Created empty Resnnance model")

    def add_layer(self, layer):
        # TODO Add layer
        self.layers.append(layer)
        self.logger.info(f"Added layer: {layer}")

    def add_connection(self, connection):
        # TODO Get postsynaptic layer from model
        # TODO Add relevant weights and parameters
        self.connections.append(connection)
        layer = "postsynaptic_layer"
        self.logger.info(f"Added connection: {connection} to layer {layer}")

    def compile(self, path=None):
        self.compiler.compile(self, path)

    def plot(self, path=None):
        self.plotter.plot(self, path)