from .logger   import resnnance_logger
from .compiler import Compiler
from .plotter  import Plotter

class Model(object):

    def __init__(self):
        # Logger
        self.logger = resnnance_logger()

        # Model build
        self.compiler = Compiler()

        # Plotter
        self.plotter = Plotter()

        # Model data
        self.layers = []
        self.logger.info("Created empty Resnnance model")

    def add_layer(self, layer):
        self.layers.append(layer)
        self.logger.info(f"Added {layer.__class__.__name__} layer: {layer.label}")

    def compile(self, path=None):
        self.compiler.compile(self, path)

    def plot(self, path=None):
        self.plotter.plot(self, path)