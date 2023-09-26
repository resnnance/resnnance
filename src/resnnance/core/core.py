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
        self.logger.info("Created empty Resnnance model")

    def add_layer(self, layer):
        self.layers.append(layer)
        self.logger.info(f"Added {layer.__class__.__name__} layer: {layer.label}")

    def compile(self, path=None):
        self.compiler.compile(self, path)

    def plot(self, path=None):
        self.plotter.plot(self, path)